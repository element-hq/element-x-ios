//
//  Application.swift
//  UITests
//
//  Created by Stefan Ceriu on 13/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import XCTest
import SnapshotTesting

struct Application {
    static func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment = ["IS_RUNNING_UI_TESTS": "1"]
        Bundle.elementFallbackLanguage = "en"
        app.launch()
        return app
    }
}

extension XCUIApplication {
    func goToScreenWithIdentifier(_ identifier: UITestScreenIdentifier) {
        let button = buttons[identifier.rawValue]
        let lastLabel = staticTexts["lastItem"]
        
        while !button.isHittable, !lastLabel.isHittable {
            tables.firstMatch.swipeUp()
        }
        
        button.tap()
    }

    /// Assert screenshot for a screen with the given identifier. Does not fail if a screenshot is newly created.
    /// - Parameter identifier: Identifier of the UI test screen
    func assertScreenshot(_ identifier: UITestScreenIdentifier) {
        let failure = verifySnapshot(
            matching: self,
            as: .image,
            named: identifier.rawValue,
            testName: testName)

        if let failure = failure,
           !failure.contains("No reference was found on disk."),
           !failure.contains("to test against the newly-recorded snapshot") {
            XCTFail(failure)
        }
    }

    private var testName: String {
        languageCode + "-" + regionCode + "-" + deviceName
    }

    private var deviceName: String {
        UIDevice.current.name
    }

    private var languageCode: String {
        Locale.current.languageCode ?? ""
    }

    private var regionCode: String {
        Locale.current.regionCode ?? ""
    }
}

extension Snapshotting where Value == XCUIElement, Format == UIImage {
    public static let image: Snapshotting =
    Snapshotting<UIImage, UIImage>.image.pullback { element in element.screenshot().image }
}
