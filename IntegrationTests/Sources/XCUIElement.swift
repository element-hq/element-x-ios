//
//  XCUElement.swift
//  ElementX
//
//  Created by Stefan Ceriu on 27/07/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import XCTest

extension XCUIElement {
    func clearAndTypeText(_ text: String) {
        guard let stringValue = value as? String else {
            XCTFail("Tried to clear and type text into a non string value")
            return
        }

        tap()

        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)

        typeText(deleteString)
        typeText(text)
    }
}
