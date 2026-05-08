//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

public final class UserDefaultsMock: UserDefaultsProtocol, Sendable {
    private let lock = NSLock()
	
    private nonisolated(unsafe) var _storage: [String: Any]
    public private(set) var storage: [String: Any] {
        get { lock.withLock { _storage } }
        set { lock.withLock { _storage = newValue } }
    }
	
    public init(initialValues: [String: Any] = [:]) {
        lock.lock()
        defer { lock.unlock() }
		
        _storage = initialValues
    }
	
    public func data(forKey key: String) -> Data? {
        storage[key] as? Data
    }
	
    public func object(forKey key: String) -> Any? {
        storage[key]
    }
	
    public func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
	
    public func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }
	
    public func removePersistentDomain(forName name: String) {
        storage = [:]
    }
    
    public func string(forKey key: String) -> String? {
        object(forKey: key) as? String
    }
    
    public func array(forKey key: String) -> [Any]? {
        object(forKey: key) as? [Any]
    }
}
