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

import ElementX
import XCTest

@MainActor
class UserSessionScreenTests: XCTestCase {
    func testUserSessionFlows() async throws {
        let roomName = "First room"
        
        let app = Application.launch(.userSessionScreen)

        app.assertScreenshot(.userSessionScreen, step: 1)
        
        app.buttons["roomName:\(roomName)"].tap()
        
        XCTAssert(app.staticTexts[roomName].waitForExistence(timeout: 5.0))
        
        try await Task.sleep(for: .seconds(1))
    
        app.assertScreenshot(.userSessionScreen, step: 2)
    }
}
