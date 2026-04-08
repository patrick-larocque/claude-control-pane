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
                    HookMatcherRowView(
                        matcher: group.matcher ?? "",
                        onUpdate: { newMatcher in
                            manager.updateSettings { settings in
                                guard let gi = settings.hooks[event]?.firstIndex(where: { $0.id == groupId }) else { return }
                                settings.hooks[event]?[gi].matcher = newMatcher.isEmpty ? nil : newMatcher
                            }
                        }
                    )
                    ForEach(group.hooks) { hook in
                        let hookId = hook.id
                        HookRowView(
                            hook: hook,
                            onUpdate: { updatedHook in
                                manager.updateSettings { settings in
                                    guard let gi = settings.hooks[event]?.firstIndex(where: { $0.id == groupId }),
                                          let hi = settings.hooks[event]?[gi].hooks.firstIndex(where: { $0.id == hookId })
                                    else { return }
                                    settings.hooks[event]?[gi].hooks[hi] = updatedHook
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

struct HookMatcherRowView: View {
    let externalMatcher: String
    @State private var matcher: String
    @FocusState private var isFocused: Bool
    var onUpdate: (String) -> Void

    init(matcher: String, onUpdate: @escaping (String) -> Void) {
        self.externalMatcher = matcher
        self._matcher = State(initialValue: matcher)
        self.onUpdate = onUpdate
    }

    var body: some View {
        HStack {
            Text("Matcher")
                .foregroundStyle(.secondary)
                .font(.callout)
                .frame(width: 60, alignment: .leading)
            TextField("all tools", text: $matcher)
                .textFieldStyle(.roundedBorder)
                .font(.system(.callout, design: .monospaced))
                .focused($isFocused)
                .onSubmit { onUpdate(matcher) }
                .onChange(of: isFocused) { _, newFocused in
                    if !newFocused { onUpdate(matcher) }
                }
        }
        .onChange(of: externalMatcher) { _, newValue in
            matcher = newValue
        }
    }
}

struct HookRowView: View {
    let externalHook: Hook
    @State private var hook: Hook
    @FocusState private var isFocused: Bool
    var onUpdate: (Hook) -> Void
    var onDelete: () -> Void

    init(hook: Hook, onUpdate: @escaping (Hook) -> Void, onDelete: @escaping () -> Void) {
        self.externalHook = hook
        self._hook = State(initialValue: hook)
        self.onUpdate = onUpdate
        self.onDelete = onDelete
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Picker("Type", selection: Binding(
                    get: { hook.type },
                    set: { newType in
                        hook.normalizePrimaryPayload(for: newType)
                        onUpdate(hook)
                    }
                )) {
                    Text("command").tag("command")
                    Text("http").tag("http")
                    Text("prompt").tag("prompt")
                    Text("agent").tag("agent")
                }
                .labelsHidden()
                .frame(width: 110)

                TextField(hook.primaryLabel, text: Binding(
                    get: { hook.primaryValue },
                    set: { newValue in
                        hook.updatePrimaryValue(newValue)
                    }
                ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
                    .focused($isFocused)
                    .onSubmit {
                        onUpdate(hook)
                    }
                    .onChange(of: isFocused) { _, newFocused in
                        if !newFocused { onUpdate(hook) }
                    }
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            if let ifCondition = hook.ifCondition, !ifCondition.isEmpty {
                Text("if: \(ifCondition)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
            if hook.primaryValue.trimmingCharacters(in: .whitespaces).isEmpty {
                Text("\(hook.primaryLabel) cannot be empty — this hook will fail at runtime")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .onChange(of: externalHook) { _, newValue in
            hook = newValue
        }
    }
}
