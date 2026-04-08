import Foundation
import Observation

@Observable
@MainActor
final class GlobalConfigFileManager {
    let filePath: String
    private(set) var config: ClaudeGlobalConfig
    private(set) var hasError = false
    private(set) var errorMessage = ""

    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var debounceTask: Task<Void, Never>?
    private var writeResetTask: Task<Void, Never>?
    private var isWriting = false

    init(filePath: String) {
        self.filePath = filePath
        self.config = ClaudeGlobalConfig()
        loadFromDisk()
        startWatching()
    }

    func cleanup() {
        stopWatching()
        debounceTask?.cancel()
        debounceTask = nil
        writeResetTask?.cancel()
        writeResetTask = nil
    }

    func loadFromDisk() {
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            config = ClaudeGlobalConfig()
            hasError = false
            errorMessage = ""
            return
        }

        do {
            let data = try Data(contentsOf: url)
            config = try ClaudeGlobalConfig.decode(from: data)
            hasError = false
            errorMessage = ""
        } catch {
            hasError = true
            errorMessage = "Invalid JSON: \(error.localizedDescription)"
        }
    }

    func saveToDisk() {
        do {
            let data = try config.encode()
            let url = URL(fileURLWithPath: filePath)
            let directory = url.deletingLastPathComponent()
            let dirCreated = !FileManager.default.fileExists(atPath: directory.path)
            if dirCreated {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            isWriting = true
            try data.write(to: url, options: .atomic)
            hasError = false
            errorMessage = ""

            writeResetTask?.cancel()
            writeResetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                self?.isWriting = false
            }

            if dirCreated && dispatchSource == nil {
                startWatching()
            }
        } catch {
            isWriting = false
            hasError = true
            errorMessage = "Write failed: \(error.localizedDescription)"
        }
    }

    func updateConfig(_ transform: (inout ClaudeGlobalConfig) -> Void) {
        transform(&config)
        saveToDisk()
    }

    private func startWatching() {
        let url = URL(fileURLWithPath: filePath)
        let directory = url.deletingLastPathComponent().path

        if !FileManager.default.fileExists(atPath: directory) {
            return
        }

        let watchPath = FileManager.default.fileExists(atPath: filePath) ? filePath : directory
        let fd = open(watchPath, O_EVTONLY)
        guard fd >= 0 else { return }
        fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self, !self.isWriting else { return }

            let flags = DispatchSource.FileSystemEvent(rawValue: self.dispatchSource?.data ?? 0)
            if flags.contains(.rename) || flags.contains(.delete) {
                self.stopWatching()
                self.debounceTask?.cancel()
                self.debounceTask = Task { @MainActor [weak self] in
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    guard !Task.isCancelled else { return }
                    self?.startWatching()
                    self?.loadFromDisk()
                }
                return
            }

            self.debounceTask?.cancel()
            self.debounceTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 100_000_000)
                guard !Task.isCancelled else { return }
                self?.loadFromDisk()
            }
        }

        source.setCancelHandler { [fd] in
            close(fd)
        }

        dispatchSource = source
        source.resume()
    }

    private func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
        fileDescriptor = -1
    }
}
