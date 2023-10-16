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
    private var app: XCUIApplication!
    
    override func setUp() {
        app = Application.launch()
        app.login(currentTestCase: self)
    }
    
    func testUserFlow() {
        checkSettings()
        
        checkInvites()
        
        checkRoomCreation()
        
        // Open the first room in the list.
        let firstRoom = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", A11yIdentifiers.homeScreen.roomNamePrefix)).firstMatch
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 10.0))
        firstRoom.tap()
        
        checkAttachmentsPicker()
        
        checkTimelineItemActionMenu()
        
        checkRoomDetails()
        
        app.logout()
    }
    
    private func checkInvites() {
        // Open invites
        let invitesButton = app.buttons[A11yIdentifiers.homeScreen.invites]
        XCTAssertTrue(invitesButton.waitForExistence(timeout: 10.0))
        invitesButton.tap()
        
        // Go back to the room list
        tapOnBackButton("All Chats")
    }
    
    private func checkAttachmentsPicker() {
        for identifier in [A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary,
                           A11yIdentifiers.roomScreen.attachmentPickerDocuments,
                           A11yIdentifiers.roomScreen.attachmentPickerLocation] {
            tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
            tapOnButton(identifier)
            tapOnButton("Cancel")
        }
                
        // Open attachments picker
        tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)

        // Open photo library picker
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
        
        // Tap on the second image. First one is always broken on simulators.
        app.scrollViews.images.element(boundBy: 1).tap()
        
        // Cancel the upload flow
        tapOnButton("Cancel")
    }
    
    private func checkRoomCreation() {
        tapOnButton(A11yIdentifiers.homeScreen.startChat)
        
        tapOnButton(A11yIdentifiers.startChatScreen.createRoom)
        
        tapOnButton(A11yIdentifiers.inviteUsersScreen.proceed)
        
        tapOnBackButton("Invite people")
        
        tapOnBackButton("Start chat")
        
        tapOnButton("Cancel")
        
        sleep(1)
    }
    
    private func checkTimelineItemActionMenu() {
        // Long press on the last message
        let lastMessage = app.cells.firstMatch
        XCTAssertTrue(lastMessage.waitForExistence(timeout: 10.0))
        lastMessage.press(forDuration: 2.0)
        
        // Hide the bottom sheet
        let timelineItemActionMenu = app.scrollViews[A11yIdentifiers.roomScreen.timelineItemActionMenu].firstMatch
        XCTAssertTrue(timelineItemActionMenu.waitForExistence(timeout: 10.0))
        timelineItemActionMenu.swipeDown(velocity: .fast)
    }
    
    private func checkRoomDetails() {
        // Open the room details
        let roomHeader = app.staticTexts[A11yIdentifiers.roomScreen.name]
        XCTAssertTrue(roomHeader.waitForExistence(timeout: 10.0))
        roomHeader.tap()
        
        // Open the room member details
        tapOnButton(A11yIdentifiers.roomDetailsScreen.people)
        
        // Open the first member's details
        let firstRoomMember = app.scrollViews.buttons.firstMatch
        XCTAssertTrue(firstRoomMember.waitForExistence(timeout: 10.0))
        firstRoomMember.tap()
        
        // Go back to the room member details
        tapOnBackButton("People")
        
        // Go back to the room details
        tapOnBackButton()
        
        // Go back to the room
        tapOnBackButton()
        
        // Go back to the room list
        tapOnBackButton("All Chats")
    }
    
    private func checkSettings() {
        let profileButton = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        profileButton.forceTap()
        
        // Open the settings
        tapOnButton(A11yIdentifiers.homeScreen.settings)
        
        // Open analytics
        tapOnButton(A11yIdentifiers.settingsScreen.analytics)
        
        // Go back to settings
        tapOnBackButton("Settings")
        
        // Open report a bug
        tapOnButton(A11yIdentifiers.settingsScreen.reportBug)
        
        // Go back to settings
        tapOnBackButton("Settings")
        
        // Open about
        tapOnButton(A11yIdentifiers.settingsScreen.about)
        
        // Go back to settings
        tapOnBackButton("Settings")
        
        // Close the settings
        tapOnButton(A11yIdentifiers.settingsScreen.done)
    }
    
    private func tapOnButton(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tap()
    }
    
    /// Taps on a back button that the system configured with a label but no identifier.
    ///
    /// When there are multiple buttons with the same label in the hierarchy, all the buttons we created
    /// should have an identifier set, and so this method will ignore those picking the one with only a label.
    private func tapOnBackButton(_ label: String = "Back") {
        let button = app.buttons.matching(NSPredicate(format: "label == %@ && identifier == ''", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tap()
    }
}
