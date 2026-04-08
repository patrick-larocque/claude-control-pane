import SwiftUI

struct PermissionsView: View {
    @Bindable var manager: SettingsFileManager

    private let modeOptions = ["default", "acceptEdits", "plan", "auto", "dontAsk", "bypassPermissions"]

    var body: some View {
        Form {
            Section("Default Mode") {
                Picker("Permission Mode", selection: Binding(
                    get: { manager.settings.permissions.defaultMode ?? "default" },
                    set: { newValue in
                        manager.updateSettings { settings in
                            settings.permissions.defaultMode = newValue == "default" ? nil : newValue
                        }
                    }
                )) {
                    ForEach(modeOptions, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(.menu)
            }

            PermissionListSection(
                title: "Allow",
                items: manager.settings.permissions.allow,
                onAdd: { pattern in
                    manager.updateSettings { $0.permissions.allow.append(pattern) }
                },
                onRemove: { index in
                    manager.updateSettings { $0.permissions.allow.remove(at: index) }
                },
                onUpdate: { index, value in
                    manager.updateSettings { $0.permissions.allow[index] = value }
                }
            )

            PermissionListSection(
                title: "Deny",
                items: manager.settings.permissions.deny,
                onAdd: { pattern in
                    manager.updateSettings { $0.permissions.deny.append(pattern) }
                },
                onRemove: { index in
                    manager.updateSettings { $0.permissions.deny.remove(at: index) }
                },
                onUpdate: { index, value in
                    manager.updateSettings { $0.permissions.deny[index] = value }
                }
            )

            PermissionListSection(
                title: "Ask",
                items: manager.settings.permissions.ask,
                onAdd: { pattern in
                    manager.updateSettings { $0.permissions.ask.append(pattern) }
                },
                onRemove: { index in
                    manager.updateSettings { $0.permissions.ask.remove(at: index) }
                },
                onUpdate: { index, value in
                    manager.updateSettings { $0.permissions.ask[index] = value }
                }
            )
        }
        .formStyle(.grouped)
    }
}

struct PermissionListSection: View {
    let title: String
    let items: [String]
    var onAdd: (String) -> Void
    var onRemove: (Int) -> Void
    var onUpdate: (Int, String) -> Void

    @State private var newItem = ""

    var body: some View {
        Section(title) {
            if items.isEmpty {
                Text("No patterns configured")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(Array(items.enumerated()), id: \.offset) { index, item in
                    HStack {
                        PermissionItemField(
                            value: item,
                            onCommit: { newValue in
                                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                                guard !trimmed.isEmpty else { return }
                                // Prevent duplicates: skip if value already exists at a different index
                                guard !items.enumerated().contains(where: { $0.offset != index && $0.element == trimmed }) else { return }
                                onUpdate(index, trimmed)
                            }
                        )
                        Button(role: .destructive) {
                            onRemove(index)
                        } label: {
                            Image(systemName: "trash")
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            HStack {
                TextField("e.g. Bash(git *)", text: $newItem)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        addItem()
                    }
                Button("Add") {
                    addItem()
                }
                .disabled(newItem.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
    }

    private func addItem() {
        let trimmed = newItem.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !items.contains(trimmed) else {
            newItem = ""
            return
        }
        onAdd(trimmed)
        newItem = ""
    }
}

struct PermissionItemField: View {
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
        TextField("Pattern", text: $value)
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
