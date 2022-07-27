//
//  Application.swift
//  IntegrationTests
//
//  Created by Stefan Ceriu on 26/07/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import XCTest

struct Application {
    @discardableResult static func launch() -> XCUIApplication {
        let app = XCUIApplication()
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
