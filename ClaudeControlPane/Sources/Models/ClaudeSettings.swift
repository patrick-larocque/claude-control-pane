import Foundation

struct ClaudeSettings: Sendable, Equatable {
    var permissions: PermissionsConfig
    var hooks: [String: [HookGroup]]
    var env: [String: String]
    var extraFields: [String: AnyCodableValue]

    static let knownHookEvents = ["Stop", "PreToolUse", "PostToolUse", "Notification", "SubagentStop"]

    init(
        permissions: PermissionsConfig = PermissionsConfig(),
        hooks: [String: [HookGroup]] = [:],
        env: [String: String] = [:],
        extraFields: [String: AnyCodableValue] = [:]
    ) {
        self.permissions = permissions
        self.hooks = hooks
        self.env = env
        self.extraFields = extraFields
    }
}

extension ClaudeSettings {
    static func decode(from data: Data) throws -> ClaudeSettings {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let decoder = JSONDecoder()

        var permissions = PermissionsConfig()
        if let permDict = json["permissions"] {
            let permData = try JSONSerialization.data(withJSONObject: permDict)
            permissions = try decoder.decode(PermissionsConfig.self, from: permData)
        }

        var hooks: [String: [HookGroup]] = [:]
        if let hooksDict = json["hooks"] as? [String: Any] {
            for (event, value) in hooksDict {
                let hookData = try JSONSerialization.data(withJSONObject: value)
                hooks[event] = try decoder.decode([HookGroup].self, from: hookData)
            }
        }

        var env: [String: String] = [:]
        if let envDict = json["env"] as? [String: String] {
            env = envDict
        }

        let knownKeys: Set<String> = ["permissions", "hooks", "env"]
        var extraFields: [String: AnyCodableValue] = [:]
        for (key, value) in json where !knownKeys.contains(key) {
            extraFields[key] = AnyCodableValue.from(value)
        }

        return ClaudeSettings(
            permissions: permissions,
            hooks: hooks,
            env: env,
            extraFields: extraFields
        )
    }

    static func loadFromFile(_ path: String) -> ClaudeSettings? {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? ClaudeSettings.decode(from: data)
    }

    func encode() throws -> Data {
        var dict: [String: Any] = [:]

        for (key, value) in extraFields {
            dict[key] = value.toAny()
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]

        let permData = try encoder.encode(permissions)
        let permObj = try JSONSerialization.jsonObject(with: permData)
        dict["permissions"] = permObj

        if !hooks.isEmpty {
            var hooksDict: [String: Any] = [:]
            for (event, groups) in hooks {
                let groupData = try encoder.encode(groups)
                hooksDict[event] = try JSONSerialization.jsonObject(with: groupData)
            }
            dict["hooks"] = hooksDict
        }

        if !env.isEmpty {
            dict["env"] = env
        }

        return try JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        )
    }
}
