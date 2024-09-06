//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class PINTextFieldTests: XCTestCase {
    func testSanitize() {
        let textField = PINTextField(pinCode: .constant(""))
        XCTAssertEqual(textField.sanitize("2"), "2")
        XCTAssertEqual(textField.sanitize("2023"), "2023")
        XCTAssertEqual(textField.sanitize("20233"), "2023")
        XCTAssertEqual(textField.sanitize("20x"), "20")
        XCTAssertEqual(textField.sanitize("20!"), "20")
        XCTAssertEqual(textField.sanitize("boop"), "")
    }
}
