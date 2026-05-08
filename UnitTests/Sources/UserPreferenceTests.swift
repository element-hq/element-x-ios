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
        let testDefaults = UserDefaultsMock()
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.plist == "Hello")
        #expect(testDefaults.string(forKey: AppSettings.UserDefaultsKeys.key2.rawValue) != nil)
        #expect(testDefaults.data(forKey: AppSettings.UserDefaultsKeys.key2.rawValue) == nil)
    }
    
    @Test
    func storeCodableValue() {
        let testDefaults = UserDefaultsMock()
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.codable == storedType)
        #expect(testDefaults.data(forKey: AppSettings.UserDefaultsKeys.key3.rawValue) != nil)
    }
    
    @Test
    func storePlistValueOnVolatileStorage() {
        let testDefaults = UserDefaultsMock()
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
        let testDefaults = UserDefaultsMock()
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.volatileCodable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.volatileCodable == nil)
        #expect(testDefaults.data(forKey: AppSettings.UserDefaultsKeys.key4.rawValue) == nil)
    }
    
    @Test
    func storePlistArray() {
        let testDefaults = UserDefaultsMock()
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.plistArray = [1, 2, 3]
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        
        #expect(value.plistArray == [1, 2, 3])
        #expect(testDefaults.array(forKey: AppSettings.UserDefaultsKeys.key5.rawValue) as? [Int] == [1, 2, 3])
        #expect(testDefaults.data(forKey: AppSettings.UserDefaultsKeys.key5.rawValue) == nil)
    }
    
    @Test
    func assignNilToPlistType() {
        let testDefaults = UserDefaultsMock()
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        value.plist = nil
        
        #expect(value.plist == nil)
        #expect(testDefaults.string(forKey: AppSettings.UserDefaultsKeys.key2.rawValue) == nil)
    }
    
    @Test
    func assignNilToCodableType() {
        let testDefaults = UserDefaultsMock()
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences(testDefaults)
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences(testDefaults)
        value.codable = nil

        #expect(value.codable == nil)
        #expect(testDefaults.data(forKey: AppSettings.UserDefaultsKeys.key3.rawValue) == nil)
    }
    
    @Test
    func localOverRemoteValue() {
        let storage = UserDefaultsMock()
        @UserPreference(key: .testKey, defaultValue: "", storage: storage) var preference
        #expect(preference == "")
        
        _preference.remoteValue = "remote"
        #expect(preference == "remote")
        
        preference = "local"
        #expect(preference == "local")
    }
    
    @Test
    func remoteOverLocalValue() {
        let storage = UserDefaultsMock()
        @UserPreference(key: .testKey, defaultValue: "", storage: storage, mode: .remoteOverLocal) var preference
        #expect(preference == "")
        
        _preference.remoteValue = "remote"
        #expect(preference == "remote")
        
        preference = "local"
        #expect(preference == "remote")
        #expect(_preference.isLockedToRemote)
    }
}

private struct TestPreferences {
    private let storage = UserDefaultsMock()
    
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
        _volatileVar = UserPreference(key: .key1, storage: storage)
        _plist = UserPreference(key: .key2, storage: storage)
        _codable = UserPreference(key: .key3, storage: storage)
        _volatileCodable = UserPreference(key: .key4, storage: storage)
        _plistArray = UserPreference(key: .key5, storage: storage)
    }
}

private struct CodableTestType: Equatable, Codable {
    let a: String
    let b: [Int]
}


private extension AppSettings.UserDefaultsKeys {
    static let testKey = Self(rawValue: "testKey")
    static let key1 = Self(rawValue: "foo.volatile")
    static let key2 = Self(rawValue: "foo.plist")
    static let key3 = Self(rawValue: "foo.codable")
    static let key4 = Self(rawValue: "foo.volatile.codable")
    static let key5 = Self(rawValue: "foo.plist.array")
}
