//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// A property wrapper that allows storing data in a keyed storage while also exposing a Combine publisher
/// to listen for value changes. The publisher does not skip consecutive duplicates, as there is no
/// `Equatable` enforcement at this level.
@propertyWrapper
final class UserPreference<T: Codable> {
    static var remotePrefix: String {
        "remote-"
    }
    
    enum Mode {
        case localOverRemote
        case remoteOverLocal
    }
    
    private let key: String
    private var remoteKey: String {
        "\(Self.remotePrefix)\(key)"
    }

    private var keyedStorage: any KeyedStorage<T>
    private let defaultValue: T
    private let subject: PassthroughSubject<T, Never> = .init()
    private let mode: Mode
    
    /// This can be used to check if is still possible for the user to change the value or not
    /// Can only be accessed by using `_preferenceName.isLockedToRemote`
    var isLockedToRemote: Bool {
        mode == .remoteOverLocal && remoteValue != nil
    }
    
    /// Initializes the property wrapper with a static default value.
    ///
    /// - Parameters:
    ///   - key: The key used to store and retrieve the value.
    ///   - defaultValue: The default value to use if no stored value exists or if `forceDefault` is `true`.
    ///   - keyedStorage: The storage instance where the value is saved.
    ///   - forceDefault: A publisher that determines whether the default value should always be used. Defaults to publish `false`. Useful in the context of remote settings that need to override the local value.
    init(key: String,
         defaultValue: T,
         keyedStorage: any KeyedStorage<T>,
         mode: Mode) {
        self.key = key
        self.defaultValue = defaultValue
        self.keyedStorage = keyedStorage
        self.mode = mode
    }
    
    /// The wrapped value is supposed to be the one updated by the user so it can only control the local value
    var wrappedValue: T {
        get {
            switch mode {
            case .localOverRemote:
                return keyedStorage[key] ?? keyedStorage[remoteKey] ?? defaultValue
            case .remoteOverLocal:
                return keyedStorage[remoteKey] ?? keyedStorage[key] ?? defaultValue
            }
        }
        set {
            keyedStorage[key] = newValue
            subject.send(wrappedValue)
        }
    }
    
    /// This is supposed to be the value that is set by the remote settings
    /// So it can only be accessed by doing `AppSettings._preferenceName.remoteValue`
    var remoteValue: T? {
        get {
            keyedStorage[remoteKey]
        } set {
            keyedStorage[remoteKey] = newValue
            if mode == .remoteOverLocal || keyedStorage[key] == nil {
                subject.send(wrappedValue)
            }
        }
    }
                
    var projectedValue: AnyPublisher<T, Never> {
        subject
            .prepend(wrappedValue)
            .eraseToAnyPublisher()
    }
}

// MARK: - UserPreference convenience initializers

extension UserPreference {
    enum StorageType {
        case userDefaults(UserDefaults)
        case volatile
    }
    
    convenience init(key: String, defaultValue: T, storageType: StorageType, mode: Mode = .localOverRemote) {
        let storage: any KeyedStorage<T>
        
        switch storageType {
        case .userDefaults(let userDefaults):
            storage = UserDefaultsStorage(userDefaults: userDefaults)
        case .volatile:
            storage = [String: T]()
        }
        
        self.init(key: key, defaultValue: defaultValue, keyedStorage: storage, mode: mode)
    }
    
    convenience init<R: RawRepresentable>(key: R, defaultValue: T, storageType: StorageType, mode: Mode = .localOverRemote) where R.RawValue == String {
        self.init(key: key.rawValue, defaultValue: defaultValue, storageType: storageType, mode: mode)
    }
    
    convenience init(key: String, storageType: StorageType, mode: Mode = .localOverRemote) where T: ExpressibleByNilLiteral {
        self.init(key: key, defaultValue: nil, storageType: storageType, mode: mode)
    }
    
    convenience init<R: RawRepresentable>(key: R, storageType: StorageType, mode: Mode = .localOverRemote) where R: RawRepresentable, R.RawValue == String, T: ExpressibleByNilLiteral {
        self.init(key: key.rawValue, storageType: storageType, mode: mode)
    }
}

// MARK: - Storage

protocol KeyedStorage<Value> {
    associatedtype Value: Codable
    
    subscript(key: String) -> Value? { get set }
}

/// An implementation of KeyedStorage on the UserDefaults.
///
/// When used with a `Value` that conforms to `PlistRepresentable` the Codable encode/decode
/// phase is skipped, and values are stored natively in the plist.
final class UserDefaultsStorage<Value: Codable>: KeyedStorage {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults) {
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
        set {
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
            userDefaults.setValue(encodedValue, forKey: key)
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

private protocol Nullable {
    var isNil: Bool { get }
}

extension Optional: Nullable {
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

extension Dictionary: KeyedStorage where Key == String, Value: Codable { }

// MARK: - PlistRepresentable

/// A protocol to mark types as being plist compliant.
/// UserDefaultsStorage uses this protocol to avoid to encode/decode with Codable plist compliant values.
protocol PlistRepresentable { }

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
