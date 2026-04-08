import SwiftUI

struct InstructionFileEntry: Identifiable, Equatable {
    let id = UUID()
    let title: String
    let subtitle: String
    let filePath: String
    let defaultContent: String
}

struct InstructionsWorkspaceView: View {
    let title: String
    let summary: String
    let files: [InstructionFileEntry]
    let rulesPath: String
    let outputStylesPath: String
    let hooksPath: String

    @State private var selection: InstructionFileEntry?

    var body: some View {
        let selectionBinding = Binding<UUID?>(
            get: { selection?.id },
            set: { newValue in
                selection = files.first { $0.id == newValue }
            }
        )

        TabView {
            HSplitView {
                List(files, selection: selectionBinding) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.title)
                        Text(entry.subtitle)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(entry.id)
                }
                .frame(minWidth: 220)

                if let selection {
                    ManagedTextEditorView(
                        title: selection.title,
                        subtitle: selection.subtitle,
                        filePath: selection.filePath,
                        defaultContent: selection.defaultContent
                    )
                    .id(selection.id)
                } else {
                    ContentUnavailableView(
                        "No File Selected",
                        systemImage: "text.page",
                        description: Text("Choose one of the instruction files.")
                    )
                }
            }
            .tabItem { Label("Files", systemImage: "doc.text") }

            DirectoryTextBrowserView(
                title: "Rules",
                directoryPath: rulesPath,
                summary: "Markdown rule files loaded into Claude context when relevant.",
                defaultNewFileName: "rule",
                templateContent: """
                # Rule

                Explain the rule and when it should apply.
                """,
                allowedExtensions: ["md"]
            )
            .tabItem { Label("Rules", systemImage: "list.bullet.rectangle") }

            DirectoryTextBrowserView(
                title: "Output Styles",
                directoryPath: outputStylesPath,
                summary: "Custom output styles that can be selected from Claude settings.",
                defaultNewFileName: "style",
                templateContent: """
                # Output Style

                Describe the desired tone, structure, and response shape.
                """,
                allowedExtensions: ["md"]
            )
            .tabItem { Label("Output Styles", systemImage: "paintbrush.pointed") }

            DirectoryTextBrowserView(
                title: "Hook Scripts",
                directoryPath: hooksPath,
                summary: "Referenced shell or script files used by hook handlers.",
                defaultNewFileName: "hook.sh",
                templateContent: "#!/bin/bash\n",
                allowedExtensions: nil
            )
            .tabItem { Label("Hook Scripts", systemImage: "terminal") }
        }
        .onAppear {
            if selection == nil {
                selection = files.first
            }
        }
    }
}
