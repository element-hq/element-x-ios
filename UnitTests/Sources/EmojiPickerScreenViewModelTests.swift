//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
final class EmojiPickerScreenViewModelTests: XCTestCase {
    var timelineProxy: TimelineProxyMock!
    
    var viewModel: EmojiPickerScreenViewModel!
    var context: EmojiPickerScreenViewModel.Context {
        viewModel.context
    }
    
    func testToggleReaction() async throws {
        setupViewModel()
        let reaction = "👋"
        
        let expectation = XCTestExpectation(description: "Toggle reaction")
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        timelineProxy.toggleReactionToClosure = { toggledReaction, _ in
            XCTAssertEqual(toggledReaction, reaction)
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .emojiTapped(emoji: .init(id: "wave", value: reaction)))
        await fulfillment(of: [expectation], timeout: 1)
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(selectedEmojis: Set<String> = []) {
        timelineProxy = TimelineProxyMock(.init())
        
        viewModel = EmojiPickerScreenViewModel(itemID: .randomEvent,
                                               selectedEmojis: selectedEmojis,
                                               emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                               timelineController: MockTimelineController(timelineProxy: timelineProxy))
    }
}
