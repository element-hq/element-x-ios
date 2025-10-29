//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
class StartChatTests: XCTestCase {
    enum Step {
        static let startChat = 1
        static let startChatWithResults = 2
        static let createRoom = 3
        static let createRoomAvatarPicker = 4
        static let createRoomFilled = 5
        static let inviteUsers = 6
        static let inviteUsersWithResults = 7
        static let inviteUsersSelectedResults = 8
        static let dismissed = 99
    }
    
    func testFlow() async throws {
        let app = Application.launch(.startChatFlow)
        try await app.assertScreenshot(step: Step.startChat)
        
        let startChatSearchField = app.searchFields.firstMatch
        startChatSearchField.clearAndTypeText("Bob\n", app: app)
        XCTAssertFalse(app.staticTexts[A11yIdentifiers.startChatScreen.searchNoResults].waitForExistence(timeout: 1.0))
        XCTAssertEqual(app.collectionViews.firstMatch.cells.count, 2)
        try await app.assertScreenshot(step: Step.startChatWithResults)
        
        startChatSearchField.clearAndTypeText("\n", app: app)
        app.buttons[A11yIdentifiers.startChatScreen.createRoom].firstMatch.tap()
        XCTAssertTrue(app.textFields[A11yIdentifiers.createRoomScreen.roomName].waitForExistence(timeout: 1.0))
        try await app.assertScreenshot(step: Step.createRoom)
        
        app.buttons[A11yIdentifiers.createRoomScreen.roomAvatar].tap()
        app.popovers.buttons.element(boundBy: 2).tap() // There are 2 buttons with the accessibility identifier, so use the index to get the right one.
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 1.0))
        try await app.assertScreenshot(step: Step.createRoomAvatarPicker)
        cancelButton.tap()
        
        // typeText sometimes misses letters but it's faster than typing one letter at a time
        // repeat the same letter enough times to avoid that but also to work on iPads
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].tap()
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].typeText(.init(repeating: "x", count: 200))
        app.textFields[A11yIdentifiers.createRoomScreen.roomName].typeText("\n")
        try await app.assertScreenshot(step: Step.createRoomFilled)
        
        app.buttons[A11yIdentifiers.createRoomScreen.create].tap()
        XCTAssertTrue(app.buttons[A11yIdentifiers.inviteUsersScreen.proceed].waitForExistence(timeout: 1.0))
        try await app.assertScreenshot(step: Step.inviteUsers)
        
        let inviteUsersSearchField = app.searchFields.firstMatch
        inviteUsersSearchField.clearAndTypeText("Bob\n", app: app)
        let cells = app.collectionViews.firstMatch.cells
        XCTAssertEqual(cells.count, 2)
        try await app.assertScreenshot(step: Step.inviteUsersWithResults)
        
        cells.element(boundBy: 0).tap()
        // Selecting the first member has inserted the horizontal collection view above the list.
        // So to select the second member we now need to increment the index by 2 instead of 1.
        cells.element(boundBy: 2).tap()
        try await app.assertScreenshot(step: Step.inviteUsersSelectedResults)
        
        app.buttons[A11yIdentifiers.inviteUsersScreen.proceed].tap()
        try await app.assertScreenshot(step: Step.dismissed)
    }
}
