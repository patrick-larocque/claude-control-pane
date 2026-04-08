import SwiftUI

struct AdvancedSettingsView: View {
    @Bindable var manager: SettingsFileManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Form {
                    Section("Core Behavior") {
                        OptionalStringField(
                            title: "Model",
                            value: manager.settings.model ?? "",
                            placeholder: "claude-sonnet-4-6"
                        ) { newValue in
                            manager.updateSettings { $0.model = normalized(newValue) }
                        }

                        OptionalStringField(
                            title: "Language",
                            value: manager.settings.language ?? "",
                            placeholder: "english"
                        ) { newValue in
                            manager.updateSettings { $0.language = normalized(newValue) }
                        }

                        OptionalStringField(
                            title: "Output Style",
                            value: manager.settings.outputStyle ?? "",
                            placeholder: "Explanatory"
                        ) { newValue in
                            manager.updateSettings { $0.outputStyle = normalized(newValue) }
                        }

                        OptionalStringField(
                            title: "Agent",
                            value: manager.settings.agent ?? "",
                            placeholder: "code-reviewer"
                        ) { newValue in
                            manager.updateSettings { $0.agent = normalized(newValue) }
                        }
                    }

                    Section("Session Behavior") {
                        OptionalStringField(
                            title: "Plans Directory",
                            value: manager.settings.plansDirectory ?? "",
                            placeholder: "~/.claude/plans"
                        ) { newValue in
                            manager.updateSettings { $0.plansDirectory = normalized(newValue) }
                        }

                        OptionalStringField(
                            title: "Default Shell",
                            value: manager.settings.defaultShell ?? "",
                            placeholder: "bash"
                        ) { newValue in
                            manager.updateSettings { $0.defaultShell = normalized(newValue) }
                        }

                        OptionalStringField(
                            title: "Effort Level",
                            value: manager.settings.effortLevel ?? "",
                            placeholder: "high"
                        ) { newValue in
                            manager.updateSettings { $0.effortLevel = normalized(newValue) }
                        }

                        OptionalStringField(
                            title: "Auto Updates Channel",
                            value: manager.settings.autoUpdatesChannel ?? "",
                            placeholder: "latest"
                        ) { newValue in
                            manager.updateSettings { $0.autoUpdatesChannel = normalized(newValue) }
                        }
                    }

                    Section("Doc-backed Toggles") {
                        Toggle("Voice Enabled", isOn: optionalBoolBinding(
                            get: manager.settings.voiceEnabled,
                            set: { newValue in
                                manager.updateSettings { $0.voiceEnabled = newValue }
                            }
                        ))
                        Toggle("Prefers Reduced Motion", isOn: optionalBoolBinding(
                            get: manager.settings.prefersReducedMotion,
                            set: { newValue in
                                manager.updateSettings { $0.prefersReducedMotion = newValue }
                            }
                        ))
                        Toggle("Respect .gitignore", isOn: optionalBoolBinding(
                            get: manager.settings.respectGitignore,
                            set: { newValue in
                                manager.updateSettings { $0.respectGitignore = newValue }
                            }
                        ))
                        Toggle("Show Thinking Summaries", isOn: optionalBoolBinding(
                            get: manager.settings.showThinkingSummaries,
                            set: { newValue in
                                manager.updateSettings { $0.showThinkingSummaries = newValue }
                            }
                        ))
                        Toggle("Include Git Instructions", isOn: optionalBoolBinding(
                            get: manager.settings.includeGitInstructions,
                            set: { newValue in
                                manager.updateSettings { $0.includeGitInstructions = newValue }
                            }
                        ))
                        Toggle("Use Auto Mode During Plan", isOn: optionalBoolBinding(
                            get: manager.settings.useAutoModeDuringPlan,
                            set: { newValue in
                                manager.updateSettings { $0.useAutoModeDuringPlan = newValue }
                            }
                        ))
                    }
                }
                .formStyle(.grouped)

                JSONObjectFieldView(
                    title: "Status Line",
                    subtitle: "Structured object stored as `statusLine` in settings.json.",
                    currentValue: manager.settings.statusLine
                ) { newValue in
                    manager.updateSettings { $0.statusLine = newValue }
                }

                JSONObjectFieldView(
                    title: "Attribution",
                    subtitle: "Structured object stored as `attribution` in settings.json.",
                    currentValue: manager.settings.attribution
                ) { newValue in
                    manager.updateSettings { $0.attribution = newValue }
                }

                JSONObjectFieldView(
                    title: "Sandbox",
                    subtitle: "Structured object stored as `sandbox` in settings.json.",
                    currentValue: manager.settings.sandbox
                ) { newValue in
                    manager.updateSettings { $0.sandbox = newValue }
                }

                JSONObjectFieldView(
                    title: "Worktree",
                    subtitle: "Structured object stored as `worktree` in settings.json.",
                    currentValue: manager.settings.worktree
                ) { newValue in
                    manager.updateSettings { $0.worktree = newValue }
                }
            }
            .padding(.bottom)
        }
    }

    private func normalized(_ value: String) -> String? {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

    private func optionalBoolBinding(get value: Bool?, set: @escaping (Bool?) -> Void) -> Binding<Bool> {
        Binding(
            get: { value ?? false },
            set: { newValue in
                set(newValue)
            }
        )
    }
}

private struct OptionalStringField: View {
    let title: String
    let externalValue: String
    let placeholder: String
    var onCommit: (String) -> Void

    @State private var value: String
    @FocusState private var isFocused: Bool

    init(title: String, value: String, placeholder: String, onCommit: @escaping (String) -> Void) {
        self.title = title
        self.externalValue = value
        self.placeholder = placeholder
        self.onCommit = onCommit
        _value = State(initialValue: value)
    }

    var body: some View {
        HStack {
            Text(title)
                .frame(width: 160, alignment: .leading)
            TextField(placeholder, text: $value)
                .textFieldStyle(.roundedBorder)
                .font(.system(.body, design: .monospaced))
                .focused($isFocused)
                .onSubmit { onCommit(value) }
                .onChange(of: isFocused) { _, newValue in
                    if !newValue {
                        onCommit(value)
                    }
                }
        }
        .onChange(of: externalValue) { _, newValue in
            value = newValue
        }
    }
}
