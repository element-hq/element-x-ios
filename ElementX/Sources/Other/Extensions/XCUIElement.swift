//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        forceTap()
        
        guard let currentValue = value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        typeText(deleteString)
        
        for character in text {
            typeText(String(character))
        }
    }
    
    func forceTap() {
        let coordinate: XCUICoordinate = coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}
