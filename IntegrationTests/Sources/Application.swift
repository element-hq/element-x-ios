//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
