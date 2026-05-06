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
    
    private var app: XCUIApplication!
    
    override func setUp() async throws {
        app = Application.launch()
        try app.login(currentTestCase: self)
    }
    
    func testUserFlow() {
        checkRoomFlows()
        
        app.logout()
    }
    
    /// Assumes app is on the home screen
    private func checkRoomFlows() {
        // Wait for the room list to paginate and correctly compute the room display names otherwise the test room
        // won't be found
        // Remove once https://github.com/element-hq/element-x-ios/issues/3365 gets sorted
        sleep(30)
        
        // Search for the special test room
        let searchField = app.searchFields.firstMatch
        searchField.clearAndTypeText(Self.integrationTestsRoomName, app: app)
        
        // And open it
        let firstRoom = app.buttons.matching(NSPredicate(format: "identifier CONTAINS %@", Self.integrationTestsRoomName)).firstMatch
        
        // The backend is sometimes really slow and having a longer timeout
        // beats having to rerun the whole suite again.
        XCTAssertTrue(firstRoom.waitForExistence(timeout: 100.0))
        
        firstRoom.tap(.center)
        
        sendMessages()
        
        checkTimelineItemActionMenu()
        
        // Go back to the room list
        tapOnBackButton("Chats")
        
        // Cancel initial the room search
        let searchCancelButton = app.buttons["Close"].firstMatch
        XCTAssertTrue(searchCancelButton.waitForExistence(timeout: 10.0))
        searchCancelButton.tap(.center)
    }
    
    private func sendMessages() {
        var composerTextField = app.textViews[A11yIdentifiers.roomScreen.messageComposer].firstMatch
        XCTAssertTrue(composerTextField.waitForExistence(timeout: 10.0))
        composerTextField.clearAndTypeText(Self.integrationTestsMessage, app: app)
        
        var sendButton = app.buttons[A11yIdentifiers.roomScreen.sendButton].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0))
        sendButton.tap(.center)
        
        sleep(10) // Wait for the message to be sent
        
        // Switch to the rich text editor
        tapOnButton(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        tapOnButton(A11yIdentifiers.roomScreen.attachmentPickerTextFormatting)
        
        composerTextField = app.textViews[A11yIdentifiers.roomScreen.messageComposer].firstMatch
        XCTAssertTrue(composerTextField.waitForExistence(timeout: 10.0))
        composerTextField.clearAndTypeText(Self.integrationTestsMessage, app: app)
        
        sendButton = app.buttons[A11yIdentifiers.roomScreen.sendButton].firstMatch
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10.0))
        sendButton.tap(.center)
        
        sleep(5) // Wait for the message to be sent
        
        // Close the formatting options
        app.buttons[A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions].tap(.center)
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
    
    private func tapOnButton(_ identifier: String, waitForDisappearance: Bool = false) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tap(.center)
        
        if waitForDisappearance {
            let doesNotExistPredicate = NSPredicate(format: "exists == 0")
            expectation(for: doesNotExistPredicate, evaluatedWith: button)
            waitForExpectations(timeout: 10.0)
        }
    }
    
    /// Taps on a back button that the system configured with a label but no identifier.
    ///
    /// When there are multiple buttons with the same label in the hierarchy, all the buttons we created
    /// should have an identifier set, and so this method will ignore those picking the one with only a label.
    private func tapOnBackButton(_ label: String = "Back") {
        let button = app.buttons.matching(NSPredicate(format: "label == %@ && identifier == 'BackButton'", label)).firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 10.0))
        button.tap(.center)
    }
}
