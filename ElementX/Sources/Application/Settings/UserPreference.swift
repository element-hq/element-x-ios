//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Storage

/// Typed storage of a `Codable` value in `UserDefaults`, used by the `@UserPreference` macro.
///
/// When used with a `Value` that conforms to `PlistRepresentable` the Codable encode/decode
/// phase is skipped, and values are stored natively in the plist.
nonisolated struct UserDefaultsStorage<Value: Codable> {
    private let userDefaults: UserDefaultsProtocol
    
    init(userDefaults: UserDefaultsProtocol) {
        self.userDefaults = userDefaults
    }
    
    subscript(key: String) -> Value? {
        get {
            let value: Value?
            if Value.self is PlistRepresentable.Type {
                value = decodePlistRepresentableValue(for: key)
            } else {
                value = decodeValue(for: key)
            }
            
            return value
        }
        nonmutating set {
            if Value.self is PlistRepresentable.Type {
                encodePlistRepresentable(value: newValue, for: key)
            } else {
                encode(value: newValue, for: key)
            }
        }
    }
    
    private func decodeValue(for key: String) -> Value? {
        userDefaults
            .data(forKey: key)
            .flatMap {
                try? JSONDecoder().decode(Value.self, from: $0)
            }
    }
    
    private func decodePlistRepresentableValue(for key: String) -> Value? {
        userDefaults.object(forKey: key) as? Value
    }
    
    private func encode(value: Value?, for key: String) {
        // Detects correctly double optionals like this: String?? = .some(nil)
        if value.isNil {
            userDefaults.removeObject(forKey: key)
        } else {
            let encodedValue = try? JSONEncoder().encode(value)
            userDefaults.set(encodedValue, forKey: key)
        }
    }
    
    private func encodePlistRepresentable(value: Value?, for key: String) {
        // Detects correctly double optionals like this: String?? = .some(nil)
        if value.isNil {
            userDefaults.removeObject(forKey: key)
        } else {
            userDefaults.set(value, forKey: key)
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
/// UserDefaultsStorage uses this protocol to avoid to encode/decode with Codable plist compliant values.
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
