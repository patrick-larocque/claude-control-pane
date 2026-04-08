import SwiftUI

struct GlobalConfigView: View {
    @Bindable var manager: GlobalConfigFileManager

    var body: some View {
        TabView {
            Form {
                Section("Editor") {
                    Picker("Editor Mode", selection: Binding(
                        get: { manager.config.editorMode ?? "normal" },
                        set: { newValue in
                            manager.updateConfig { $0.editorMode = normalized(newValue) }
                        }
                    )) {
                        Text("normal").tag("normal")
                        Text("vim").tag("vim")
                    }
                    .pickerStyle(.segmented)
                }

                Section("Global Preferences") {
                    Toggle("Auto-connect IDE", isOn: boolBinding(
                        manager.config.autoConnectIde,
                        set: { newValue in
                            manager.updateConfig { $0.autoConnectIde = newValue }
                        }
                    ))
                    Toggle("Auto-install IDE Extension", isOn: boolBinding(
                        manager.config.autoInstallIdeExtension,
                        set: { newValue in
                            manager.updateConfig { $0.autoInstallIdeExtension = newValue }
                        }
                    ))
                    Toggle("Show Turn Duration", isOn: boolBinding(
                        manager.config.showTurnDuration,
                        set: { newValue in
                            manager.updateConfig { $0.showTurnDuration = newValue }
                        }
                    ))
                    Toggle("Terminal Progress Bar", isOn: boolBinding(
                        manager.config.terminalProgressBarEnabled,
                        set: { newValue in
                            manager.updateConfig { $0.terminalProgressBarEnabled = newValue }
                        }
                    ))
                }

                Section("Agent Teams") {
                    Picker("Teammate Mode", selection: Binding(
                        get: { manager.config.teammateMode ?? "auto" },
                        set: { newValue in
                            manager.updateConfig { $0.teammateMode = normalized(newValue) }
                        }
                    )) {
                        Text("auto").tag("auto")
                        Text("in-process").tag("in-process")
                        Text("tmux").tag("tmux")
                    }
                }
            }
            .formStyle(.grouped)
            .tabItem { Label("Preferences", systemImage: "slider.horizontal.3") }

            ManagedTextEditorView(
                title: "~/.claude.json",
                subtitle: "Global preferences, MCP local state, and other Claude metadata.",
                filePath: manager.filePath,
                defaultContent: "{}\n",
                validationMode: .json
            )
            .tabItem { Label("JSON", systemImage: "curlybraces") }
        }
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func boolBinding(_ value: Bool?, set: @escaping (Bool?) -> Void) -> Binding<Bool> {
        Binding(
            get: { value ?? false },
            set: { newValue in
                set(newValue)
            }
        )
    }
}
