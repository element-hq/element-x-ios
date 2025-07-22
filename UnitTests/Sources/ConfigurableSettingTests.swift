//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

class ConfigurableSettingTests: XCTestCase {
    func testOverrideAndReset() {
        let setting = ConfigurableSetting(0)
        XCTAssertEqual(setting.publisher.value, 0)
        
        setting.override(1)
        XCTAssertEqual(setting.publisher.value, 1)
        
        setting.override(2)
        XCTAssertEqual(setting.publisher.value, 2)
        
        setting.reset()
        XCTAssertEqual(setting.publisher.value, 0)
    }
    
    func testOptionalOverride() {
        let setting: ConfigurableSetting<String?> = .init("Hello")
        XCTAssertEqual(setting.publisher.value, "Hello")
        
        setting.override("World")
        XCTAssertEqual(setting.publisher.value, "World")
        
        setting.override(nil)
        XCTAssertEqual(setting.publisher.value, nil)
        
        setting.reset()
        XCTAssertEqual(setting.publisher.value, "Hello")
    }
}
