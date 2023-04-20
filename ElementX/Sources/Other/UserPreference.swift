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

// UserPreference sugar syntax
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
}

// MARK: - PlistRepresentable

protocol PlistRepresentable { }

extension Bool: PlistRepresentable { }
extension String: PlistRepresentable { }
extension Int: PlistRepresentable { }
extension Float: PlistRepresentable { }
extension Double: PlistRepresentable { }
extension Data: PlistRepresentable { }

extension Array: PlistRepresentable where Element: PlistRepresentable { }
extension Dictionary: PlistRepresentable where Key == String, Value: PlistRepresentable { }
extension Optional: PlistRepresentable where Wrapped: PlistRepresentable { }

// MARK: - Storage

protocol KeyedStorage<Value> {
    associatedtype Value: Codable
    
    subscript(key: String) -> Value? { get set }
}

final class UserDefaultsStorage<Value: Codable>: KeyedStorage {
    private let userDefaults: UserDefaults
    private var cache: [String: Value] = .init()
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    subscript(key: String) -> Value? {
        get {
            guard cache[key] == nil else {
                return cache[key]
            }
            
            let value: Value?
            if Value.self is PlistRepresentable.Type {
                value = decodePlistRepresentableValue(for: key)
            } else {
                value = decodeValue(for: key)
            }
            
            cache[key] = value
            return value
        }
        set {
            if Value.self is PlistRepresentable.Type {
                encodePlistRepresentable(value: newValue, for: key)
            } else {
                encode(value: newValue, for: key)
            }
            
            cache[key] = nil
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
        let encodedValue = try? JSONEncoder().encode(value)
        userDefaults.setValue(encodedValue, forKey: key)
    }
    
    private func encodePlistRepresentable(value: Value?, for key: String) {
        userDefaults.set(value, forKey: key)
    }
}

extension Dictionary: KeyedStorage where Key == String, Value: Codable { }
