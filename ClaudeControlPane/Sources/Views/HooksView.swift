import SwiftUI

struct HooksView: View {
    @Bindable var manager: SettingsFileManager

    private var hasSoundHook: Bool {
        guard let groups = manager.settings.hooks["Stop"] else { return false }
        return groups.contains { group in
            group.hooks.contains { $0.command.contains("afplay") }
        }
    }

    private var customHookEvents: [String] {
        manager.settings.hooks.keys
            .filter { !ClaudeSettings.knownHookEvents.contains($0) }
            .sorted()
    }

    var body: some View {
        Form {
            Section {
                Toggle("Play sound when Claude finishes", isOn: Binding(
                    get: { hasSoundHook },
                    set: { enabled in
                        manager.updateSettings { settings in
                            if enabled {
                                let hook = Hook(type: "command", command: "afplay /System/Library/Sounds/Funk.aiff")
                                let group = HookGroup(hooks: [hook])
                                settings.hooks["Stop", default: []].append(group)
                            } else {
                                settings.hooks["Stop"]?.removeAll { group in
                                    group.hooks.contains { $0.command.contains("afplay") }
                                }
                                if settings.hooks["Stop"]?.isEmpty == true {
                                    settings.hooks.removeValue(forKey: "Stop")
                                }
                            }
                        }
                    }
                ))
            } header: {
                Text("Quick Settings")
            }

            ForEach(ClaudeSettings.knownHookEvents, id: \.self) { event in
                hookEventSection(event: event)
            }

            if !customHookEvents.isEmpty {
                ForEach(customHookEvents, id: \.self) { event in
                    hookEventSection(event: event)
                }
            }
        }
        .formStyle(.grouped)
    }

    @ViewBuilder
    private func hookEventSection(event: String) -> some View {
        Section {
            let groups = manager.settings.hooks[event] ?? []
            if groups.isEmpty {
                Text("No hooks configured")
                    .foregroundStyle(.secondary)
                    .font(.callout)
            } else {
                ForEach(groups) { group in
                    let groupId = group.id
                    ForEach(group.hooks) { hook in
                        let hookId = hook.id
                        HookRowView(
                            command: hook.command,
                            onUpdate: { newCommand in
                                manager.updateSettings { settings in
                                    guard let gi = settings.hooks[event]?.firstIndex(where: { $0.id == groupId }),
                                          let hi = settings.hooks[event]?[gi].hooks.firstIndex(where: { $0.id == hookId })
                                    else { return }
                                    settings.hooks[event]?[gi].hooks[hi].command = newCommand
                                }
                            },
                            onDelete: {
                                manager.updateSettings { settings in
                                    guard let gi = settings.hooks[event]?.firstIndex(where: { $0.id == groupId }) else { return }
                                    settings.hooks[event]?[gi].hooks.removeAll { $0.id == hookId }
                                    if settings.hooks[event]?[gi].hooks.isEmpty == true {
                                        settings.hooks[event]?.remove(at: gi)
                                    }
                                    if settings.hooks[event]?.isEmpty == true {
                                        settings.hooks.removeValue(forKey: event)
                                    }
                                }
                            }
                        )
                    }
                }
            }

            Button("Add Hook") {
                manager.updateSettings { settings in
                    let hook = Hook(type: "command", command: "")
                    let group = HookGroup(hooks: [hook])
                    settings.hooks[event, default: []].append(group)
                }
            }
            .buttonStyle(.borderless)
        } header: {
            Text(event)
        }
    }
}

struct HookRowView: View {
    let externalCommand: String
    @State private var command: String
    @FocusState private var isFocused: Bool
    var onUpdate: (String) -> Void
    var onDelete: () -> Void

    init(command: String, onUpdate: @escaping (String) -> Void, onDelete: @escaping () -> Void) {
        self.externalCommand = command
        self._command = State(initialValue: command)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                TextField("Command", text: $command)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($isFocused)
                    .onSubmit {
                        onUpdate(command)
                    }
                    .onChange(of: isFocused) { _, newFocused in
                        if !newFocused { onUpdate(command) }
                    }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            if command.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("Command cannot be empty — hook will fail at runtime")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .onChange(of: externalCommand) { _, newValue in
            command = newValue
        }
    }
}
