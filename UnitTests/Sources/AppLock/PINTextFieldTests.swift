//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
struct PINTextFieldTests {
    @Test
    func sanitize() {
        let textField = PINTextField(pinCode: .constant(""))
        #expect(textField.sanitize("2") == "2")
        #expect(textField.sanitize("2023") == "2023")
        #expect(textField.sanitize("20233") == "2023")
        #expect(textField.sanitize("20x") == "20")
        #expect(textField.sanitize("20!") == "20")
        #expect(textField.sanitize("boop") == "")
    }
}
