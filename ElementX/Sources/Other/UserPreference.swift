//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

/// A property wrapper that allows storing data in a keyed storage while also exposing a Combine publisher
/// to listen for value changes. The publisher does not skip consecutive duplicates, as there is no
/// `Equatable` enforcement at this level.
///
/// - Note: This wrapper allows enforcing a default value through the `forceDefault` closure.
@propertyWrapper
final class UserPreference<T: Codable> {
    private let key: String
    private var keyedStorage: any KeyedStorage<T>
    private let defaultValue: () -> T
    private let subject: PassthroughSubject<T, Never> = .init()
    private var cancellable: AnyCancellable?
    
    /// A publisher that determines whether the default value is always being enforced.
    let forceDefault: CurrentValuePublisher<Bool, Never>
    
    /// Initializes the property wrapper.
    ///
    /// - Parameters:
    ///   - key: The key used to store and retrieve the value.
    ///   - defaultValue: The default value to use if no stored value exists or if `forceDefault` is `true`.
    ///   - keyedStorage: The storage instance where the value is saved.
    ///   - forceDefault: A publisher that determines whether the default value should always be used. Defaults to  publish`false`. Useful in the context of MDM settings.
    init(key: String,
         defaultValue: @autoclosure @escaping () -> T,
         keyedStorage: any KeyedStorage<T>,
         forceDefault: CurrentValuePublisher<Bool, Never> = .init(.init(false))) {
        self.key = key
        self.defaultValue = defaultValue
        self.keyedStorage = keyedStorage
        self.forceDefault = forceDefault
        
        cancellable = forceDefault
            .sink { [weak self] value in
                guard value else {
                    return
                }
                // If we are now forcing the default value, we need to update the subject with the default value.
                self?.subject.send(defaultValue())
            }
    }
    
    var wrappedValue: T {
        get {
            guard !forceDefault.value else {
                return defaultValue()
            }
            return keyedStorage[key] ?? defaultValue()
        }
        set {
            guard !forceDefault.value else {
                return
            }
            keyedStorage[key] = newValue
            subject.send(wrappedValue)
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
        case userDefaults(UserDefaults = .standard)
        case volatile
    }
    
    convenience init(key: String, defaultValue: T, storageType: StorageType) {
        let storage: any KeyedStorage<T>
        
        switch storageType {
        case .userDefaults(let userDefaults):
            storage = UserDefaultsStorage(userDefaults: userDefaults)
        case .volatile:
            storage = [String: T]()
        }
        
        self.init(key: key, defaultValue: defaultValue, keyedStorage: storage)
    }
    
    convenience init<R: RawRepresentable>(key: R, defaultValue: T, storageType: StorageType) where R.RawValue == String {
        self.init(key: key.rawValue, defaultValue: defaultValue, storageType: storageType)
    }
    
    convenience init(key: String, storageType: StorageType) where T: ExpressibleByNilLiteral {
        self.init(key: key, defaultValue: nil, storageType: storageType)
    }
    
    convenience init<R: RawRepresentable>(key: R, storageType: StorageType) where R: RawRepresentable, R.RawValue == String, T: ExpressibleByNilLiteral {
        self.init(key: key.rawValue, storageType: storageType)
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
