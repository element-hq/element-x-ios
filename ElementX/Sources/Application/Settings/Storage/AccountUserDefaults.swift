//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A store that scopes all of its values to a single account.
///
/// Each value keeps its own key in the parent store, prefixed with the user ID so that writes
/// remain atomic across the app and its extensions.
final nonisolated class AccountUserDefaults: UserDefaultsProtocol, @unchecked Sendable {
    private let keyPrefix: String
    private let store: UserDefaultsProtocol
    
    init(userID: String, store: UserDefaultsProtocol) {
        keyPrefix = "accountSettings[\(userID)]."
        self.store = store
    }
    
    // MARK: Storage
    
    func data(forKey key: String) -> Data? {
        store.data(forKey: keyPrefix + key)
    }
    
    func object(forKey key: String) -> Any? {
        store.object(forKey: keyPrefix + key)
    }
    
    func removeObject(forKey key: String) {
        store.removeObject(forKey: keyPrefix + key)
    }
    
    func set(_ value: Any?, forKey key: String) {
        store.set(value, forKey: keyPrefix + key)
    }
    
    // MARK: - Management
    
    func migrateAppSettingsValue(forKey key: String) {
        guard let value = store.object(forKey: key) else {
            MXLog.info("Ignoring \(key), not set.")
            return
        }
        
        store.set(value, forKey: keyPrefix + key)
        store.removeObject(forKey: key)
    }
    
    func reset() {
        for key in dictionaryRepresentation().keys {
            removeObject(forKey: key)
        }
    }
    
    func dictionaryRepresentation() -> [String: Any] {
        var representation = [String: Any]()
        for (key, value) in store.dictionaryRepresentation() where key.hasPrefix(keyPrefix) {
            representation[String(key.dropFirst(keyPrefix.count))] = value
        }
        return representation
    }
}
