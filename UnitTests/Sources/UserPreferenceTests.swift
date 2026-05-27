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

struct UserPreferenceTests {
    @Test
    func storePlistValue() {
        let testDefaults = VolatileUserDefaults()
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.plist == "Hello")
        #expect(testDefaults.object(forKey: TestsKey.key2.rawValue) is String)
        #expect(testDefaults.data(forKey: TestsKey.key2.rawValue) == nil)
    }
    
    @Test
    func storeCodableValue() {
        let testDefaults = VolatileUserDefaults()
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.codable == storedType)
        #expect(testDefaults.data(forKey: TestsKey.key3.rawValue) != nil)
    }
    
    @Test
    func storePlistValueOnVolatileStorage() {
        let testDefaults = VolatileUserDefaults()
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.volatileVar = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.volatileVar == nil)
    }
    
    @Test
    func storeCodableValueOnVolatileStorage() {
        let testDefaults = VolatileUserDefaults()
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.volatileCodable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.volatileCodable == nil)
        #expect(testDefaults.data(forKey: TestsKey.key4.rawValue) == nil)
    }
    
    @Test
    func storePlistArray() {
        let testDefaults = VolatileUserDefaults()
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.plistArray = [1, 2, 3]
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.plistArray == [1, 2, 3])
        #expect(testDefaults.object(forKey: TestsKey.key5.rawValue) as? [Int] == [1, 2, 3])
        #expect(testDefaults.data(forKey: TestsKey.key5.rawValue) == nil)
    }
    
    @Test
    func assignNilToPlistType() {
        let testDefaults = VolatileUserDefaults()
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        value.plist = nil
        
        #expect(value.plist == nil)
        #expect(testDefaults.object(forKey: TestsKey.key2.rawValue) as? String == nil)
    }
    
    @Test
    func assignNilToCodableType() {
        let testDefaults = VolatileUserDefaults()
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        value.codable = nil
        
        #expect(value.codable == nil)
        #expect(testDefaults.data(forKey: TestsKey.key3.rawValue) == nil)
    }
    
    @Test
    func localOverRemoteValue() {
        let storage = VolatileUserDefaults()
        @UserPreference(key: TestsKey.testKey, defaultValue: "", storage: storage) var preference
        #expect(preference == "")
        
        _preference.remoteValue = "remote"
        #expect(preference == "remote")
        
        preference = "local"
        #expect(preference == "local")
    }
    
    @Test
    func remoteOverLocalValue() {
        let storage = VolatileUserDefaults()
        @UserPreference(key: TestsKey.testKey, defaultValue: "", storage: storage, mode: .remoteOverLocal) var preference
        #expect(preference == "")
        
        _preference.remoteValue = "remote"
        #expect(preference == "remote")
        
        preference = "local"
        #expect(preference == "remote")
        #expect(_preference.isLockedToRemote)
    }
}

private struct TestPreferences {
    @UserPreference
    var volatileVar: String?
    
    @UserPreference
    var plist: String?
    
    @UserPreference
    var codable: CodableTestType?
    
    @UserPreference
    var volatileCodable: CodableTestType?
    
    @UserPreference
    var plistArray: [Int]?
    
    init(_ storage: UserDefaultsProtocol) {
        _volatileVar = UserPreference(key: TestsKey.key1, storage: VolatileUserDefaults())
        _plist = UserPreference(key: TestsKey.key2, storage: storage)
        _codable = UserPreference(key: TestsKey.key3, storage: storage)
        _volatileCodable = UserPreference(key: TestsKey.key4, storage: VolatileUserDefaults())
        _plistArray = UserPreference(key: TestsKey.key5, storage: storage)
    }
}

private struct CodableTestType: Equatable, Codable {
    let a: String
    let b: [Int]
}

private struct TestsKey: PreferenceKeyable, RawRepresentable {
    static let testKey = Self(rawValue: "testKey")
    static let key1 = Self(rawValue: "foo.volatile")
    static let key2 = Self(rawValue: "foo.plist")
    static let key3 = Self(rawValue: "foo.codable")
    static let key4 = Self(rawValue: "foo.volatile.codable")
    static let key5 = Self(rawValue: "foo.plist.array")
    
    let rawValue: String
}
