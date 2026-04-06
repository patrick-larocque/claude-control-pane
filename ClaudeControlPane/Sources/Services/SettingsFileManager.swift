import Foundation
import Observation

@Observable
@MainActor
final class SettingsFileManager {
    let filePath: String
    private(set) var settings: ClaudeSettings
    private(set) var hasError: Bool = false
    private(set) var errorMessage: String = ""

    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var debounceTask: Task<Void, Never>?
    private var writeResetTask: Task<Void, Never>?
    private var isWriting = false

    init(filePath: String) {
        self.filePath = filePath
        self.settings = ClaudeSettings()
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
            self.settings = ClaudeSettings()
            self.hasError = false
            self.errorMessage = ""
            return
        }

        do {
            let data = try Data(contentsOf: url)
            self.settings = try ClaudeSettings.decode(from: data)
            self.hasError = false
            self.errorMessage = ""
        } catch {
            self.hasError = true
            self.errorMessage = "Invalid JSON: \(error.localizedDescription)"
        }
    }

    func saveToDisk() {
        do {
            let data = try settings.encode()
            let url = URL(fileURLWithPath: filePath)

            let directory = url.deletingLastPathComponent()
            let dirCreated = !FileManager.default.fileExists(atPath: directory.path)
            if dirCreated {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            isWriting = true
            try data.write(to: url, options: .atomic)
            writeResetTask?.cancel()
            writeResetTask = Task { @MainActor [weak self] in
                try? await Task.sleep(nanoseconds: 200_000_000)
                guard !Task.isCancelled else { return }
                self?.isWriting = false
            }
            self.hasError = false
            self.errorMessage = ""

            // If we just created the directory (watcher couldn't start before), start now.
            if dirCreated && dispatchSource == nil {
                startWatching()
            }
        } catch {
            isWriting = false
            self.hasError = true
            self.errorMessage = "Write failed: \(error.localizedDescription)"
        }
    }

    func updateSettings(_ transform: (inout ClaudeSettings) -> Void) {
        transform(&settings)
        saveToDisk()
    }

    private func startWatching() {
        let url = URL(fileURLWithPath: filePath)
        let dir = url.deletingLastPathComponent().path

        if !FileManager.default.fileExists(atPath: dir) {
            return
        }

        let watchPath = FileManager.default.fileExists(atPath: filePath) ? filePath : dir
        let fd = open(watchPath, O_EVTONLY)
        guard fd >= 0 else { return }
        self.fileDescriptor = fd

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write, .rename, .delete],
            queue: .main
        )

        source.setEventHandler { [weak self] in
            guard let self = self, !self.isWriting else { return }

            // Detect rename/delete (from atomic write or external deletion).
            // The fd now points to a stale or deleted inode — restart the watcher.
            let flags = DispatchSource.FileSystemEvent(rawValue: self.dispatchSource?.data ?? 0)
            if flags.contains(.rename) || flags.contains(.delete) {
                self.stopWatching()
                self.debounceTask?.cancel()
                self.debounceTask = Task { @MainActor [weak self] in
                    // Brief settle delay before re-opening path (atomic rename needs to land)
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

        self.dispatchSource = source
        source.resume()
    }

    private func stopWatching() {
        dispatchSource?.cancel()
        dispatchSource = nil
        fileDescriptor = -1
    }
}
