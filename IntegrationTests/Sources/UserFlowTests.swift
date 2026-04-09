//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class UserFlowTests: XCTestCase {
    private static let integrationTestsRoomName = "Element X iOS Integration Tests"
    private static let integrationTestsMessage = "Go down in flames!"
    
    // Held statically so that class func tearDown can call logout() after all tests have run.
    private static var sharedApp: XCUIApplication?
    private var app: XCUIApplication!
    
    override func setUp() async throws {
        continueAfterFailure = false
        // Always relaunch — this terminates the process, wiping all navigation state, while
        // leaving the Matrix session in the keychain so subsequent tests restore to home.
        app = Application.launch()
        Self.sharedApp = app
    }
    
    override class func tearDown() {
        sharedApp?.logout()
        sharedApp = nil
    }
    
    /// Runs first (alphabetically "L" < "R" < "S"). Stores the session to the keychain
    /// so every subsequent setUp() relaunch lands on the home screen automatically.
    func testLogin() throws {
        try app.login(currentTestCase: self)
    }
    
    func testRoomCreation() {
        XCTAssertTrue(app.buttons[A11yIdentifiers.homeScreen.userAvatar].waitForExistence(timeout: 30.0))
        checkRoomCreation()
    }
    
    func testRoomFlows() {
        XCTAssertTrue(app.buttons[A11yIdentifiers.homeScreen.userAvatar].waitForExistence(timeout: 30.0))
        checkRoomFlows()
    }
    
    func testSettings() {
        XCTAssertTrue(app.buttons[A11yIdentifiers.homeScreen.userAvatar].waitForExistence(timeout: 30.0))
        checkSettings()
    }
    
    /// Assumes app is on the home screen
    private func checkRoomFlows() {
        // Search for the special test room
        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10.0))
        searchField.clearAndTypeText(Self.integrationTestsRoomName, app: app)
        
        // And open it
        let firstRoom = app.buttons.matching(NSPredicate(format: "identifier CONTAINS %@", Self.integrationTestsRoomName)).firstMatch
        
        // The backend is sometimes really slow and having a longer timeout
        // beats having to rerun the whole suite again.
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 100.0))
        
        firstRoom.tap(.center)
        
        sendMessages()
        
        checkPhotoSharing()
        
        checkDocumentSharing()
        
        checkLocationSharing()
        
        checkTimelineItemActionMenu()
        
        checkRoomDetails()
        
        // Go back to the room list
        tapOnBackButton("Chats")
        
        // Cancel initial the room search
        let searchCancelButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(searchCancelButton.waitForExistence(timeout: 10.0))
        searchCancelButton.tap(.center)
    }
    
    private func sendMessages() {
        var composerTextField = app.textViews[A11yIdentifiers.roomScreen.messageComposer].firstMatch
        XCTAssertTrue(composerTextField.waitForExistence(timeout: 30.0))
        composerTextField.clearAndTypeText(Self.integrationTestsMessage, app: app)
        
        var sendButton = app.buttons[A11yIdentifiers.roomScreen.sendButton].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0))
        sendButton.tap(.center)
        
        // Wait for the composer to clear, confirming the message was accepted before switching editors.
        expectation(for: NSPredicate(format: "value == ''"), evaluatedWith: composerTextField)
        waitForExpectations(timeout: 30.0)
        
        // Switch to the rich text editor
        tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerTextFormatting)
        
        composerTextField = app.textViews[A11yIdentifiers.roomScreen.messageComposer].firstMatch
        XCTAssertTrue(composerTextField.waitForExistence(timeout: 10.0))
        composerTextField.clearAndTypeText(Self.integrationTestsMessage, app: app)
        
        sendButton = app.buttons[A11yIdentifiers.roomScreen.sendButton].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0))
        sendButton.tap(.center)
        
        // Close the formatting options
        tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions)
    }
        
    private func checkPhotoSharing() {
        tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
        
        // Tap on the second image. First one is always broken on simulators.
        let secondImage = app.scrollViews.images.element(boundBy: 1)
        XCTAssertTrue(secondImage.waitForExistence(timeout: 30.0)) // Photo library takes a bit to load
        secondImage.tap(.center)
        
        // PHPickerViewController dismisses as soon as a photo is selected. Its "Cancel" nav button
        // lingers briefly in the accessibility tree during the dismiss animation with isHittable == false.
        // Tapping at that point causes "Timed out while evaluating UI query". Wait until a hittable
        // Cancel appears, which signals the media upload preview sheet has fully replaced the picker.
        let cancelButton = app.buttons["Cancel"].firstMatch
        expectation(for: NSPredicate(format: "isHittable == true"), evaluatedWith: cancelButton)
        waitForExpectations(timeout: 30.0)
        cancelButton.tap(.center)
        
        // Wait for the upload preview to dismiss before continuing.
        expectation(for: NSPredicate(format: "exists == 0"), evaluatedWith: cancelButton)
        waitForExpectations(timeout: 30.0)
    }
    
    private func checkDocumentSharing() {
        tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
        
        tapOnButton("Cancel", waitForDisappearance: true, timeout: 30.0)
    }
    
    private func checkLocationSharing() {
        tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerLocation)
        
        // Wait for the location screen to appear before handling permission alerts.
        XCTAssertTrue(app.buttons["Close"].firstMatch.waitForExistence(timeout: 30.0))
        
        // The order of the alerts is a bit of a mistery so try twice
        
        allowLocationPermissionOnce()
        
        // Handle map loading errors (missing credentials)
        let alertOkButton = app.alerts.firstMatch.buttons["OK"].firstMatch
        if alertOkButton.waitForExistence(timeout: 10.0) {
            alertOkButton.tap(.center)
        }
        
        allowLocationPermissionOnce()
        
        tapOnButton("Close", waitForDisappearance: true)
    }
    
    private func allowLocationPermissionOnce() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notificationAlertAllowButton = springboard.buttons["Allow Once"].firstMatch
        if notificationAlertAllowButton.waitForExistence(timeout: 20.0) {
            notificationAlertAllowButton.tap(.center)
        }
    }
    
    private func checkRoomCreation() {
        tapOnButton(A11yIdentifiers.homeScreen.startChat)
        
        tapOnButton(A11yIdentifiers.startChatScreen.createRoom)
        
        // Don't create the room, it will make the test account very noisy.
        // The UI tests already test this flow with mocked data.
        
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
        let roomHeader = app.buttons[A11yIdentifiers.roomScreen.name]
        XCTAssertTrue(roomHeader.waitForExistence(timeout: 10.0))
        roomHeader.tap(.center)
        
        // Swipe until the People button is hittable
        let peopleButton = app.buttons[A11yIdentifiers.roomDetailsScreen.people]
        if !peopleButton.isHittable {
            var attempts = 0
            while !peopleButton.isHittable, attempts < 5 {
                app.swipeUp()
                attempts += 1
            }
        }

        // Open the room members list.
        tapOnButton(A11yIdentifiers.roomDetailsScreen.people)
        
        // Open the first member's details. Loading members for big rooms can take a while.
        let firstRoomMember = app.scrollViews.buttons.firstMatch
        XCTAssertTrue(firstRoomMember.waitForExistence(timeout: 120.0))
        firstRoomMember.tap(.center)
        
        // Open the profile from the bottom sheet
        let viewProfileButton = app.buttons[A11yIdentifiers.manageRoomMemberSheet.viewProfile]
        XCTAssertTrue(viewProfileButton.waitForExistence(timeout: 10.0))
        tapOnButton(A11yIdentifiers.manageRoomMemberSheet.viewProfile, waitForDisappearance: true)
        
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
        profileButton.tap(.center)
        
        // Wait for the settings sheet to finish animating in.
        XCTAssertTrue(app.buttons[A11yIdentifiers.settingsScreen.done].waitForExistence(timeout: 30.0))
        
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
    
    private func tapOnButton(_ identifier: String, waitForDisappearance: Bool = false, timeout: TimeInterval = 10.0) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap(.center)
        
        if waitForDisappearance {
            let doesNotExistPredicate = NSPredicate(format: "exists == 0")
            expectation(for: doesNotExistPredicate, evaluatedWith: button)
            waitForExpectations(timeout: timeout)
        }
    }
    
    /// Taps on a back button that the system configured with a label but no identifier.
    ///
    /// When there are multiple buttons with the same label in the hierarchy, all the buttons we created
    /// should have an identifier set, and so this method will ignore those picking the one with only a label.
    private func tapOnBackButton(_ label: String = "Back", timeout: TimeInterval = 10.0) {
        let button = app.buttons.matching(NSPredicate(format: "label == %@ && identifier == 'BackButton'", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        button.tap(.center)
    }
}
