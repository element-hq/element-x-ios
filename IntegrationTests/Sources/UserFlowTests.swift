//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
        checkRoomCreation()
        
        // Open the first room in the list.
        let firstRoom = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", A11yIdentifiers.homeScreen.roomNamePrefix)).firstMatch
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 10.0))
        firstRoom.tap()
        
        checkPhotoSharing()
        
        checkDocumentSharing()
        
        checkLocationSharing()
        
        checkTimelineItemActionMenu()
        
        checkRoomDetails()
        
        app.logout()
    }
        
    private func checkPhotoSharing() {
        // Open attachments picker
        tapOnMenu(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)

        // Open photo library picker
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
        
        // Tap on the second image. First one is always broken on simulators.
        let secondImage = app.scrollViews.images.element(boundBy: 1)
        XCTAssertTrue(secondImage.waitForExistence(timeout: 10.0)) // Photo library takes a bit to load
        secondImage.tap()
        
        // Cancel the upload flow
        tapOnButton("Cancel", waitForDisappearance: true)
    }
    
    private func checkDocumentSharing() {
        tapOnMenu(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
        
        tapOnButton("Cancel", waitForDisappearance: true)
    }
    
    private func checkLocationSharing() {
        tapOnMenu(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerLocation)
        
        // The order of the alerts is a bit of a mistery so try twice
        
        allowLocationPermissionOnce()
        
        // Handle map loading errors (missing credentials)
        let alertOkButton = app.alerts.firstMatch.buttons["OK"].firstMatch
        if alertOkButton.waitForExistence(timeout: 10.0) {
            alertOkButton.tap()
        }
        
        allowLocationPermissionOnce()
        
        tapOnButton("Cancel", waitForDisappearance: true)
    }
    
    private func allowLocationPermissionOnce() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notificationAlertAllowButton = springboard.buttons["Allow Once"].firstMatch
        if notificationAlertAllowButton.waitForExistence(timeout: 10.0) {
            notificationAlertAllowButton.tap()
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
        roomHeader.tap()
        
        // Open the room member details
        tapOnButton(A11yIdentifiers.roomDetailsScreen.people)
        
        // Open the first member's details. Loading members for big rooms can take a while.
        let firstRoomMember = app.scrollViews.buttons.firstMatch
        XCTAssertTrue(firstRoomMember.waitForExistence(timeout: 1000.0))
        firstRoomMember.tap()
        
        // Go back to the room member details
        tapOnBackButton("People")
        
        // Go back to the room details
        tapOnBackButton("Room info")
        
        // Go back to the room
        tapOnBackButton("Chat")
        
        // Go back to the room list
        tapOnBackButton("Chats")
    }
    
    private func checkSettings() {
        // On first login when multiple sheets get presented the profile button is not hittable
        // Moving the scroll fixed it for some obscure reason
        app.swipeDown()
        
        let profileButton = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        profileButton.forceTap()
        
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
        button.tap()
        
        if waitForDisappearance {
            let doesNotExistPredicate = NSPredicate(format: "exists == 0")
            expectation(for: doesNotExistPredicate, evaluatedWith: button)
            waitForExpectations(timeout: 10.0)
        }
    }
    
    private func tapOnMenu(_ identifier: String) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.forceTap()
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
