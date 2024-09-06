//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@MainActor
class RoomScreenUITests: XCTestCase {
    func testPlainNoAvatar() async throws {
        let app = Application.launch(.roomPlainNoAvatar)

        XCTAssert(app.staticTexts[A11yIdentifiers.roomScreen.name].exists)
        XCTAssert(app.staticTexts[A11yIdentifiers.roomScreen.avatar].exists)

        try await app.assertScreenshot(.roomPlainNoAvatar)
    }
    
    func testSmallTimelineLayout() async throws {
        let app = Application.launch(.roomSmallTimeline)
        
        // The messages should be bottom aligned.
        try await app.assertScreenshot(.roomSmallTimeline)
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
        try await app.assertScreenshot(.roomSmallTimelineIncomingAndSmallPagination)
    }
    
    func testSmallTimelineWithLargePagination() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomSmallTimelineLargePagination)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // When a large back pagination occurs.
        try await performOperation(.paginate, using: client)

        // The bottom of the timeline should remain visible with more items added above.
        try await app.assertScreenshot(.roomSmallTimelineLargePagination)
    }
    
    func testTimelineLayoutAtTop() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomLayoutTop)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // Given a timeline that is scrolled to the top.
        for _ in 0...5 {
            app.swipeDown()
        }
        try await app.assertScreenshot(.roomLayoutTop) // Assert initial state for comparison.
        
        // When a back pagination occurs.
        try await performOperation(.paginate, using: client)

        // Then the bottom of the timeline should remain unchanged (with new items having been added above).
        try await app.assertScreenshot(.roomLayoutTop)
    }

    func testTimelineLayoutAtBottom() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomLayoutBottom)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // Some time for the timeline to settle
        try await Task.sleep(for: .seconds(1))
        // When an incoming message arrives.
        try await performOperation(.incomingMessage, using: client)
        // Some time for the timeline to settle
        try await Task.sleep(for: .seconds(1))
        
        // Then the timeline should scroll down to reveal the message.
        try await app.assertScreenshot(.roomLayoutBottom, step: 0)
        
        // When the keyboard appears for the message composer.
        try await tapMessageComposer(in: app)
        
        try await app.assertScreenshot(.roomLayoutBottom, step: 1)
    }
    
    func testTimelineLayoutHighlightExisting() async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        
        let app = Application.launch(.roomLayoutHighlight)
        
        await client.waitForApp()
        defer { try? client.stop() }
        
        // When tapping a permalink to an item in the timeline.
        try await performOperation(.focusOnEvent("$5"), using: client)
        
        // Then the item should become highlighted.
        try await app.assertScreenshot(.roomLayoutHighlight, step: 0)
        
        guard UIDevice.current.userInterfaceIdiom == .phone else { return }
        
        // When scrolling to the bottom and tapping the same permalink again.
        app.buttons[A11yIdentifiers.roomScreen.scrollToBottom].tap()
        try await Task.sleep(for: .seconds(1)) // Some time for the timeline to settle
        try await performOperation(.focusOnEvent("$5"), using: client)
        
        // Then the item should also be highlighted and scrolled to in the same state as before.
        try await app.assertScreenshot(.roomLayoutHighlight, step: 0)
    }

    func testTimelineReadReceipts() async throws {
        let app = Application.launch(.roomSmallTimelineWithReadReceipts)

        // The messages should be bottom aligned.
        try await app.assertScreenshot(.roomSmallTimelineWithReadReceipts)
    }

    func testTimelineDisclosedPolls() async throws {
        let app = Application.launch(.roomWithDisclosedPolls)

        try await app.assertScreenshot(.roomWithDisclosedPolls)
    }

    func testTimelineUndisclosedPolls() async throws {
        let app = Application.launch(.roomWithUndisclosedPolls)

        try await app.assertScreenshot(.roomWithUndisclosedPolls)
    }

    func testTimelineOutgoingPolls() async throws {
        let app = Application.launch(.roomWithOutgoingPolls)

        try await app.assertScreenshot(.roomWithOutgoingPolls)
    }

    // MARK: - Helper Methods
    
    private func performOperation(_ operation: UITestsSignal.Timeline, using client: UITestsSignalling.Client) async throws {
        try client.send(.timeline(operation))
        await _ = client.signals.values.first { $0 == .success }
        try await Task.sleep(for: .seconds(2)) // Allow the timeline to update
    }
    
    private func tapMessageComposer(in app: XCUIApplication) async throws {
        app.textViews.element.tap()
        try await Task.sleep(for: .seconds(10)) // Allow the animations to complete
    }
}
