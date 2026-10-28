//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Any JSON value, for content the app handles dynamically such as custom event content.
indirect nonisolated enum JSONValue: Hashable, Sendable, Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([JSONValue])
    case object([String: JSONValue])
    
    var stringValue: String? {
        if case .string(let value) = self {
            value
        } else {
            nil
        }
    }
    
    var doubleValue: Double? {
        if case .number(let value) = self {
            value
        } else {
            nil
        }
    }
    
    var boolValue: Bool? {
        if case .bool(let value) = self {
            value
        } else {
            nil
        }
    }
    
    var arrayValue: [JSONValue]? {
        if case .array(let value) = self {
            value
        } else {
            nil
        }
    }
    
    var objectValue: [String: JSONValue]? {
        if case .object(let value) = self {
            value
        } else {
            nil
        }
    }
    
    var isNull: Bool {
        if case .null = self {
            true
        } else {
            false
        }
    }
    
    /// The value serialised as compact JSON, with sorted keys so the output is stable.
    var jsonString: String? {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        guard let data = try? encoder.encode(self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    
    init?(jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let value = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            return nil
        }
        self = value
    }
    
    subscript(key: String) -> JSONValue? {
        objectValue?[key]
    }
    
    // MARK: - Codable
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode(Double.self) {
            self = .number(value)
        } else if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode([JSONValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: JSONValue].self) {
            self = .object(value)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Not a JSON value.")
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .number(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
}

// MARK: - Literals

nonisolated extension JSONValue: ExpressibleByStringLiteral, ExpressibleByIntegerLiteral, ExpressibleByFloatLiteral,
    ExpressibleByBooleanLiteral, ExpressibleByNilLiteral, ExpressibleByArrayLiteral, ExpressibleByDictionaryLiteral {
    init(stringLiteral value: String) {
        self = .string(value)
    }
    
    init(integerLiteral value: Int) {
        self = .number(Double(value))
    }
    
    init(floatLiteral value: Double) {
        self = .number(value)
    }
    
    init(booleanLiteral value: Bool) {
        self = .bool(value)
    }
    
    init(nilLiteral: ()) {
        self = .null
    }
    
    init(arrayLiteral elements: JSONValue...) {
        self = .array(elements)
    }
    
    init(dictionaryLiteral elements: (String, JSONValue)...) {
        self = .object(Dictionary(elements) { _, last in last })
    }
}

// MARK: - JSON Pointer (RFC 6901)

nonisolated enum JSONPointer {
    /// The unescaped reference tokens of a pointer. The empty pointer and `/` both refer to the whole document.
    static func tokens(_ pointer: String) -> [String] {
        if pointer.isEmpty || pointer == "/" {
            return []
        }
        let body = pointer.hasPrefix("/") ? String(pointer.dropFirst()) : pointer
        return body.split(separator: "/", omittingEmptySubsequences: false).map {
            $0.replacingOccurrences(of: "~1", with: "/").replacingOccurrences(of: "~0", with: "~")
        }
    }
    
    /// Joins a scope pointer and a pointer relative to it, e.g. for bindings inside a template item.
    static func join(scope: String?, pointer: String) -> String {
        guard let scope, !scope.isEmpty, scope != "/" else { return pointer }
        if pointer.isEmpty || pointer == "/" {
            return scope
        }
        return scope + (pointer.hasPrefix("/") ? pointer : "/\(pointer)")
    }
}

nonisolated extension JSONValue {
    /// The value at the pointer, or `nil` when any segment is missing.
    func value(at pointer: String) -> JSONValue? {
        var current = self
        for token in JSONPointer.tokens(pointer) {
            switch current {
            case .array(let items):
                guard let index = Int(token), items.indices.contains(index) else { return nil }
                current = items[index]
            case .object(let object):
                guard let child = object[token] else { return nil }
                current = child
            default:
                return nil
            }
        }
        return current
    }
}

nonisolated extension JSONValue? {
    /// A copy with `value` written at the pointer, creating intermediate objects as needed.
    /// Writing `nil` removes the key. Writing to the root pointer replaces the whole document.
    func setting(_ value: JSONValue?, at pointer: String) -> JSONValue? {
        let tokens = JSONPointer.tokens(pointer)
        guard !tokens.isEmpty else { return value }
        return Self.write(value, into: self, tokens: tokens[...])
    }
    
    private static func write(_ value: JSONValue?, into node: JSONValue?, tokens: ArraySlice<String>) -> JSONValue {
        guard let token = tokens.first else { return value ?? .null }
        let remaining = tokens.dropFirst()
        
        if case .array(var items) = node {
            guard let index = token == "-" ? items.count : Int(token), index >= 0, index <= items.count else {
                return .array(items) // An index outside the array can't be written.
            }
            if remaining.isEmpty {
                switch (value, index < items.count) {
                case (let value?, true): items[index] = value
                case (let value?, false): items.append(value)
                case (nil, true): items.remove(at: index)
                case (nil, false): break
                }
            } else {
                let child = write(value, into: index < items.count ? items[index] : nil, tokens: remaining)
                if index < items.count {
                    items[index] = child
                } else {
                    items.append(child)
                }
            }
            return .array(items)
        }
        
        var object = node?.objectValue ?? [:]
        object[token] = remaining.isEmpty ? value : write(value, into: object[token], tokens: remaining)
        return .object(object)
    }
}
