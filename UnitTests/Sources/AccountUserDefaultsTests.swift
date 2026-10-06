//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct AccountUserDefaultsTests {
    private let store = VolatileUserDefaults()
    private let aliceDefaults: AccountUserDefaults
    private let bobDefaults: AccountUserDefaults
    
    init() {
        aliceDefaults = AccountUserDefaults(userID: "@alice:example.com", store: store)
        bobDefaults = AccountUserDefaults(userID: "@bob:example.com", store: store)
    }
    
    @Test
    func dictionaryRepresentation() {
        // Given a store containing values for Alice, Bob and the app, all sharing a key.
        aliceDefaults.set("one", forKey: "first")
        aliceDefaults.set(2, forKey: "second")
        bobDefaults.set("bob", forKey: "first")
        store.set("global", forKey: "first")
        #expect(aliceDefaults.object(forKey: "first") as? String == "one")
        #expect(aliceDefaults.object(forKey: "second") as? Int == 2)
        #expect(bobDefaults.object(forKey: "first") as? String == "bob")
        #expect(store.object(forKey: "first") as? String == "global")
        
        // When getting the dictionary representation of Alice's defaults.
        let representation = aliceDefaults.dictionaryRepresentation()
        
        // Then it should only contain Alice's values.
        #expect(representation.count == 2)
        #expect(representation["first"] as? String == "one")
        #expect(representation["second"] as? Int == 2)
    }
    
    @Test
    func reset() {
        // Given a store containing values for Alice, Bob and the app, all sharing a key.
        aliceDefaults.set("one", forKey: "first")
        aliceDefaults.set(2, forKey: "second")
        bobDefaults.set("bob", forKey: "first")
        store.set("global", forKey: "first")
        #expect(aliceDefaults.object(forKey: "first") as? String == "one")
        #expect(aliceDefaults.object(forKey: "second") as? Int == 2)
        #expect(bobDefaults.object(forKey: "first") as? String == "bob")
        #expect(store.object(forKey: "first") as? String == "global")
        
        // When resetting Alice's defaults.
        aliceDefaults.reset()
        
        // Then only Alice's values should be removed.
        #expect(aliceDefaults.object(forKey: "first") == nil)
        #expect(aliceDefaults.object(forKey: "second") == nil)
        #expect(bobDefaults.object(forKey: "first") as? String == "bob")
        #expect(store.object(forKey: "first") as? String == "global")
    }
    
    @Test
    func migrateAppSettingsValue() {
        // Given a store containing an app value.
        store.set("global", forKey: "first")
        #expect(store.object(forKey: "first") as? String == "global")
        #expect(aliceDefaults.object(forKey: "first") == nil)
        #expect(bobDefaults.object(forKey: "first") == nil)
        
        // When migrating that value into Alice's defaults.
        aliceDefaults.migrateAppSettingsValue(forKey: "first")
        
        // Then the value should be moved to Alice's defaults only.
        #expect(aliceDefaults.object(forKey: "first") as? String == "global")
        #expect(store.object(forKey: "first") == nil)
        #expect(bobDefaults.object(forKey: "first") == nil)
    }
    
    @Test
    func migrateUnsetAppSettingsValue() {
        // Given an empty store.
        #expect(store.storage.isEmpty)
        
        // When migrating a value that isn't set into Alice's defaults.
        aliceDefaults.migrateAppSettingsValue(forKey: "first")
        
        // Then nothing should be written to the store.
        #expect(aliceDefaults.object(forKey: "first") == nil)
        #expect(store.storage.isEmpty)
    }
}
