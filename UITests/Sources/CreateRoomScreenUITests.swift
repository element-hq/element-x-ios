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

class CreateRoomScreenUITests: XCTestCase {
    func testLanding() {
        let app = Application.launch(.createRoom)
        app.assertScreenshot(.createRoom, step: 0)
    }

    func testLandingWithoutUsers() {
        let app = Application.launch(.createRoomNoUsers)
        app.assertScreenshot(.createRoom, step: 1)
    }
    
    func testLongInputNameText() {
        let app = Application.launch(.createRoom)
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].tap()
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].typeText("xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
        app.assertScreenshot(.createRoom, step: 2)
    }
    
    func testLongInputTopicText() {
        let app = Application.launch(.createRoom)
        let roomTopic = "Room topic\nvery\nvery\nvery long"
        app.textViews[A11yIdentifiers.createRoomScreen.roomTopic].tap()
        app.textViews[A11yIdentifiers.createRoomScreen.roomTopic].typeText(roomTopic)
        app.assertScreenshot(.createRoom, step: 3)
    }
}
