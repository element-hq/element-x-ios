//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct UserPreferenceTests {
    init() {
        UserDefaults.testDefaults.removeVolatileDomain(forName: .userDefaultsSuiteName)
        UserDefaults.testDefaults.removePersistentDomain(forName: .userDefaultsSuiteName)
    }

    @Test
    func storePlistValue() {
        let setPreference = {
            let value = TestPreferences()
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        #expect(value.plist == "Hello")
        #expect(UserDefaults.testDefaults.string(forKey: .key2) != nil)
        #expect(UserDefaults.testDefaults.data(forKey: .key2) == nil)
    }
    
    @Test
    func storeCodableValue() {
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences()
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        #expect(value.codable == storedType)
        #expect(UserDefaults.testDefaults.data(forKey: .key3) != nil)
    }
    
    @Test
    func storePlistValueOnVolatileStorage() {
        let setPreference = {
            let value = TestPreferences()
            value.volatileVar = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        #expect(value.volatileVar == nil)
    }
    
    @Test
    func storeCodableValueOnVolatileStorage() {
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences()
            value.volatileCodable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        #expect(value.volatileCodable == nil)
        #expect(UserDefaults.testDefaults.data(forKey: .key4) == nil)
    }
    
    @Test
    func storePlistArray() {
        let setPreference = {
            let value = TestPreferences()
            value.plistArray = [1, 2, 3]
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        #expect(value.plistArray == [1, 2, 3])
        #expect(UserDefaults.testDefaults.array(forKey: .key5) as? [Int] == [1, 2, 3])
        #expect(UserDefaults.testDefaults.data(forKey: .key5) == nil)
    }
    
    @Test
    func assignNilToPlistType() {
        let setPreference = {
            let value = TestPreferences()
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences()
        value.plist = nil
        
        #expect(value.plist == nil)
        #expect(UserDefaults.testDefaults.string(forKey: .key2) == nil)
    }
    
    @Test
    func assignNilToCodableType() {
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences()
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences()
        value.codable = nil

        #expect(value.codable == nil)
        #expect(UserDefaults.testDefaults.data(forKey: .key3) == nil)
    }
    
    @Test
    func localOverRemoteValue() {
        @UserPreference(key: "testKey", defaultValue: "", storageType: .userDefaults(.testDefaults)) var preference
        #expect(preference == "")
        
        _preference.remoteValue = "remote"
        #expect(preference == "remote")
        
        preference = "local"
        #expect(preference == "local")
    }
    
    @Test
    func remoteOverLocalValue() {
        @UserPreference(key: "testKey", defaultValue: "", storageType: .userDefaults(.testDefaults), mode: .remoteOverLocal) var preference
        #expect(preference == "")
        
        _preference.remoteValue = "remote"
        #expect(preference == "remote")
        
        preference = "local"
        #expect(preference == "remote")
        #expect(_preference.isLockedToRemote)
    }
}

private struct TestPreferences {
    @UserPreference(key: .key1, storageType: .volatile)
    var volatileVar: String?
    
    @UserPreference(key: .key2, storageType: .userDefaults(.testDefaults))
    var plist: String?
    
    @UserPreference(key: .key3, storageType: .userDefaults(.testDefaults))
    var codable: CodableTestType?
    
    @UserPreference(key: .key4, storageType: .volatile)
    var volatileCodable: CodableTestType?
    
    @UserPreference(key: .key5, storageType: .userDefaults(.testDefaults))
    var plistArray: [Int]?
}

private struct CodableTestType: Equatable, Codable {
    let a: String
    let b: [Int]
}

private extension String {
    static let key1 = "foo.volatile"
    static let key2 = "foo.plist"
    static let key3 = "foo.codable"
    static let key4 = "foo.volatile.codable"
    static let key5 = "foo.plist.array"
    static let userDefaultsSuiteName = "io.element.elementx.unitests"
}

private extension UserDefaults {
    // swiftlint:disable:next force_unwrapping
    static let testDefaults = UserDefaults(suiteName: .userDefaultsSuiteName)!
}
