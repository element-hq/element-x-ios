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
        static let spacesTabBar = 4
        static let spaceList = 5
        static let spaceScreen = 6
        static let subspaceScreen = 7
        static let subspaceRoomScreen = 8
        static let spaceJoinRoomScreen = 9
    }
    
    func testUserSessionFlows() async throws {
        let app = Application.launch(.userSessionScreen)
        
        app.swipeDown() // Make sure the header shows a large title
        
        try await app.assertScreenshot(step: Step.homeScreen)

        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.staticTexts[firstRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.roomScreen)

        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions].tap(.center)
        try await app.assertScreenshot(step: Step.composerAttachments)
    }

    func testUserSessionReply() async throws {
        let app = Application.launch(.userSessionScreenReply, disableTimelineAccessibility: false)
        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.staticTexts[firstRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))

        let cell = app.cells.element(boundBy: 1) // Skip the typing indicator cell
        cell.swipeRight(velocity: .fast)

        try await app.assertScreenshot()
    }

    func testElementCall() async throws {
        let app = Application.launch(.userSessionScreen)

        app.buttons[A11yIdentifiers.homeScreen.roomName(firstRoomName)].tap()
        XCTAssert(app.staticTexts[firstRoomName].waitForExistence(timeout: 5.0))

        app.buttons[A11yIdentifiers.roomScreen.joinCall].tap()
        
        let textField = app.textFields["Display name"]
        XCTAssert(textField.waitForExistence(timeout: 10))
        
        let joinButton = app.buttons["Continue"]
        XCTAssert(joinButton.waitForExistence(timeout: 10))
    }
    
    func testSpaceExploration() async throws {
        let app = Application.launch(.userSessionSpacesFlow)
        
        app.swipeDown() // Make sure the header shows a large title
        
        try await app.assertScreenshot(step: Step.spacesTabBar)
        
        // app.tabBars doesn't work on iPadOS 18 😐
        app.buttons["Spaces"].firstMatch.tap(.center)
        
        try await app.assertScreenshot(step: Step.spaceList)
        
        app.buttons[A11yIdentifiers.spaceListScreen.spaceRoomName(firstSpaceName)].tap()
        XCTAssert(app.staticTexts[firstSpaceName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceScreen)
        
        app.buttons[A11yIdentifiers.spaceListScreen.spaceRoomName(joinedSubspaceName)].tap()
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.subspaceScreen)
        
        app.buttons[A11yIdentifiers.spaceListScreen.spaceRoomName(joinedSubspaceRoomName)].tap()
        XCTAssert(app.staticTexts[joinedSubspaceRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.subspaceRoomScreen)
        
        app.navigationBars.buttons[joinedSubspaceName].firstMatch.tap(.center)
        XCTAssert(app.staticTexts[joinedSubspaceName].waitForExistence(timeout: 5.0))
        
        app.navigationBars.buttons[firstSpaceName].firstMatch.tap(.center)
        XCTAssert(app.staticTexts[firstSpaceName].waitForExistence(timeout: 5.0))
        
        app.buttons[A11yIdentifiers.spaceListScreen.spaceRoomName(unjoinedSpaceRoomName)].tap()
        XCTAssert(app.staticTexts[unjoinedSpaceRoomName].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceJoinRoomScreen)
    }
    
    func testAcceptSpaceInvite() async throws {
        let app = Application.launch(.userSessionSpacesFlow)
        
        app.swipeDown() // Make sure the header shows a large title
        
        try await app.assertScreenshot(step: Step.spacesTabBar)
        
        // Tap the space invite cell.
        app.staticTexts[A11yIdentifiers.homeScreen.roomName(spaceInviteName)].tap()
        XCTAssert(app.buttons[A11yIdentifiers.joinRoomScreen.join].waitForExistence(timeout: 5.0))
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceJoinRoomScreen)
        
        // Tap join on the join room screen.
        app.buttons[A11yIdentifiers.joinRoomScreen.join].tap()
        XCTAssert(app.staticTexts[A11yIdentifiers.roomScreen.name].waitForExistence(timeout: 5.0)) // The space screen reuses the room screen header
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceScreen)
        
        // Go back to the room list.
        app.navigationBars.buttons["Chats"].firstMatch.tap(.center)
        XCTAssert(app.staticTexts["Chats"].waitForExistence(timeout: 5.0))
        
        // Tap the join button in the space invite cell.
        app.buttons.matching(NSPredicate(format: "identifier == %@ && label == %@",
                                         A11yIdentifiers.homeScreen.roomName(spaceInviteName),
                                         "Accept")).firstMatch.tap()
        XCTAssert(app.staticTexts[A11yIdentifiers.roomScreen.name].waitForExistence(timeout: 5.0)) // The space screen reuses the room screen header
        try await Task.sleep(for: .seconds(1))
        try await app.assertScreenshot(step: Step.spaceScreen)
    }
}
