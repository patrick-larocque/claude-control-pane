import Foundation

struct Hook: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var type: String
    var command: String

    enum CodingKeys: String, CodingKey {
        case type, command
    }

    init(type: String = "command", command: String = "") {
        self.id = UUID()
        self.type = type
        self.command = command
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.type = (try? container.decode(String.self, forKey: .type)) ?? "command"
        self.command = (try? container.decode(String.self, forKey: .command)) ?? ""
    }
}

struct HookGroup: Codable, Sendable, Equatable, Identifiable {
    var id = UUID()
    var hooks: [Hook]

    enum CodingKeys: String, CodingKey {
        case hooks
    }

    init(hooks: [Hook] = []) {
        self.id = UUID()
        self.hooks = hooks
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = UUID()
        self.hooks = (try? container.decode([Hook].self, forKey: .hooks)) ?? []
    }
}
