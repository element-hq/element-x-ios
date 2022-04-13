//
//  Application.swift
//  UITests
//
//  Created by Stefan Ceriu on 13/04/2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import XCTest

struct Application {
    func launch() {
        let app = XCUIApplication()
        app.launchEnvironment = ["IS_RUNNING_UI_TESTS": "1"]
        app.launch()
    }
}
