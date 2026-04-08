import Foundation

struct Hook: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var type: String
    var command: String
    var url: String?
    var prompt: String?
    var model: String?
    var ifCondition: String?
    var timeout: Int?
    var isAsync: Bool?
    var shell: String?
    var extraFields: [String: AnyCodableValue]

    init(
        type: String = "command",
        command: String = "",
        url: String? = nil,
        prompt: String? = nil,
        model: String? = nil,
        ifCondition: String? = nil,
        timeout: Int? = nil,
        isAsync: Bool? = nil,
        shell: String? = nil,
        extraFields: [String: AnyCodableValue] = [:]
    ) {
        self.id = UUID()
        self.type = type
        self.command = command
        self.url = url
        self.prompt = prompt
        self.model = model
        self.ifCondition = ifCondition
        self.timeout = timeout
        self.isAsync = isAsync
        self.shell = shell
        self.extraFields = extraFields
    }

    init(from decoder: Decoder) throws {
        let rawValue = try AnyCodableValue(from: decoder)
        let rawDict = rawValue.dictionaryValue ?? [:]
        self.id = UUID()
        self.type = rawDict["type"]?.stringValue ?? "command"
        self.command = rawDict["command"]?.stringValue ?? ""
        self.url = rawDict["url"]?.stringValue
        self.prompt = rawDict["prompt"]?.stringValue
        self.model = rawDict["model"]?.stringValue
        self.ifCondition = rawDict["if"]?.stringValue
        self.timeout = rawDict["timeout"]?.intValue
        self.isAsync = rawDict["async"]?.boolValue
        self.shell = rawDict["shell"]?.stringValue
        var extras = rawDict
        extras.removeValue(forKey: "type")
        extras.removeValue(forKey: "command")
        extras.removeValue(forKey: "url")
        extras.removeValue(forKey: "prompt")
        extras.removeValue(forKey: "model")
        extras.removeValue(forKey: "if")
        extras.removeValue(forKey: "timeout")
        extras.removeValue(forKey: "async")
        extras.removeValue(forKey: "shell")
        self.extraFields = extras
    }

    func encode(to encoder: Encoder) throws {
        var dict = extraFields
        dict["type"] = .string(type)
        switch type {
        case "http":
            if let url {
                dict["url"] = .string(url)
            }
        case "prompt", "agent":
            if let prompt {
                dict["prompt"] = .string(prompt)
            }
        default:
            if !command.isEmpty {
                dict["command"] = .string(command)
            }
        }
        if let model {
            dict["model"] = .string(model)
        }
        if let ifCondition {
            dict["if"] = .string(ifCondition)
        }
        if let timeout {
            dict["timeout"] = .int(timeout)
        }
        if let isAsync {
            dict["async"] = .bool(isAsync)
        }
        if let shell {
            dict["shell"] = .string(shell)
        }
        try AnyCodableValue.dictionary(dict).encode(to: encoder)
    }

    var primaryValue: String {
        switch type {
        case "http":
            return url ?? ""
        case "prompt", "agent":
            return prompt ?? ""
        default:
            return command
        }
    }

    mutating func updatePrimaryValue(_ value: String) {
        switch type {
        case "http":
            url = value
        case "prompt", "agent":
            prompt = value
        default:
            command = value
        }
    }

    mutating func normalizePrimaryPayload(for newType: String) {
        let preservedValue = primaryValue
        type = newType
        command = ""
        url = nil
        prompt = nil
        updatePrimaryValue(preservedValue)
    }

    var primaryLabel: String {
        switch type {
        case "http":
            return "URL"
        case "prompt":
            return "Prompt"
        case "agent":
            return "Agent Prompt"
        default:
            return "Command"
        }
    }
}

struct HookGroup: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var matcher: String?
    var hooks: [Hook]
    var extraFields: [String: AnyCodableValue]

    init(matcher: String? = nil, hooks: [Hook] = [], extraFields: [String: AnyCodableValue] = [:]) {
        self.id = UUID()
        self.matcher = matcher
        self.hooks = hooks
        self.extraFields = extraFields
    }

    init(from decoder: Decoder) throws {
        let rawValue = try AnyCodableValue(from: decoder)
        let rawDict = rawValue.dictionaryValue ?? [:]
        self.id = UUID()
        self.matcher = rawDict["matcher"]?.stringValue
        if let rawHooks = rawDict["hooks"] {
            let hookData = try JSONEncoder().encode(rawHooks)
            self.hooks = (try? JSONDecoder().decode([Hook].self, from: hookData)) ?? []
        } else {
            self.hooks = []
        }
        var extras = rawDict
        extras.removeValue(forKey: "matcher")
        extras.removeValue(forKey: "hooks")
        self.extraFields = extras
    }

    func encode(to encoder: Encoder) throws {
        var dict = extraFields
        if let matcher {
            dict["matcher"] = .string(matcher)
        }
        let hookData = try JSONEncoder().encode(hooks)
        let hookObject = try JSONSerialization.jsonObject(with: hookData)
        dict["hooks"] = AnyCodableValue.from(hookObject)
        try AnyCodableValue.dictionary(dict).encode(to: encoder)
    }
}
