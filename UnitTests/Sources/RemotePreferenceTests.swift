//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

class RemotePreferenceTests: XCTestCase {
    func testOverrideAndReset() {
        let preference = RemotePreference(0)
        XCTAssertEqual(preference.publisher.value, 0)
        XCTAssertFalse(preference.isRemotelyConfigured)
        
        preference.applyRemoteValue(1)
        XCTAssertEqual(preference.publisher.value, 1)
        XCTAssertTrue(preference.isRemotelyConfigured)
        
        preference.applyRemoteValue(2)
        XCTAssertEqual(preference.publisher.value, 2)
        XCTAssertTrue(preference.isRemotelyConfigured)
        
        preference.reset()
        XCTAssertEqual(preference.publisher.value, 0)
        XCTAssertFalse(preference.isRemotelyConfigured)
    }
    
    func testOptionalOverride() {
        let preference: RemotePreference<String?> = .init("Hello")
        XCTAssertEqual(preference.publisher.value, "Hello")
        XCTAssertFalse(preference.isRemotelyConfigured)
        
        preference.applyRemoteValue("World")
        XCTAssertEqual(preference.publisher.value, "World")
        XCTAssertTrue(preference.isRemotelyConfigured)
        
        preference.applyRemoteValue(nil)
        XCTAssertEqual(preference.publisher.value, nil)
        XCTAssertTrue(preference.isRemotelyConfigured)
        
        preference.reset()
        XCTAssertEqual(preference.publisher.value, "Hello")
        XCTAssertFalse(preference.isRemotelyConfigured)
    }
}
