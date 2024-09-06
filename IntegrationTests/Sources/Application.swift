//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

enum Application {
    @discardableResult static func launch() -> XCUIApplication {
        let app = XCUIApplication()
        
        let launchEnvironment = [
            "IS_RUNNING_INTEGRATION_TESTS": "1"
        ]
        
        app.launchEnvironment = launchEnvironment
        app.launch()
        
        return app
    }
}

extension XCUIApplication {
    var homeserver: String {
        guard let homeserver = ProcessInfo.processInfo.environment["INTEGRATION_TESTS_HOST"],
              homeserver.count > 0 else {
            return "default"
        }
        
        return homeserver
    }
    
    var username: String {
        guard let username = ProcessInfo.processInfo.environment["INTEGRATION_TESTS_USERNAME"],
              username.count > 0 else {
            return "default"
        }
        
        return username
    }
    
    var password: String {
        guard let password = ProcessInfo.processInfo.environment["INTEGRATION_TESTS_PASSWORD"],
              password.count > 0 else {
            return "default"
        }
        
        return password
    }
}
