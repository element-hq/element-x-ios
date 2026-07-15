//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated protocol UserDefaultsProtocol: AnyObject {
    func data(forKey key: String) -> Data?
    func object(forKey key: String) -> Any?
    func removeObject(forKey key: String)
    func set(_ value: Any?, forKey key: String)
    
    func reset()
}

// MARK: - Codable handling

nonisolated extension UserDefaultsProtocol {
    /// Reads and writes a `Codable` value stored under `key`, used by the `@UserPreference` macro.
    ///
    /// When `Value` conforms to `PlistRepresentable` the Codable encode/decode phase is skipped and
    /// the value is stored natively in the plist.
    subscript<Value: Codable>(key: String) -> Value? {
        get {
            if Value.self is PlistRepresentable.Type {
                object(forKey: key) as? Value
            } else {
                data(forKey: key).flatMap { try? JSONDecoder().decode(Value.self, from: $0) }
            }
        }
        set {
            // Detects correctly double optionals like this: String?? = .some(nil)
            if newValue.isNil {
                removeObject(forKey: key)
            } else if Value.self is PlistRepresentable.Type {
                set(newValue, forKey: key)
            } else {
                set(try? JSONEncoder().encode(newValue), forKey: key)
            }
        }
    }
}

private nonisolated protocol Nullable {
    var isNil: Bool { get }
}

nonisolated extension Optional: Nullable {
    var isNil: Bool {
        switch self {
        case .none:
            return true
        case .some(let nullable as Nullable):
            return nullable.isNil
        case .some:
            return false
        }
    }
}

// MARK: - PlistRepresentable

/// A protocol to mark types as being plist compliant.
/// The `UserDefaultsProtocol` storage subscript uses this to avoid encoding/decoding plist compliant values with Codable.
nonisolated protocol PlistRepresentable { }

extension Bool: PlistRepresentable { }
extension String: PlistRepresentable { }
extension Int: PlistRepresentable { }
extension Float: PlistRepresentable { }
extension Double: PlistRepresentable { }
extension Date: PlistRepresentable { }
extension Data: PlistRepresentable { }

extension Array: PlistRepresentable where Element: PlistRepresentable { }
extension Dictionary: PlistRepresentable where Key == String, Value: PlistRepresentable { }
extension Optional: PlistRepresentable where Wrapped: PlistRepresentable { }
