//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Macros
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
}

private final class TestPreferences {
    let store: UserDefaultsProtocol
    
    init(_ store: UserDefaultsProtocol) {
        self.store = store
    }
    
    @UserPreference(key: TestsKey.key1.rawValue, volatile: true)
    var volatileVar: String?
    
    @UserPreference(key: TestsKey.key2.rawValue)
    var plist: String?
    
    @UserPreference(key: TestsKey.key3.rawValue)
    var codable: CodableTestType?
    
    @UserPreference(key: TestsKey.key4.rawValue, volatile: true)
    var volatileCodable: CodableTestType?
    
    @UserPreference(key: TestsKey.key5.rawValue)
    var plistArray: [Int]?
}

private struct CodableTestType: Equatable, Codable {
    let a: String
    let b: [Int]
}

private enum TestsKey: String {
    case key1 = "foo.volatile"
    case key2 = "foo.plist"
    case key3 = "foo.codable"
    case key4 = "foo.volatile.codable"
    case key5 = "foo.plist.array"
}
