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

class RoomDetailsScreenUITests: XCTestCase {
    func testInitialStateComponents() {
        let app = Application.launch(.roomDetailsScreen)
        
        XCTAssert(app.staticTexts[A11yIdentifiers.roomDetailsScreen.avatar].exists)
        XCTAssert(app.buttons[A11yIdentifiers.roomDetailsScreen.people].waitForExistence(timeout: 1))
        app.assertScreenshot(.roomDetailsScreen)
    }

    func testInitialStateComponentsWithRoomAvatar() {
        let app = Application.launch(.roomDetailsScreenWithRoomAvatar)

        XCTAssert(app.images[A11yIdentifiers.roomDetailsScreen.avatar].waitForExistence(timeout: 1))
        XCTAssert(app.buttons[A11yIdentifiers.roomDetailsScreen.people].waitForExistence(timeout: 1))
        app.assertScreenshot(.roomDetailsScreenWithRoomAvatar)
    }
}
