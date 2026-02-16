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
}
