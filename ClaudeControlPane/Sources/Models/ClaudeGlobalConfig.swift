import Foundation

struct ClaudeGlobalConfig: Sendable, Equatable {
    var autoConnectIde: Bool?
    var autoInstallIdeExtension: Bool?
    var editorMode: String?
    var showTurnDuration: Bool?
    var terminalProgressBarEnabled: Bool?
    var teammateMode: String?
    var extraFields: [String: AnyCodableValue]
    var presentKeys: Set<String>

    init(
        autoConnectIde: Bool? = nil,
        autoInstallIdeExtension: Bool? = nil,
        editorMode: String? = nil,
        showTurnDuration: Bool? = nil,
        terminalProgressBarEnabled: Bool? = nil,
        teammateMode: String? = nil,
        extraFields: [String: AnyCodableValue] = [:],
        presentKeys: Set<String> = []
    ) {
        self.autoConnectIde = autoConnectIde
        self.autoInstallIdeExtension = autoInstallIdeExtension
        self.editorMode = editorMode
        self.showTurnDuration = showTurnDuration
        self.terminalProgressBarEnabled = terminalProgressBarEnabled
        self.teammateMode = teammateMode
        self.extraFields = extraFields
        self.presentKeys = presentKeys
    }
}

extension ClaudeGlobalConfig {
    private static func stringValue(_ raw: Any?) -> String? {
        raw as? String
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

    static func decode(from data: Data) throws -> ClaudeGlobalConfig {
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] ?? [:]
        let knownKeys: Set<String> = [
            "autoConnectIde",
            "autoInstallIdeExtension",
            "editorMode",
            "showTurnDuration",
            "terminalProgressBarEnabled",
            "teammateMode"
        ]

        var extraFields: [String: AnyCodableValue] = [:]
        for (key, value) in json where !knownKeys.contains(key) {
            extraFields[key] = AnyCodableValue.from(value)
        }

        return ClaudeGlobalConfig(
            autoConnectIde: boolValue(json["autoConnectIde"]),
            autoInstallIdeExtension: boolValue(json["autoInstallIdeExtension"]),
            editorMode: stringValue(json["editorMode"]),
            showTurnDuration: boolValue(json["showTurnDuration"]),
            terminalProgressBarEnabled: boolValue(json["terminalProgressBarEnabled"]),
            teammateMode: stringValue(json["teammateMode"]),
            extraFields: extraFields,
            presentKeys: Set(json.keys)
        )
    }

    func encode() throws -> Data {
        var dict: [String: Any] = extraFields.mapValues { $0.toAny() }

        if let autoConnectIde {
            dict["autoConnectIde"] = autoConnectIde
        }
        if let autoInstallIdeExtension {
            dict["autoInstallIdeExtension"] = autoInstallIdeExtension
        }
        if let editorMode {
            dict["editorMode"] = editorMode
        }
        if let showTurnDuration {
            dict["showTurnDuration"] = showTurnDuration
        }
        if let terminalProgressBarEnabled {
            dict["terminalProgressBarEnabled"] = terminalProgressBarEnabled
        }
        if let teammateMode {
            dict["teammateMode"] = teammateMode
        }

        return try JSONSerialization.data(
            withJSONObject: dict,
            options: [.prettyPrinted, .sortedKeys]
        )
    }

    func localMcpServers(for projectPath: String) -> AnyCodableValue? {
        guard let projects = extraFields["projects"]?.dictionaryValue,
              let projectEntry = projects[projectPath]?.dictionaryValue else {
            return nil
        }
        return projectEntry["mcpServers"]
    }

    mutating func setLocalMcpServers(_ value: AnyCodableValue?, for projectPath: String) {
        var projects = extraFields["projects"]?.dictionaryValue ?? [:]
        var projectEntry = projects[projectPath]?.dictionaryValue ?? [:]
        if let value {
            projectEntry["mcpServers"] = value
        } else {
            projectEntry.removeValue(forKey: "mcpServers")
        }
        projects[projectPath] = .dictionary(projectEntry)
        extraFields["projects"] = .dictionary(projects)
    }
}
