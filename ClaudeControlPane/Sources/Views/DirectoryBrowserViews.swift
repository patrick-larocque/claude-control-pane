import SwiftUI

private struct FileEntry: Identifiable, Equatable {
    let path: String
    let displayName: String

    var id: String { path }
}

struct DirectoryTextBrowserView: View {
    let title: String
    let directoryPath: String
    let summary: String
    let defaultNewFileName: String
    let templateContent: String
    var allowedExtensions: Set<String>? = nil
    var allowsCreate = true

    @State private var entries: [FileEntry] = []
    @State private var selection: String?
    @State private var newFileName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(summary)
                .font(.callout)
                .foregroundStyle(.secondary)

            HSplitView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(directoryPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    List(entries, selection: $selection) { entry in
                        Text(entry.displayName)
                            .font(.system(.body, design: .monospaced))
                            .tag(entry.path)
                    }
                    .frame(minWidth: 200)

                    if allowsCreate {
                        HStack {
                            TextField(defaultNewFileName, text: $newFileName)
                                .textFieldStyle(.roundedBorder)
                            Button("Create") {
                                createEntry()
                            }
                            .disabled(newFileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                }

                if let selection {
                    ManagedTextEditorView(
                        title: URL(fileURLWithPath: selection).lastPathComponent,
                        subtitle: "Editing file contents directly.",
                        filePath: selection
                    )
                    .id(selection)
                } else {
                    ContentUnavailableView(
                        "No File Selected",
                        systemImage: "doc.text",
                        description: Text("Choose a file or create a new one.")
                    )
                }
            }
        }
        .onAppear {
            reloadEntries()
        }
    }

    private func reloadEntries() {
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(atPath: directoryPath) else {
            entries = []
            selection = nil
            return
        }

        entries = children
            .sorted()
            .compactMap { child in
                let fullPath = URL(fileURLWithPath: directoryPath).appendingPathComponent(child).path
                var isDirectory: ObjCBool = false
                guard fm.fileExists(atPath: fullPath, isDirectory: &isDirectory), !isDirectory.boolValue else {
                    return nil
                }
                if let allowedExtensions, !allowedExtensions.isEmpty {
                    let fileExtension = URL(fileURLWithPath: fullPath).pathExtension.lowercased()
                    guard allowedExtensions.contains(fileExtension) else {
                        return nil
                    }
                }
                return FileEntry(path: fullPath, displayName: child)
            }

        if selection == nil || !entries.contains(where: { $0.path == selection }) {
            selection = entries.first?.path
        }
    }

    private func createEntry() {
        let name = newFileName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let fileName: String
        if let allowedExtensions, allowedExtensions.count == 1, let onlyExtension = allowedExtensions.first,
           !name.lowercased().hasSuffix(".\(onlyExtension)") {
            fileName = "\(name).\(onlyExtension)"
        } else {
            fileName = name
        }

        let url = URL(fileURLWithPath: directoryPath).appendingPathComponent(fileName)
        try? FileManager.default.createDirectory(
            at: URL(fileURLWithPath: directoryPath),
            withIntermediateDirectories: true
        )
        FileManager.default.createFile(atPath: url.path, contents: Data(templateContent.utf8))
        newFileName = ""
        reloadEntries()
        selection = url.path
    }
}

struct SkillsBrowserView: View {
    let directoryPath: String

    @State private var entries: [FileEntry] = []
    @State private var selection: String?
    @State private var newSkillName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Skills")
                .font(.headline)
            Text("Skills use the `<name>/SKILL.md` layout described in the Claude docs.")
                .font(.callout)
                .foregroundStyle(.secondary)

            HSplitView {
                VStack(alignment: .leading, spacing: 8) {
                    Text(directoryPath)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)

                    List(entries, selection: $selection) { entry in
                        Text(entry.displayName)
                            .font(.system(.body, design: .monospaced))
                            .tag(entry.path)
                    }
                    .frame(minWidth: 220)

                    HStack {
                        TextField("new-skill", text: $newSkillName)
                            .textFieldStyle(.roundedBorder)
                        Button("Create") {
                            createSkill()
                        }
                        .disabled(newSkillName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }

                if let selection {
                    ManagedTextEditorView(
                        title: URL(fileURLWithPath: selection).deletingLastPathComponent().lastPathComponent,
                        subtitle: "Edit the skill contract directly.",
                        filePath: selection,
                        defaultContent: """
                        # Skill

                        Describe what this skill does and when Claude should use it.
                        """
                    )
                    .id(selection)
                } else {
                    ContentUnavailableView(
                        "No Skill Selected",
                        systemImage: "sparkles.rectangle.stack",
                        description: Text("Choose a skill or create a new one.")
                    )
                }
            }
        }
        .onAppear {
            reloadEntries()
        }
    }

    private func reloadEntries() {
        let fm = FileManager.default
        guard let children = try? fm.contentsOfDirectory(atPath: directoryPath) else {
            entries = []
            selection = nil
            return
        }

        entries = children
            .sorted()
            .compactMap { child in
                let skillPath = URL(fileURLWithPath: directoryPath).appendingPathComponent(child).appendingPathComponent("SKILL.md").path
                return fm.fileExists(atPath: skillPath) ? FileEntry(path: skillPath, displayName: child) : nil
            }

        if selection == nil || !entries.contains(where: { $0.path == selection }) {
            selection = entries.first?.path
        }
    }

    private func createSkill() {
        let skillName = newSkillName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !skillName.isEmpty else { return }

        let directoryURL = URL(fileURLWithPath: directoryPath).appendingPathComponent(skillName)
        let fileURL = directoryURL.appendingPathComponent("SKILL.md")
        try? FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        FileManager.default.createFile(atPath: fileURL.path, contents: Data("""
        # \(skillName)

        Describe this skill and when it should be triggered.
        """.utf8))

        newSkillName = ""
        reloadEntries()
        selection = fileURL.path
    }
}
