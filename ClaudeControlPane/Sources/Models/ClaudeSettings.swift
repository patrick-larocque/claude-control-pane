import Foundation

struct ClaudeSettings: Sendable, Equatable {
    var permissions: PermissionsConfig
    var hooks: [String: [HookGroup]]
    var env: [String: String]
    var enabledPlugins: [String: Bool]
    var extraKnownMarketplaces: [String: AnyCodableValue]
    var extraFields: [String: AnyCodableValue]
    var presentKeys: Set<String>

    static let knownHookEvents = ["Stop", "PreToolUse", "PostToolUse", "Notification", "SubagentStop"]

    init(
        permissions: PermissionsConfig = PermissionsConfig(),
        hooks: [String: [HookGroup]] = [:],
        env: [String: String] = [:],
        enabledPlugins: [String: Bool] = [:],
        extraKnownMarketplaces: [String: AnyCodableValue] = [:],
        extraFields: [String: AnyCodableValue] = [:],
        presentKeys: Set<String> = []
    ) {
        self.permissions = permissions
        self.hooks = hooks
        self.env = env
        self.enabledPlugins = enabledPlugins
        self.extraKnownMarketplaces = extraKnownMarketplaces
        self.extraFields = extraFields
        self.presentKeys = presentKeys
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
        if let envDict = json["env"] as? [String: Any] {
            for (key, value) in envDict {
                if let s = value as? String {
                    env[key] = s
                } else if let n = value as? NSNumber {
                    env[key] = n.stringValue
                } else {
                    env[key] = String(describing: value)
                }
            }
        }

        var enabledPlugins: [String: Bool] = [:]
        if let pluginsDict = json["enabledPlugins"] as? [String: Any] {
            for (key, value) in pluginsDict {
                if let b = value as? Bool {
                    enabledPlugins[key] = b
                } else if let n = value as? NSNumber {
                    enabledPlugins[key] = n.boolValue
                } else if let s = value as? String, s.lowercased() == "true" {
                    enabledPlugins[key] = true
                }
            }
        }

        var extraKnownMarketplaces: [String: AnyCodableValue] = [:]
        if let marketplacesDict = json["extraKnownMarketplaces"] as? [String: Any] {
            for (key, value) in marketplacesDict {
                extraKnownMarketplaces[key] = AnyCodableValue.from(value)
            }
        }

        let knownKeys: Set<String> = ["permissions", "hooks", "env", "enabledPlugins", "extraKnownMarketplaces"]
        var extraFields: [String: AnyCodableValue] = [:]
        for (key, value) in json where !knownKeys.contains(key) {
            extraFields[key] = AnyCodableValue.from(value)
        }

        let presentKeys = Set(json.keys)

        return ClaudeSettings(
            permissions: permissions,
            hooks: hooks,
            env: env,
            enabledPlugins: enabledPlugins,
            extraKnownMarketplaces: extraKnownMarketplaces,
            extraFields: extraFields,
            presentKeys: presentKeys
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

        if !permissions.isDefault || presentKeys.contains("permissions") {
            let permData = try encoder.encode(permissions)
            let permObj = try JSONSerialization.jsonObject(with: permData)
            dict["permissions"] = permObj
        }

        if !hooks.isEmpty || presentKeys.contains("hooks") {
            var hooksDict: [String: Any] = [:]
            for (event, groups) in hooks {
                let groupData = try encoder.encode(groups)
                hooksDict[event] = try JSONSerialization.jsonObject(with: groupData)
            }
            dict["hooks"] = hooksDict
        }

        if !env.isEmpty || presentKeys.contains("env") {
            dict["env"] = env
        }

        if !enabledPlugins.isEmpty || presentKeys.contains("enabledPlugins") {
            dict["enabledPlugins"] = enabledPlugins
        }

        if !extraKnownMarketplaces.isEmpty || presentKeys.contains("extraKnownMarketplaces") {
            var marketplacesDict: [String: Any] = [:]
            for (key, value) in extraKnownMarketplaces {
                marketplacesDict[key] = value.toAny()
            }
            dict["extraKnownMarketplaces"] = marketplacesDict
        }

        return try JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        )
    }
}
