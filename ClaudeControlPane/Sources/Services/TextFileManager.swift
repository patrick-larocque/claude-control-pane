import Foundation
import Observation

@Observable
@MainActor
final class TextFileManager {
    enum ValidationMode: Sendable {
        case none
        case json
    }

    let filePath: String
    let defaultContent: String
    let validationMode: ValidationMode

    private(set) var content: String
    private(set) var hasError = false
    private(set) var errorMessage = ""
    private(set) var fileExists = false
    private(set) var hasUnsavedChanges = false

    private var lastSavedContent: String
    private var fileDescriptor: Int32 = -1
    private var dispatchSource: DispatchSourceFileSystemObject?
    private var debounceTask: Task<Void, Never>?
    private var writeResetTask: Task<Void, Never>?
    private var isWriting = false

    init(filePath: String, defaultContent: String = "", validationMode: ValidationMode = .none) {
        self.filePath = filePath
        self.defaultContent = defaultContent
        self.validationMode = validationMode
        self.content = defaultContent
        self.lastSavedContent = defaultContent
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

    func setContent(_ newValue: String) {
        content = newValue
        hasUnsavedChanges = newValue != lastSavedContent
    }

    func loadFromDisk() {
        let url = URL(fileURLWithPath: filePath)
        guard FileManager.default.fileExists(atPath: filePath) else {
            fileExists = false
            content = defaultContent
            lastSavedContent = defaultContent
            hasUnsavedChanges = false
            hasError = false
            errorMessage = ""
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let loaded = String(decoding: data, as: UTF8.self)
            content = loaded
            lastSavedContent = loaded
            hasUnsavedChanges = false
            fileExists = true
            hasError = false
            errorMessage = ""
        } catch {
            hasError = true
            errorMessage = "Cannot read file: \(error.localizedDescription)"
        }
    }

    func saveToDisk() {
        do {
            let data = try normalizedData()
            let url = URL(fileURLWithPath: filePath)
            let directory = url.deletingLastPathComponent()
            let dirCreated = !FileManager.default.fileExists(atPath: directory.path)
            if dirCreated {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            isWriting = true
            try data.write(to: url, options: .atomic)
            let saved = String(decoding: data, as: UTF8.self)
            content = saved
            lastSavedContent = saved
            fileExists = true
            hasUnsavedChanges = false
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
            errorMessage = error.localizedDescription
        }
    }

    private func normalizedData() throws -> Data {
        switch validationMode {
        case .none:
            return Data(content.utf8)
        case .json:
            let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else {
                throw NSError(domain: "ClaudeControlPane.TextFileManager", code: 1, userInfo: [
                    NSLocalizedDescriptionKey: "JSON files cannot be empty."
                ])
            }
            let object = try JSONSerialization.jsonObject(with: Data(trimmed.utf8))
            let data = try JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys])
            var normalized = String(decoding: data, as: UTF8.self)
            if !normalized.hasSuffix("\n") {
                normalized.append("\n")
            }
            return Data(normalized.utf8)
        }
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
