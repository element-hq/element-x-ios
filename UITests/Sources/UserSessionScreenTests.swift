//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class UserSessionScreenTests: XCTestCase {
    let firstRoomName = "Foundation 🔭🪐🌌"
    let firstSpaceName = "The Foundation"
    let unjoinedSpaceRoomName = "Company Room"
    let joinedSubspaceName = "Joined Space"
    let joinedSubspaceRoomName = "Management"
    let spaceInviteName = "First space"
    
    enum Step {
        static let homeScreen = 1
        static let roomScreen = 2
        static let composerAttachments = 3
        static let homeScreenWithTabBar = 4
        static let spacesScreen = 5
        static let spaceScreen = 6
        static let subspaceScreen = 7
        static let subspaceRoomScreen = 8
        static let spaceJoinRoomScreen = 9
        static let spaceAddRoomsScreen = 10
        static let spaceMembersListScreen = 11
        static let spaceSettingsScreen = 12
        static let createSpaceRoomScreen = 13
    }
    
    func testUserSessionFlows() async throws {
        let app = Application.launch(.userSessionScreen)
        
        app.swipeDown() // Make sure the header shows a large title
        
        try await app.assertScreenshot(step: Step.homeScreen)
        
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.buttons[firstRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.roomScreen)
        
        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions].tap(.center)
        try await app.assertScreenshot(step: Step.composerAttachments)
    }
    
    func testUserSessionReply() async throws {
        let app = Application.launch(.userSessionScreenReply, disableTimelineAccessibility: false)
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.buttons[firstRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        
        let cell = app.cells.element(boundBy: 1) // Skip the typing indicator cell
        cell.swipeRight(velocity: .slow) // The iOS 26 simulator doesn't like a fast swipe.
        
        try await app.assertScreenshot()
    }
    
    func testElementCall() {
        let app = Application.launch(.userSessionScreen)
        
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.buttons[firstRoomName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.roomScreen.joinCall].tap()
        
        let textField = app.textFields["Display name"]
        XCTAssert(textField.waitForExistence(timeout: 10))
        
        let joinButton = app.buttons["Continue"]
        XCTAssert(joinButton.waitForExistence(timeout: 10))
    }
    
    func testRoomDetails() {
        let app = Application.launch(.userSessionScreen)
        
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.buttons[firstRoomName].waitForExistence(timeout: 5.0))
        
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
        app.buttons[A11yIdentifiers.roomDetailsScreen.people].tap()
        
        // Open the first member's details. Loading members for big rooms can take a while.
        let firstRoomMember = app.scrollViews.buttons.firstMatch
        XCTAssertTrue(firstRoomMember.waitForExistence(timeout: 1000.0))
        firstRoomMember.tap(.center)
        
        // Open the profile from the bottom sheet
        let viewProfileButton = app.buttons[A11yIdentifiers.manageRoomMemberSheet.viewProfile]
        XCTAssertTrue(viewProfileButton.waitForExistence(timeout: 10.0))
        app.buttons[A11yIdentifiers.manageRoomMemberSheet.viewProfile].tap()
        
        // Go back to the room member details
        tapOnBackButton("People", app)
        
        // Go back to the room details
        tapOnBackButton("Room info", app)
        
        // Go back to the room
        tapOnBackButton("Chat", app)
    }
    
    func testPhotoSharing() {
        let app = Application.launch(.userSessionScreen)
        
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.buttons[firstRoomName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions].tap()
        app.buttons[A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary].tap()
        
        // Tap on the second image. First one is always broken on simulators.
        let secondImage = app.scrollViews.images.element(boundBy: 1)
        XCTAssertTrue(secondImage.waitForExistence(timeout: 20.0)) // Photo library takes a bit to load
        secondImage.tap(.center)
    }
    
    func testDocumentSharing() {
        let app = Application.launch(.userSessionScreen)
        
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.buttons[firstRoomName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions].tap()
        app.buttons[A11yIdentifiers.roomScreen.attachmentPickerDocuments].tap()
    }
    
    func testLocationSharing() {
        let app = Application.launch(.userSessionScreen)
        
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.buttons[firstRoomName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions].tap()
        app.buttons[A11yIdentifiers.roomScreen.attachmentPickerLocation].tap()
        
        allowLocationPermissionOnce()
        
        // Handle map loading errors (missing credentials)
        let alertOkButton = app.alerts.firstMatch.buttons["OK"].firstMatch
        if alertOkButton.waitForExistence(timeout: 10.0) {
            alertOkButton.tap(.center)
        }
    }
    
    func testSpaceExploration() async throws {
        let app = Application.launch(.userSessionSpacesFlow)
        
        app.swipeDown() // Make sure the header shows a large title
        
        try await app.assertScreenshot(step: Step.homeScreenWithTabBar)
        
        // app.tabBars doesn't work on iPadOS 18 😐
        app.buttons["Spaces"].firstMatch.tap(.center)
        
        try await app.assertScreenshot(step: Step.spacesScreen)
        
        app.buttons[A11yIdentifiers.spacesScreen.spaceRoomName(firstSpaceName)].tap()
        XCTAssert(app.staticTexts[firstSpaceName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceScreen)
        
        app.buttons[A11yIdentifiers.spacesScreen.spaceRoomName(joinedSubspaceName)].tap()
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.subspaceScreen)
        
        app.buttons[A11yIdentifiers.spaceScreen.moreMenu].tap()
        app.buttons[A11yIdentifiers.spaceScreen.createRoom].tap()
        XCTAssertTrue(app.buttons[A11yIdentifiers.createRoomScreen.cancel].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.createSpaceRoomScreen)
        
        app.buttons[A11yIdentifiers.createRoomScreen.cancel].tap()
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.spaceScreen.moreMenu].tap()
        app.buttons[A11yIdentifiers.spaceScreen.addExistingRooms].tap()
        XCTAssert(app.buttons[A11yIdentifiers.spaceAddRoomsScreen.cancel].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceAddRoomsScreen)
        
        app.buttons[A11yIdentifiers.spaceAddRoomsScreen.cancel].tap()
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.spaceScreen.moreMenu].tap()
        app.buttons[A11yIdentifiers.spaceScreen.viewMembers].tap()
        XCTAssert(app.buttons[A11yIdentifiers.roomMembersListScreen.invite].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceMembersListScreen)
        
        app.navigationBars.buttons[joinedSubspaceName].firstMatch.tap(.center)
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.spaceScreen.moreMenu].tap()
        app.buttons[A11yIdentifiers.spaceScreen.settings].tap()
        XCTAssert(app.buttons[A11yIdentifiers.spaceSettingsScreen.editBaseInfo].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceSettingsScreen)
        
        app.navigationBars.buttons[joinedSubspaceName].firstMatch.tap(.center)
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.spacesScreen.spaceRoomName(joinedSubspaceRoomName)].tap()
        XCTAssert(app.buttons[joinedSubspaceRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.subspaceRoomScreen)
        
        app.navigationBars.buttons[joinedSubspaceName].firstMatch.tap(.center)
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        
        app.navigationBars.buttons[firstSpaceName].firstMatch.tap(.center)
        XCTAssert(app.staticTexts[firstSpaceName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.spacesScreen.spaceRoomName(unjoinedSpaceRoomName)].tap()
        XCTAssert(app.staticTexts[unjoinedSpaceRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceJoinRoomScreen)
    }
    
    func testAcceptSpaceInvite() async throws {
        let app = Application.launch(.userSessionSpacesFlow)
        
        app.swipeDown() // Make sure the header shows a large title
        
        try await app.assertScreenshot(step: Step.homeScreenWithTabBar)
        
        // Tap the space invite cell.
        app.staticTexts[A11yIdentifiers.homeScreen.roomName(spaceInviteName)].tap()
        XCTAssert(app.buttons[A11yIdentifiers.joinRoomScreen.join].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceJoinRoomScreen)
        
        // Tap join on the join room screen.
        app.buttons[A11yIdentifiers.joinRoomScreen.join].tap()
        XCTAssert(app.buttons[A11yIdentifiers.roomScreen.name].waitForExistence(timeout: 5.0)) // The space screen reuses the room screen header
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceScreen)
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            // Go back to the room list on iPhone.
            app.navigationBars.buttons["Chats"].firstMatch.tap(.center)
            XCTAssert(app.staticTexts["Chats"].waitForExistence(timeout: 5.0))
        } else {
            // Select a different room on iPad (otherwise nothing changes when the join button is tapped below).
            app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
            XCTAssert(app.staticTexts[firstRoomName].waitForExistence(timeout: 5.0))
        }
        
        // Tap the join button in the space invite cell.
        app.buttons.matching(NSPredicate(format: "identifier == %@ && label == %@",
                                         A11yIdentifiers.homeScreen.roomName(spaceInviteName),
                                         "Accept")).firstMatch.tap()
        XCTAssert(app.buttons[A11yIdentifiers.roomScreen.name].waitForExistence(timeout: 5.0)) // The space screen reuses the room screen header
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceScreen)
    }
    
    func testSettings() {
        let app = Application.launch(.userSessionScreen)
        
        let profileButton = app.buttons[A11yIdentifiers.homeScreen.userAvatar]
        
        // `Failed to scroll to visible (by AX action) Button` https://stackoverflow.com/a/33534187/730924
        profileButton.tap(.center)
        
        // Open analytics
        app.buttons[A11yIdentifiers.settingsScreen.analytics].tap()
        
        // Go back to settings
        tapOnBackButton("Settings", app)
        
        // Open report a bug
        app.buttons[A11yIdentifiers.settingsScreen.reportBug].tap()
        
        // Go back to settings
        tapOnBackButton("Settings", app)
        
        // Open about
        app.buttons[A11yIdentifiers.settingsScreen.about].tap()
        
        // Go back to settings
        tapOnBackButton("Settings", app)
        
        // Close the settings
        app.buttons[A11yIdentifiers.settingsScreen.done].tap()
    }
    
    func testRoomCreation() {
        let app = Application.launch(.userSessionScreen)
        
        app.buttons[A11yIdentifiers.homeScreen.startChat].tap()
        
        app.buttons[A11yIdentifiers.startChatScreen.createRoom].tap()
        
        tapOnBackButton("Start chat", app)
    }
    
    private func allowLocationPermissionOnce() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notificationAlertAllowButton = springboard.buttons["Allow Once"].firstMatch
        if notificationAlertAllowButton.waitForExistence(timeout: 10.0) {
            notificationAlertAllowButton.tap(.center)
        }
    }
    
    /// Taps on a back button that the system configured with a label but no identifier.
    ///
    /// When there are multiple buttons with the same label in the hierarchy, all the buttons we created
    /// should have an identifier set, and so this method will ignore those picking the one with only a label.
    private func tapOnBackButton(_ label: String = "Back", _ app: XCUIApplication) {
        let button = app.buttons.matching(NSPredicate(format: "label == %@ && identifier == 'BackButton'", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tap(.center)
    }
}
