import Foundation

struct ClaudeSettings: Sendable, Equatable {
    var permissions: PermissionsConfig
    var hooks: [String: [HookGroup]]
    var env: [String: String]
    var enabledPlugins: [String: Bool]
    var extraKnownMarketplaces: [String: AnyCodableValue]
    var statusLine: AnyCodableValue?
    var outputStyle: String?
    var model: String?
    var language: String?
    var agent: String?
    var plansDirectory: String?
    var defaultShell: String?
    var attribution: AnyCodableValue?
    var sandbox: AnyCodableValue?
    var worktree: AnyCodableValue?
    var voiceEnabled: Bool?
    var prefersReducedMotion: Bool?
    var respectGitignore: Bool?
    var showThinkingSummaries: Bool?
    var includeGitInstructions: Bool?
    var useAutoModeDuringPlan: Bool?
    var effortLevel: String?
    var autoUpdatesChannel: String?
    var extraFields: [String: AnyCodableValue]
    var presentKeys: Set<String>

    static let knownHookEvents = [
        "SessionStart", "InstructionsLoaded", "UserPromptSubmit",
        "PreToolUse", "PermissionRequest", "PermissionDenied",
        "PostToolUse", "PostToolUseFailure", "Notification",
        "SubagentStart", "SubagentStop", "TaskCreated",
        "TaskCompleted", "Stop", "StopFailure", "TeammateIdle",
        "ConfigChange", "CwdChanged", "FileChanged",
        "WorktreeCreate", "WorktreeRemove", "PreCompact",
        "PostCompact", "SessionEnd", "Elicitation",
        "ElicitationResult"
    ]

    init(
        permissions: PermissionsConfig = PermissionsConfig(),
        hooks: [String: [HookGroup]] = [:],
        env: [String: String] = [:],
        enabledPlugins: [String: Bool] = [:],
        extraKnownMarketplaces: [String: AnyCodableValue] = [:],
        statusLine: AnyCodableValue? = nil,
        outputStyle: String? = nil,
        model: String? = nil,
        language: String? = nil,
        agent: String? = nil,
        plansDirectory: String? = nil,
        defaultShell: String? = nil,
        attribution: AnyCodableValue? = nil,
        sandbox: AnyCodableValue? = nil,
        worktree: AnyCodableValue? = nil,
        voiceEnabled: Bool? = nil,
        prefersReducedMotion: Bool? = nil,
        respectGitignore: Bool? = nil,
        showThinkingSummaries: Bool? = nil,
        includeGitInstructions: Bool? = nil,
        useAutoModeDuringPlan: Bool? = nil,
        effortLevel: String? = nil,
        autoUpdatesChannel: String? = nil,
        extraFields: [String: AnyCodableValue] = [:],
        presentKeys: Set<String> = []
    ) {
        self.permissions = permissions
        self.hooks = hooks
        self.env = env
        self.enabledPlugins = enabledPlugins
        self.extraKnownMarketplaces = extraKnownMarketplaces
        self.statusLine = statusLine
        self.outputStyle = outputStyle
        self.model = model
        self.language = language
        self.agent = agent
        self.plansDirectory = plansDirectory
        self.defaultShell = defaultShell
        self.attribution = attribution
        self.sandbox = sandbox
        self.worktree = worktree
        self.voiceEnabled = voiceEnabled
        self.prefersReducedMotion = prefersReducedMotion
        self.respectGitignore = respectGitignore
        self.showThinkingSummaries = showThinkingSummaries
        self.includeGitInstructions = includeGitInstructions
        self.useAutoModeDuringPlan = useAutoModeDuringPlan
        self.effortLevel = effortLevel
        self.autoUpdatesChannel = autoUpdatesChannel
        self.extraFields = extraFields
        self.presentKeys = presentKeys
    }
}

extension ClaudeSettings {
    private static func stringValue(_ raw: Any?) -> String? {
        if let string = raw as? String {
            return string
        }
        return nil
    }

    private static func boolValue(_ raw: Any?) -> Bool? {
        if let bool = raw as? Bool {
            return bool
        }
        if let number = raw as? NSNumber {
            return number.boolValue
        }
        if let string = raw as? String {
            switch string.lowercased() {
            case "true", "1", "yes":
                return true
            case "false", "0", "no":
                return false
            default:
                return nil
            }
        }
        return nil
    }

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

        let statusLine = json["statusLine"].map(AnyCodableValue.from)
        let outputStyle = stringValue(json["outputStyle"])
        let model = stringValue(json["model"])
        let language = stringValue(json["language"])
        let agent = stringValue(json["agent"])
        let plansDirectory = stringValue(json["plansDirectory"])
        let defaultShell = stringValue(json["defaultShell"])
        let attribution = json["attribution"].map(AnyCodableValue.from)
        let sandbox = json["sandbox"].map(AnyCodableValue.from)
        let worktree = json["worktree"].map(AnyCodableValue.from)
        let voiceEnabled = boolValue(json["voiceEnabled"])
        let prefersReducedMotion = boolValue(json["prefersReducedMotion"])
        let respectGitignore = boolValue(json["respectGitignore"])
        let showThinkingSummaries = boolValue(json["showThinkingSummaries"])
        let includeGitInstructions = boolValue(json["includeGitInstructions"])
        let useAutoModeDuringPlan = boolValue(json["useAutoModeDuringPlan"])
        let effortLevel = stringValue(json["effortLevel"])
        let autoUpdatesChannel = stringValue(json["autoUpdatesChannel"])

        let knownKeys: Set<String> = [
            "permissions", "hooks", "env", "enabledPlugins", "extraKnownMarketplaces",
            "statusLine", "outputStyle", "model", "language", "agent",
            "plansDirectory", "defaultShell", "attribution", "sandbox",
            "worktree", "voiceEnabled", "prefersReducedMotion",
            "respectGitignore", "showThinkingSummaries",
            "includeGitInstructions", "useAutoModeDuringPlan",
            "effortLevel", "autoUpdatesChannel"
        ]
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
            statusLine: statusLine,
            outputStyle: outputStyle,
            model: model,
            language: language,
            agent: agent,
            plansDirectory: plansDirectory,
            defaultShell: defaultShell,
            attribution: attribution,
            sandbox: sandbox,
            worktree: worktree,
            voiceEnabled: voiceEnabled,
            prefersReducedMotion: prefersReducedMotion,
            respectGitignore: respectGitignore,
            showThinkingSummaries: showThinkingSummaries,
            includeGitInstructions: includeGitInstructions,
            useAutoModeDuringPlan: useAutoModeDuringPlan,
            effortLevel: effortLevel,
            autoUpdatesChannel: autoUpdatesChannel,
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

        if let statusLine {
            dict["statusLine"] = statusLine.toAny()
        }

        if let outputStyle {
            dict["outputStyle"] = outputStyle
        }

        if let model {
            dict["model"] = model
        }

        if let language {
            dict["language"] = language
        }

        if let agent {
            dict["agent"] = agent
        }

        if let plansDirectory {
            dict["plansDirectory"] = plansDirectory
        }

        if let defaultShell {
            dict["defaultShell"] = defaultShell
        }

        if let attribution {
            dict["attribution"] = attribution.toAny()
        }

        if let sandbox {
            dict["sandbox"] = sandbox.toAny()
        }

        if let worktree {
            dict["worktree"] = worktree.toAny()
        }

        if let voiceEnabled {
            dict["voiceEnabled"] = voiceEnabled
        }

        if let prefersReducedMotion {
            dict["prefersReducedMotion"] = prefersReducedMotion
        }

        if let respectGitignore {
            dict["respectGitignore"] = respectGitignore
        }

        if let showThinkingSummaries {
            dict["showThinkingSummaries"] = showThinkingSummaries
        }

        if let includeGitInstructions {
            dict["includeGitInstructions"] = includeGitInstructions
        }

        if let useAutoModeDuringPlan {
            dict["useAutoModeDuringPlan"] = useAutoModeDuringPlan
        }

        if let effortLevel {
            dict["effortLevel"] = effortLevel
        }

        if let autoUpdatesChannel {
            dict["autoUpdatesChannel"] = autoUpdatesChannel
        }

        return try JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        )
    }
}
