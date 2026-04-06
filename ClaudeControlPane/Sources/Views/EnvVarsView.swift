import SwiftUI

struct EnvVarsView: View {
    @Bindable var manager: SettingsFileManager

    @State private var newKey = ""
    @State private var newValue = ""
    @State private var showOverwriteWarning = false

    private var sortedKeys: [String] {
        manager.settings.env.keys.sorted()
    }

    var body: some View {
        Form {
            Section("Environment Variables") {
                if manager.settings.env.isEmpty {
                    Text("No environment variables configured")
                        .foregroundStyle(.secondary)
                        .font(.callout)
                } else {
                    ForEach(sortedKeys, id: \.self) { key in
                        HStack {
                            Text(key)
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 150, alignment: .leading)

                            EnvValueField(
                                value: manager.settings.env[key] ?? "",
                                onCommit: { newVal in
                                    manager.updateSettings { $0.env[key] = newVal }
                                }
                            )

                            Button(role: .destructive) {
                                manager.updateSettings { $0.env.removeValue(forKey: key) }
                            } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }

                HStack {
                    TextField("KEY", text: $newKey)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .frame(minWidth: 150)
                        .onChange(of: newKey) { showOverwriteWarning = false }
                    TextField("value", text: $newValue)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                    Button("Add") {
                        addEnvVar()
                    }
                    .disabled(newKey.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .onSubmit {
                    addEnvVar()
                }

                if showOverwriteWarning {
                    Text("Key already exists — edit the value inline above")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .formStyle(.grouped)
    }

    private func addEnvVar() {
        let key = newKey.trimmingCharacters(in: .whitespaces)
        guard !key.isEmpty else { return }
        if manager.settings.env[key] != nil {
            showOverwriteWarning = true
            return
        }
        showOverwriteWarning = false
        let value = newValue
        manager.updateSettings { $0.env[key] = value }
        newKey = ""
        newValue = ""
    }
}

struct EnvValueField: View {
    let externalValue: String
    @State private var value: String
    @FocusState private var isFocused: Bool
    var onCommit: (String) -> Void

    init(value: String, onCommit: @escaping (String) -> Void) {
        self.externalValue = value
        self._value = State(initialValue: value)
        self.onCommit = onCommit
    }

    var body: some View {
        TextField("Value", text: $value)
            .textFieldStyle(.roundedBorder)
            .font(.system(.body, design: .monospaced))
            .focused($isFocused)
            .onSubmit {
                onCommit(value)
            }
            .onChange(of: isFocused) { _, newFocused in
                if !newFocused { onCommit(value) }
            }
            .onChange(of: externalValue) { _, newValue in
                value = newValue
            }
    }
}
