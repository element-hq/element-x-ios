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
    /// Clears the element's content and types the given text into it.
    ///
    /// Keystrokes are silently dropped when the element hasn't finished taking focus, which corrupts the
    /// value in ways that are hard to spot later on, so the result is verified and retried before failing.
    func clearAndTypeText(_ text: String, app: XCUIApplication) {
        for _ in 0..<3 {
            tap(.center)
            
            app.showKeyboardIfNeeded()
            _ = app.keyboards.firstMatch.waitForExistence(timeout: 10.0)
            
            guard let currentValue = value as? String else {
                XCTFail("Tried to clear and type text into a non string value")
                return
            }
            
            let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
            typeText(deleteString)
            
            // Note: In the past, we had to type chars one by one to avoid CI flakiness
            typeText(text)
            
            // A newline submits the field, which tears it down before its value can be read back.
            if text.contains("\n") || containsTypedText(text) {
                return
            }
        }
        
        XCTFail("Failed to type the expected text, the value is \(value as? String ?? "nil")")
    }
    
    /// Whether the element's value reflects the given text.
    ///
    /// Secure text fields report a bullet per character instead of the text itself, so all that can be compared is the length.
    private func containsTypedText(_ text: String) -> Bool {
        guard let value = value as? String else { return false }
        return elementType == .secureTextField ? value.count == text.count : value == text
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
