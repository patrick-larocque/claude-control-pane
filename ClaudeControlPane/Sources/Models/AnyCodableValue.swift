import Foundation

enum AnyCodableValue: Sendable, Equatable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([AnyCodableValue])
    case dictionary([String: AnyCodableValue])
    case null

    static func from(_ any: Any) -> AnyCodableValue {
        // NSNumber must be checked first — JSONSerialization returns NSNumber for all
        // numeric types including booleans, so type-cast order matters.
        if let n = any as? NSNumber {
            if n === kCFBooleanTrue as NSNumber || n === kCFBooleanFalse as NSNumber {
                return .bool(n.boolValue)
            } else if n.doubleValue == Double(n.intValue) {
                return .int(n.intValue)
            } else {
                return .double(n.doubleValue)
            }
        }
        if let s = any as? String { return .string(s) }
        if let b = any as? Bool { return .bool(b) }
        if let i = any as? Int { return .int(i) }
        if let d = any as? Double { return .double(d) }
        if let arr = any as? [Any] { return .array(arr.map { AnyCodableValue.from($0) }) }
        if let dict = any as? [String: Any] { return .dictionary(dict.mapValues { AnyCodableValue.from($0) }) }
        return .null
    }

    func toAny() -> Any {
        switch self {
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .array(let arr): return arr.map { $0.toAny() }
        case .dictionary(let dict): return dict.mapValues { $0.toAny() }
        case .null: return NSNull()
        }
    }
}

extension AnyCodableValue: Codable {
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let i = try? container.decode(Int.self) {
            self = .int(i)
        } else if let d = try? container.decode(Double.self) {
            self = .double(d)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([AnyCodableValue].self) {
            self = .array(arr)
        } else if let dict = try? container.decode([String: AnyCodableValue].self) {
            self = .dictionary(dict)
        } else {
            self = .null
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let s): try container.encode(s)
        case .int(let i): try container.encode(i)
        case .double(let d): try container.encode(d)
        case .bool(let b): try container.encode(b)
        case .array(let arr): try container.encode(arr)
        case .dictionary(let dict): try container.encode(dict)
        case .null: try container.encodeNil()
        }
    }
}
