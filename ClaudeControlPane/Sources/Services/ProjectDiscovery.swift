import Foundation

struct ProjectDiscovery {
    static let scanDirectories = [
        "Documents", "code", "Developer", "Projects", "src"
    ]

    static let maxDepth = 4

    static func discoverProjects() -> [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let fm = FileManager.default
        var found: [String] = []

        for dir in scanDirectories {
            let scanURL = URL(fileURLWithPath: "\(home)/\(dir)")
            guard fm.fileExists(atPath: scanURL.path) else { continue }
            scanRecursively(url: scanURL, fileManager: fm, depth: 0, found: &found)
        }

        return found.sorted()
    }

    private static func scanRecursively(
        url: URL,
        fileManager fm: FileManager,
        depth: Int,
        found: inout [String]
    ) {
        guard depth < maxDepth else { return }

        let settingsPath = url.appendingPathComponent(".claude/settings.json").path
        if fm.fileExists(atPath: settingsPath) {
            found.append(url.path)
            // Don't recurse into projects that already matched
            return
        }

        guard let children = try? fm.contentsOfDirectory(atPath: url.path) else { return }
        for child in children {
            // Skip hidden directories and common non-project dirs
            if child.hasPrefix(".") || child == "node_modules" || child == ".build" { continue }

            let childURL = url.appendingPathComponent(child)
            var isDir: ObjCBool = false
            if fm.fileExists(atPath: childURL.path, isDirectory: &isDir), isDir.boolValue {
                scanRecursively(url: childURL, fileManager: fm, depth: depth + 1, found: &found)
            }
        }
    }
}
