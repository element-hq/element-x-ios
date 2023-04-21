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

@testable import ElementX
import Foundation
import XCTest

final class UserPreferenceTests: XCTestCase {
    override func setUpWithError() throws {
        UserDefaults.testDefaults.removeVolatileDomain(forName: .userDefaultsSuiteName)
    }

    func testStorePlistValue() throws {
        let setPreference = {
            let value = TestPreferences()
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        XCTAssertEqual(value.plist, "Hello")
        XCTAssertNotNil(UserDefaults.testDefaults.string(forKey: .key2), "Hello")
        XCTAssertNil(UserDefaults.testDefaults.data(forKey: .key2), "Hello")
    }
    
    func testStoreCodableValue() throws {
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences()
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        XCTAssertEqual(value.codable, storedType)
        XCTAssertNotNil(UserDefaults.testDefaults.data(forKey: .key3))
    }
    
    func testStorePlistValueOnVolatileStorage() throws {
        let setPreference = {
            let value = TestPreferences()
            value.volatileVar = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        XCTAssertNil(value.volatileVar)
    }
    
    func testStoreCodableValueOnVolatileStorage() throws {
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences()
            value.volatileCodable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        XCTAssertNil(value.volatileCodable)
        XCTAssertNil(UserDefaults.testDefaults.data(forKey: .key4))
    }
    
    func testStorePlistArray() throws {
        let setPreference = {
            let value = TestPreferences()
            value.plistArray = [1, 2, 3]
        }
        
        setPreference()
        
        let value = TestPreferences()
        
        XCTAssertEqual(value.plistArray, [1, 2, 3])
        XCTAssertEqual(UserDefaults.testDefaults.array(forKey: .key5) as? [Int], [1, 2, 3])
        XCTAssertNil(UserDefaults.testDefaults.data(forKey: .key5), "Hello")
    }
    
    func testAssignNilToPlistType() throws {
        let setPreference = {
            let value = TestPreferences()
            value.plist = "Hello"
        }
        
        setPreference()
        
        let value = TestPreferences()
        value.plist = nil
        
        XCTAssertNil(value.plist)
        XCTAssertNil(UserDefaults.testDefaults.string(forKey: .key2))
    }
    
    func testAssignNilToCodableType() throws {
        let storedType = CodableTestType(a: "some", b: [1, 2, 3])
        
        let setPreference = {
            let value = TestPreferences()
            value.codable = storedType
        }
        
        setPreference()
        
        let value = TestPreferences()
        value.codable = nil

        XCTAssertNil(value.codable)
        XCTAssertNil(UserDefaults.testDefaults.data(forKey: .key3))
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
