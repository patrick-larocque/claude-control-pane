import SwiftUI

struct SharedMCPView: View {
    let filePath: String

    var body: some View {
        ManagedTextEditorView(
            title: "Shared MCP",
            subtitle: "Project-scoped MCP servers are stored in `.mcp.json`.",
            filePath: filePath,
            defaultContent: """
            {
              "mcpServers": {}
            }
            """,
            validationMode: .json
        )
    }
}

struct LocalMCPView: View {
    let manager: GlobalConfigFileManager
    let projectPath: String

    @State private var text: String
    @State private var errorMessage = ""

    init(manager: GlobalConfigFileManager, projectPath: String) {
        self.manager = manager
        self.projectPath = projectPath
        _text = State(initialValue: AnyCodableValue.jsonString(from: manager.config.localMcpServers(for: projectPath) ?? .dictionary([:])))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Local MCP")
                .font(.headline)
            Text("Local-only MCP servers for this project are stored inside `~/.claude.json` under the project entry.")
                .font(.callout)
                .foregroundStyle(.secondary)

            Text(projectPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)

            TextEditor(text: $text)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 320)
                .padding(8)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 12))

            HStack {
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Spacer()

                Button("Reload") {
                    text = AnyCodableValue.jsonString(from: manager.config.localMcpServers(for: projectPath) ?? .dictionary([:]))
                    errorMessage = ""
                }
                .buttonStyle(.borderless)

                Button("Save") {
                    do {
                        let parsed = try AnyCodableValue.parseJSONObject(from: text, emptyHandling: .emptyObject) ?? .dictionary([:])
                        manager.updateConfig {
                            $0.setLocalMcpServers(parsed, for: projectPath)
                        }
                        text = AnyCodableValue.jsonString(from: parsed)
                        errorMessage = ""
                    } catch {
                        errorMessage = error.localizedDescription
                    }
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onChange(of: manager.config) { _, _ in
            text = AnyCodableValue.jsonString(from: manager.config.localMcpServers(for: projectPath) ?? .dictionary([:]))
        }
    }
}
