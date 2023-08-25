//
// Copyright 2023 New Vector Ltd
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

class UserFlowTests: XCTestCase {
    func testUserFlow() {
        let app = Application.launch()
        
        app.login(currentTestCase: self)
        
        // Open the first room in the list.
        let firstRoom = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", A11yIdentifiers.homeScreen.roomNamePrefix)).firstMatch
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 10.0))
        firstRoom.tap()
        
        // Long press on the last message
        let lastMessage = app.cells.firstMatch
        XCTAssertTrue(lastMessage.waitForExistence(timeout: 10.0))
        lastMessage.press(forDuration: 2.0)
        
        // Hide the bottom sheet
        let timelineItemActionMenu = app.otherElements[A11yIdentifiers.roomScreen.timelineItemActionMenu].firstMatch
        XCTAssertTrue(timelineItemActionMenu.waitForExistence(timeout: 10.0))
        timelineItemActionMenu.swipeDown(velocity: .fast)
        
        // Open the room details
        let roomHeader = app.staticTexts["room-name"]
        XCTAssertTrue(roomHeader.waitForExistence(timeout: 10.0))
        roomHeader.tap()
        
        // Open the room member details
        let roomMembers = app.buttons["room_details-people"]
        XCTAssertTrue(roomMembers.waitForExistence(timeout: 10.0))
        roomMembers.tap()
        
        // Open the first member's details
        let firstRoomMember = app.scrollViews.buttons.firstMatch
        XCTAssertTrue(firstRoomMember.waitForExistence(timeout: 10.0))
        firstRoomMember.tap()
        
        // Go back to the room member details
        var backButton = app.buttons["People"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 10.0))
        backButton.tap()
        
        // Go back to the room details
        backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 10.0))
        backButton.tap()
        
        // Go back to the room
        backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 10.0))
        backButton.tap()
        
        // Go back to the room list
        backButton = app.navigationBars.firstMatch.buttons["All Chats"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 10.0))
        backButton.tap()
        
        app.logout()
    }
}
