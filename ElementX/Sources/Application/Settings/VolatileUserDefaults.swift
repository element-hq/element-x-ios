//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

final nonisolated class VolatileUserDefaults: UserDefaultsProtocol, Sendable {
    private let lock = NSLock()
    
    private nonisolated(unsafe) var _storage: [String: Any]
    private(set) var storage: [String: Any] {
        get { lock.withLock { _storage } }
        set { lock.withLock { _storage = newValue } }
    }
    
    init(initialValues: [String: Any] = [:]) {
        lock.lock()
        defer { lock.unlock() }
        
        _storage = initialValues
    }
    
    func data(forKey key: String) -> Data? {
        storage[key] as? Data
    }
    
    func object(forKey key: String) -> Any? {
        storage[key]
    }
    
    func removeObject(forKey key: String) {
        storage.removeValue(forKey: key)
    }
    
    func set(_ value: Any?, forKey key: String) {
        storage[key] = value
    }
    
    func reset() {
        storage = [:]
    }
}
