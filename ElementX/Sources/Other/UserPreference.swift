//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation

/// Property wrapper that allows to store data into a keyed storage.
/// It also exposes a Combine publisher for listening to value changes.
/// The publisher isn't supposed to skip consecutive duplicates if any,
/// there is no concept of Equatable at this level.
@propertyWrapper
final class UserPreference<T: Codable> {
    private let key: String
    private var keyedStorage: any KeyedStorage<T>
    private let defaultValue: T
    private let subject: PassthroughSubject<T, Never> = .init()
    
    init(key: String, defaultValue: T, keyedStorage: any KeyedStorage<T>) {
        self.key = key
        self.defaultValue = defaultValue
        self.keyedStorage = keyedStorage
    }
    
    var wrappedValue: T {
        get {
            keyedStorage[key] ?? defaultValue
        }
        set {
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

    /// Convenience initializer that also immediatelly stores the provided initialValue.
    /// The initial value is stored every time the app is launched.
    /// And will override any existing values.
    ///
    /// - Parameters:
    ///   - key: the raw representable key used to store the value, needs conform also to String
    ///   - initialValue: the initial value that will be stored when the app is launched, the initialValue is also used as defaultValue
    ///   - storageType: the storage type where the wrappedValue will be stored.
    convenience init<R: RawRepresentable>(key: R, initialValue: T, storageType: StorageType) where R.RawValue == String {
        self.init(key: key, defaultValue: initialValue, storageType: storageType)
        wrappedValue = initialValue
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
