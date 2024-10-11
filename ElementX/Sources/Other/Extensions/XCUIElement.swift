//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

extension XCUIElement {
    func clearAndTypeText(_ text: String, app: XCUIApplication) {
        tapCenter()
        
        app.showKeyboardIfNeeded()
        
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
    
    func tapCenter() {
        let coordinate: XCUICoordinate = coordinate(withNormalizedOffset: .init(dx: 0.5, dy: 0.5))
        coordinate.tap()
    }
}

extension XCUIApplication {
    /// Ensures the software keyboard is shown on an iPad when a text field is focussed.
    ///
    /// Note: Whilst this could be added on XCUIElement to more closely tie it to a text field, it requires the
    /// app instance anyway, and some of our tests assert that a default focus has been set on the text field,
    /// so having a method that would set the focus and show the keyboard isn't always desirable.
    func showKeyboardIfNeeded() {
        if UIDevice.current.userInterfaceIdiom == .pad, keyboards.count == 0 {
            buttons["Keyboard"].tap()
            buttons["Show Keyboard"].tap()
        }
    }
}
