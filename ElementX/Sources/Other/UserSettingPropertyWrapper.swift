//
// Copyright 2022 New Vector Ltd
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

// Taken from https://www.swiftbysundell.com/articles/property-wrappers-in-swift/

import Combine
import Foundation

/// Property wrapper that allows transparent access to user defaults and exposes
/// a combine publisher for listening to value changes
///
/// Please use `UserSettingRawRepresentable` for storing RawRepresentable values
@propertyWrapper
struct UserSetting<Value: Equatable> {
    private let key: String
    private let defaultValue: Value
    private let storage: UserDefaults
    private let publisher: CurrentValueSubject<Value, Never>
    
    init(key: String, defaultValue: Value, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
        
        let value = storage.value(forKey: key) as? Value ?? defaultValue
        publisher = CurrentValueSubject<Value, Never>(value)
    }
    
    var wrappedValue: Value {
        get {
            let value = storage.value(forKey: key) as? Value
            return value ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
                publisher.send(defaultValue)
            } else {
                storage.setValue(newValue, forKey: key)
                publisher.send(newValue)
            }
        }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        publisher.removeDuplicates(by: { $0 == $1 }).eraseToAnyPublisher()
    }
}

extension UserSetting where Value: ExpressibleByNilLiteral {
    init(key: String, storage: UserDefaults = .standard) {
        self.init(key: key, defaultValue: nil, storage: storage)
    }
}

/// Property wrapper that allows transparent access to user defaults for RawRepresentable types
/// and exposes a combine publisher for listening to value changes
///
/// Tried extending UserSetting with RawRepresentable conformance but in that case the non-restricted
/// method takes precedence. Decided to go with with the simple solution instead of fighting the system
@propertyWrapper
struct UserSettingRawRepresentable<Value: RawRepresentable & Equatable> {
    private let key: String
    private let defaultValue: Value
    private let storage: UserDefaults
    private let publisher: CurrentValueSubject<Value, Never>
    
    init(key: String, defaultValue: Value, storage: UserDefaults = .standard) {
        self.key = key
        self.defaultValue = defaultValue
        self.storage = storage
        
        let value = (storage.value(forKey: key) as? Value.RawValue).flatMap { Value(rawValue: $0) } ?? defaultValue
        publisher = CurrentValueSubject<Value, Never>(value)
    }
    
    var wrappedValue: Value {
        get {
            guard let value = storage.value(forKey: key) as? Value.RawValue else {
                return defaultValue
            }
            
            return Value(rawValue: value) ?? defaultValue
        }
        set {
            if let optional = newValue as? AnyOptional, optional.isNil {
                storage.removeObject(forKey: key)
                publisher.send(newValue)
            } else {
                storage.setValue(newValue.rawValue, forKey: key)
                publisher.send(newValue)
            }
        }
    }
    
    var projectedValue: AnyPublisher<Value, Never> {
        publisher.removeDuplicates(by: { $0 == $1 }).eraseToAnyPublisher()
    }
}

extension UserSettingRawRepresentable where Value: ExpressibleByNilLiteral {
    init(key: String, storage: UserDefaults = .standard) {
        self.init(key: key, defaultValue: nil, storage: storage)
    }
}

// Casting to AnyOptional will fail for any types that are not Optional (below)
private protocol AnyOptional {
    var isNil: Bool { get }
}

extension Optional: AnyOptional {
    var isNil: Bool { self == nil }
}
