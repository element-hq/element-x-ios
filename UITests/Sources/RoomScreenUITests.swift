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
        let app = Application.launch(.roomPlainNoAvatar)

        XCTAssert(app.staticTexts["roomNameLabel"].exists)
        XCTAssert(app.staticTexts["roomAvatarImage"].exists)

        app.assertScreenshot(.roomPlainNoAvatar)
    }

    func testEncryptedWithAvatar() {
        let app = Application.launch(.roomEncryptedWithAvatar)

        XCTAssert(app.staticTexts["roomNameLabel"].exists)
        XCTAssert(app.images["roomAvatarImage"].waitForExistence(timeout: 1))

        app.assertScreenshot(.roomEncryptedWithAvatar)
    }
    
    func testSmallTimelineLayout() {
        let app = Application.launch(.roomSmallTimeline)
        
        // The messages should be bottom aligned.
        app.assertScreenshot(.roomSmallTimeline)
    }
    
    func testSmallTimelineWithIncomingAndPagination() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomSmallTimelineIncomingAndSmallPagination)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // When a back pagination occurs and an incoming message arrives.
        try await performOperation(.incomingMessage, using: client)
        try await performOperation(.paginate, using: client)

        // Then the 4 visible messages should stay aligned to the bottom.
        app.assertScreenshot(.roomSmallTimelineIncomingAndSmallPagination)
    }
    
    func testSmallTimelineWithLargePagination() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomSmallTimelineLargePagination)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // When a large back pagination occurs.
        try await performOperation(.paginate, using: client)

        // The bottom of the timeline should remain visible with more items added above.
        app.assertScreenshot(.roomSmallTimelineLargePagination)
    }
    
    func testTimelineLayoutInMiddle() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomLayoutMiddle)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // Given a timeline that is neither at the top nor the bottom.
        app.tables.element.swipeDown()
        try await Task.sleep(for: .milliseconds(500)) // Allow the table to settle
        app.assertScreenshot(.roomLayoutMiddle, step: 0) // Assert initial state for comparison.
        
        // When a back pagination occurs.
        try await performOperation(.paginate, using: client)
        
        // Then the UI should remain unchanged.
        app.assertScreenshot(.roomLayoutMiddle, step: 0)
        
        // When an incoming message arrives
        try await performOperation(.incomingMessage, using: client)
        
        // Then the UI should still remain unchanged.
        app.assertScreenshot(.roomLayoutMiddle, step: 0)
        
        // When the keyboard appears for the message composer.
        try await tapMessageComposer(in: app)
        
        // Then the timeline scroll offset should remain unchanged.
        app.assertScreenshot(.roomLayoutMiddle, step: 1)
    }
    
    func testTimelineLayoutAtTop() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomLayoutTop)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // Given a timeline that is scrolled to the top.
        while !app.staticTexts["Bacon ipsum dolor amet commodo incididunt ribeye dolore cupidatat short ribs."].isHittable {
            app.tables.element.swipeDown()
        }
        let cropped = UIEdgeInsets(top: 150, left: 0, bottom: 0, right: 0) // Ignore the navigation bar and pagination indicator as these change.
        app.assertScreenshot(.roomLayoutTop, insets: cropped) // Assert initial state for comparison.
        
        // When a back pagination occurs.
        try await performOperation(.paginate, using: client)

        // Then the bottom of the timeline should remain unchanged (with new items having been added above).
        app.assertScreenshot(.roomLayoutTop, insets: cropped)
    }
    
    func testTimelineLayoutAtBottom() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomLayoutBottom)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // When an incoming message arrives.
        try await performOperation(.incomingMessage, using: client)
        
        // Then the timeline should scroll down to reveal the message.
        app.assertScreenshot(.roomLayoutBottom, step: 0)
        
        // When the keyboard appears for the message composer.
        try await tapMessageComposer(in: app)
        
        // Then the timeline should still show the last message.
        app.assertScreenshot(.roomLayoutBottom, step: 1)
    }
    
    // MARK: - Helper Methods
    
    private func performOperation(_ operation: UITestsSignal, using client: UITestsSignalling.Client) async throws {
        try client.send(operation)
        await _ = client.signals.values.first { $0 == .success }
        try await Task.sleep(for: .milliseconds(500)) // Allow the timeline to update
    }
    
    private func tapMessageComposer(in app: XCUIApplication) async throws {
        app.textViews.element.tap()
        try await Task.sleep(for: .milliseconds(500)) // Allow the animations to complete
    }
}
