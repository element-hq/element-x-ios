//
// Copyright 2022 New Vector Ltd
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

import ElementX
import XCTest

@MainActor
class RoomScreenUITests: XCTestCase {
    func testPlainNoAvatar() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomPlainNoAvatar)

        XCTAssert(app.staticTexts["roomNameLabel"].exists)
        XCTAssert(app.staticTexts["roomAvatarImage"].exists)

        app.assertScreenshot(.roomPlainNoAvatar)
    }

    func testEncryptedWithAvatar() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomEncryptedWithAvatar)

        XCTAssert(app.staticTexts["roomNameLabel"].exists)
        XCTAssert(app.images["roomAvatarImage"].waitForExistence(timeout: 1))

        app.assertScreenshot(.roomEncryptedWithAvatar)
    }
    
    func testSmallTimelineLayout() {
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomSmallTimeline)
        
        // The messages should be bottom aligned.
        app.assertScreenshot(.roomSmallTimeline)
    }
    
    func testSmallTimelineWithIncomingAndPagination() async throws {
        let listener = try UITestsSignalling.Listener()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomSmallTimelineIncomingAndSmallPagination)
        
        let connection = try await listener.connection()
        try await Task.sleep(for: .seconds(1)) // Allow the connection to settle on CI/Intel...
        defer { connection.disconnect() }
        
        // When a back pagination occurs and an incoming message arrives.
        try await performOperation(.incomingMessage, using: connection)
        try await performOperation(.paginate, using: connection)

        // Then the 4 visible messages should stay aligned to the bottom.
        app.assertScreenshot(.roomSmallTimelineIncomingAndSmallPagination)
    }
    
    func testSmallTimelineWithLargePagination() async throws {
        let listener = try UITestsSignalling.Listener()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomSmallTimelineLargePagination)
        
        let connection = try await listener.connection()
        try await Task.sleep(for: .seconds(1)) // Allow the connection to settle on CI/Intel...
        defer { connection.disconnect() }
        
        // When a large back pagination occurs.
        try await performOperation(.paginate, using: connection)

        // The bottom of the timeline should remain visible with more items added above.
        app.assertScreenshot(.roomSmallTimelineLargePagination)
    }
    
    func testTimelineLayoutInMiddle() async throws {
        let listener = try UITestsSignalling.Listener()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomLayoutMiddle)
        
        let connection = try await listener.connection()
        try await Task.sleep(for: .seconds(1)) // Allow the connection to settle on CI/Intel...
        defer { connection.disconnect() }
        
        // Given a timeline that is neither at the top nor the bottom.
        app.tables.element.swipeDown()
        try await Task.sleep(for: .milliseconds(500)) // Allow the table to settle
        app.assertScreenshot(.roomLayoutMiddle, step: 0) // Assert initial state for comparison.
        
        // When a back pagination occurs.
        try await performOperation(.paginate, using: connection)
        
        // Then the UI should remain unchanged.
        app.assertScreenshot(.roomLayoutMiddle, step: 0)
        
        // When an incoming message arrives
        try await performOperation(.incomingMessage, using: connection)
        
        // Then the UI should still remain unchanged.
        app.assertScreenshot(.roomLayoutMiddle, step: 0)
        
        // When the keyboard appears for the message composer.
        try await tapMessageComposer(in: app)
        
        // Then the timeline scroll offset should remain unchanged.
        app.assertScreenshot(.roomLayoutMiddle, step: 1)
    }
    
    func testTimelineLayoutAtTop() async throws {
        let listener = try UITestsSignalling.Listener()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomLayoutTop)
        
        let connection = try await listener.connection()
        try await Task.sleep(for: .seconds(1)) // Allow the connection to settle on CI/Intel...
        defer { connection.disconnect() }
        
        // Given a timeline that is scrolled to the top.
        while !app.staticTexts["Bacon ipsum dolor amet commodo incididunt ribeye dolore cupidatat short ribs."].isHittable {
            app.tables.element.swipeDown()
        }
        let cropped = UIEdgeInsets(top: 150, left: 0, bottom: 0, right: 0) // Ignore the navigation bar and pagination indicator as these change.
        app.assertScreenshot(.roomLayoutTop, insets: cropped) // Assert initial state for comparison.
        
        // When a back pagination occurs.
        try await performOperation(.paginate, using: connection)

        // Then the bottom of the timeline should remain unchanged (with new items having been added above).
        app.assertScreenshot(.roomLayoutTop, insets: cropped)
    }
    
    func testTimelineLayoutAtBottom() async throws {
        let listener = try UITestsSignalling.Listener()
        
        let app = Application.launch()
        app.goToScreenWithIdentifier(.roomLayoutBottom)
        
        let connection = try await listener.connection()
        try await Task.sleep(for: .seconds(2)) // Allow the connection to settle on CI/Intel...
        defer { connection.disconnect() }
        
        // When an incoming message arrives.
        try await performOperation(.incomingMessage, using: connection)
        
        // Then the timeline should scroll down to reveal the message.
        app.assertScreenshot(.roomLayoutBottom, step: 0)
        
        // When the keyboard appears for the message composer.
        try await tapMessageComposer(in: app)
        
        // Then the timeline should still show the last message.
        app.assertScreenshot(.roomLayoutBottom, step: 1)
    }
    
    // MARK: - Helper Methods
    
    private func performOperation(_ operation: UITestsSignal, using connection: UITestsSignalling.Connection) async throws {
        try await connection.send(operation)
        guard try await connection.receive() == .success else { throw UITestsSignalError.unexpected }
        try await Task.sleep(for: .milliseconds(500)) // Allow the timeline to update
    }
    
    private func tapMessageComposer(in app: XCUIApplication) async throws {
        app.textViews.element.tap()
        try await Task.sleep(for: .milliseconds(500)) // Allow the animations to complete
    }
}
