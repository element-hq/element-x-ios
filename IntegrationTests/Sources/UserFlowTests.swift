//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

class UserFlowTests: XCTestCase {
    private static let integrationTestsRoomName = "Element X iOS Integration Tests"
    private static let integrationTestsMessage = "Go down in flames!"
    
    private var app: XCUIApplication!
    
    override func setUp() {
        app = Application.launch()
        app.login(currentTestCase: self)
    }
    
    func testUserFlow() {
        checkRoomFlows()
        
        checkSettings()
        
        checkRoomCreation()
        
        app.logout()
    }
    
    // Assumes app is on the home screen
    private func checkRoomFlows() {
        // Search for the special test room
        let searchField = app.searchFields.firstMatch
        searchField.clearAndTypeText(Self.integrationTestsRoomName, app: app)
        
        // And open it
        let firstRoom = app.buttons.matching(NSPredicate(format: "identifier CONTAINS %@", Self.integrationTestsRoomName)).firstMatch
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 10.0))
        firstRoom.tapCenter()
        
        sendMessages()
        
        checkPhotoSharing()
        
        checkDocumentSharing()
        
        checkLocationSharing()
        
        checkTimelineItemActionMenu()
        
        checkRoomDetails()
        
        // Go back to the room list
        tapOnBackButton("Chats")
        
        // Cancel initial the room search
        let searchCancelButton = app.buttons["Cancel"].firstMatch
        XCTAssertTrue(searchCancelButton.waitForExistence(timeout: 10.0))
        searchCancelButton.tapCenter()
    }
    
    private func sendMessages() {
        var composerTextField = app.textViews[A11yIdentifiers.roomScreen.messageComposer].firstMatch
        XCTAssertTrue(composerTextField.waitForExistence(timeout: 10.0))
        composerTextField.clearAndTypeText(Self.integrationTestsMessage, app: app)
        
        var sendButton = app.buttons[A11yIdentifiers.roomScreen.sendButton].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0))
        sendButton.tapCenter()
        
        sleep(10) // Wait for the message to be sent
        
        // Switch to the rich text editor
        tapOnMenu(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerTextFormatting)
        
        composerTextField = app.textViews[A11yIdentifiers.roomScreen.messageComposer].firstMatch
        XCTAssertTrue(composerTextField.waitForExistence(timeout: 10.0))
        composerTextField.clearAndTypeText(Self.integrationTestsMessage, app: app)
        
        sendButton = app.buttons[A11yIdentifiers.roomScreen.sendButton].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0))
        sendButton.tapCenter()
        
        sleep(5) // Wait for the message to be sent
        
        // Close the formatting options
        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions].tapCenter()
    }
        
    private func checkPhotoSharing() {
        tapOnMenu(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
        
        sleep(10) // Wait for the picker to load
        
        // Tap on the second image. First one is always broken on simulators.
        let secondImage = app.scrollViews.images.element(boundBy: 1)
        XCTAssertTrue(secondImage.waitForExistence(timeout: 20.0)) // Photo library takes a bit to load
        secondImage.tapCenter()
        
        // Wait for the image to be processed and the new screen to appear
        sleep(10)
        
        // Cancel the upload flow
        tapOnButton("Cancel", waitForDisappearance: true)
    }
    
    private func checkDocumentSharing() {
        tapOnMenu(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
        
        sleep(10) // Wait for the picker to load
        
        tapOnButton("Cancel", waitForDisappearance: true)
    }
    
    private func checkLocationSharing() {
        tapOnMenu(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerLocation)
        
        sleep(10) // Wait for the picker to load
        
        // The order of the alerts is a bit of a mistery so try twice
        
        allowLocationPermissionOnce()
        
        // Handle map loading errors (missing credentials)
        let alertOkButton = app.alerts.firstMatch.buttons["OK"].firstMatch
        if alertOkButton.waitForExistence(timeout: 10.0) {
            alertOkButton.tapCenter()
        }
        
        allowLocationPermissionOnce()
        
        tapOnButton("Cancel", waitForDisappearance: true)
    }
    
    private func allowLocationPermissionOnce() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notificationAlertAllowButton = springboard.buttons["Allow Once"].firstMatch
        if notificationAlertAllowButton.waitForExistence(timeout: 10.0) {
            notificationAlertAllowButton.tapCenter()
        }
    }
    
    private func checkRoomCreation() {
        tapOnButton(A11yIdentifiers.homeScreen.startChat)
        
        tapOnButton(A11yIdentifiers.startChatScreen.createRoom)
        
        tapOnButton(A11yIdentifiers.inviteUsersScreen.proceed)
        
        tapOnBackButton("Invite people")
        
        tapOnBackButton("Start chat")
        
        tapOnButton("Cancel", waitForDisappearance: true)
    }
    
    private func checkTimelineItemActionMenu() {
        // Long press on the last message
        let lastMessage = app.cells.firstMatch
        XCTAssertTrue(lastMessage.waitForExistence(timeout: 10.0))
        lastMessage.press(forDuration: 2.0)
        
        // Hide the bottom sheet
        let timelineItemActionMenu = app.scrollViews[A11yIdentifiers.roomScreen.timelineItemActionMenu].firstMatch
        
        // Some rooms might not have any messages in it (e.g. message history unavailable)
        if timelineItemActionMenu.waitForExistence(timeout: 10.0) {
            timelineItemActionMenu.swipeDown(velocity: .fast)
        }
    }
    
    private func checkRoomDetails() {
        // Open the room details
        let roomHeader = app.staticTexts[A11yIdentifiers.roomScreen.name]
        XCTAssertTrue(roomHeader.waitForExistence(timeout: 10.0))
        roomHeader.tapCenter()
        
        // Open the room member details
        tapOnButton(A11yIdentifiers.roomDetailsScreen.people)
        
        // Open the first member's details. Loading members for big rooms can take a while.
        let firstRoomMember = app.scrollViews.buttons.firstMatch
        XCTAssertTrue(firstRoomMember.waitForExistence(timeout: 1000.0))
        firstRoomMember.tapCenter()
        
        // Go back to the room member details
        tapOnBackButton("People")
        
        // Go back to the room details
        tapOnBackButton("Room info")
        
        // Go back to the room
        tapOnBackButton("Chat")
    }
    
    private func checkSettings() {
        // On first login when multiple sheets get presented the profile button is not hittable
        // Moving the scroll fixed it for some obscure reason
        app.swipeDown()
        
        let profileButton = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        profileButton.tapCenter()
        
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
    
    private func tapOnButton(_ identifier: String, waitForDisappearance: Bool = false) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tapCenter()
        
        if waitForDisappearance {
            let doesNotExistPredicate = NSPredicate(format: "exists == 0")
            expectation(for: doesNotExistPredicate, evaluatedWith: button)
            waitForExpectations(timeout: 10.0)
        }
    }
    
    private func tapOnMenu(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tapCenter()
    }
    
    /// Taps on a back button that the system configured with a label but no identifier.
    ///
    /// When there are multiple buttons with the same label in the hierarchy, all the buttons we created
    /// should have an identifier set, and so this method will ignore those picking the one with only a label.
    private func tapOnBackButton(_ label: String = "Back") {
        let button = app.buttons.matching(NSPredicate(format: "label == %@ && identifier == ''", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tapCenter()
    }
}
