//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

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
