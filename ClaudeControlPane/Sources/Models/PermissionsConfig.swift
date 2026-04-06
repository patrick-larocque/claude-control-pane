import Foundation

struct PermissionsConfig: Codable, Sendable, Equatable {
    var defaultMode: String?
    var allow: [String]
    var deny: [String]
    var ask: [String]

    init(defaultMode: String? = nil, allow: [String] = [], deny: [String] = [], ask: [String] = []) {
        self.defaultMode = defaultMode
        self.allow = allow
        self.deny = deny
        self.ask = ask
    }

    enum CodingKeys: String, CodingKey {
        case defaultMode, allow, deny, ask
    }

    var isDefault: Bool {
        defaultMode == nil && allow.isEmpty && deny.isEmpty && ask.isEmpty
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.defaultMode = try container.decodeIfPresent(String.self, forKey: .defaultMode)
        self.allow = (try? container.decode([String].self, forKey: .allow)) ?? []
        self.deny = (try? container.decode([String].self, forKey: .deny)) ?? []
        self.ask = (try? container.decode([String].self, forKey: .ask)) ?? []
    }
}
