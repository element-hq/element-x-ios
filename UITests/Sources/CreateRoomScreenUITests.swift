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
class CreateRoomScreenUITests: XCTestCase {
    func testLanding() async throws {
        let app = Application.launch(.createRoom)
        try await app.assertScreenshot(.createRoom)
    }

    func testLandingWithoutUsers() async throws {
        let app = Application.launch(.createRoomNoUsers)
        try await app.assertScreenshot(.createRoomNoUsers)
    }
    
    func testLongInputNameText() async throws {
        let app = Application.launch(.createRoom)
        
        // typeText sometimes misses letters but it's faster than typing one letter at a time
        // repeat the same letter enough times to avoid that but also to work on iPads
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].tap()
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].typeText(.init(repeating: "x", count: 200))
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].typeText("\n")
        try await app.assertScreenshot(.createRoom, step: 1)
    }
    
    // Disabled because tapping on the textView doesn't work
    func disabled_testLongInputTopicText() async throws {
        let app = Application.launch(.createRoom)
        let textView = app.textViews[A11yIdentifiers.createRoomScreen.roomTopic]
        textView.tap()
        textView.typeText(.init(repeating: "Topic\n", count: 3))
        try await app.assertScreenshot(.createRoom, step: 2)
    }
}
