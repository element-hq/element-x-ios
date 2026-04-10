//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import XCTest

extension XCUIElement {
    func clearAndTypeText(_ text: String, app: XCUIApplication) {
        // Read the current value before tap() while the element is in its stable (unfocused) state.
        // After tap(), iOS 26.3 changes the search field's accessibility label from its placeholder
        // to an empty string, which causes XCUITest's snapshot-based element re-find to fail.
        let currentValue = (value as? String) ?? ""
        tap()
        
        app.showKeyboardIfNeeded()
        
        // Use app.typeText instead of self.typeText to avoid any post-tap element re-lookup.
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        app.typeText(deleteString)
        
        // Note: In the past, we had to type chars one by one to avoid CI flakiness
        app.typeText(text)
    }
    
    func tap(_ point: UnitPoint) {
        let coordinate = coordinate(withNormalizedOffset: .init(dx: point.x, dy: point.y))
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
