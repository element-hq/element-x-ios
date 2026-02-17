//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct EmojiPickerScreenViewModelTests {
    var timelineProxy: TimelineProxyMock!
    
    var viewModel: EmojiPickerScreenViewModel!
    var context: EmojiPickerScreenViewModel.Context {
        viewModel.context
    }
    
    @Test
    mutating func toggleReaction() async throws {
        setupViewModel()
        let reaction = "👋"
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        try await confirmation { confirmation in
            var toggleReactionCalled = false
            timelineProxy.toggleReactionToClosure = { toggledReaction, _ in
                defer {
                    confirmation()
                    toggleReactionCalled = true
                }
                #expect(toggledReaction == reaction)
                return .success(())
            }
                
            context.send(viewAction: .emojiTapped(emoji: .init(id: "wave", value: reaction)))
            
            try await deferred.fulfill()
            
            // Since the reaction is called asynchronously after dismissing the picker
            // We need to actively wait for the function to be called before fulfilling the test.
            while !toggleReactionCalled {
                await Task.yield()
            }
        }
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(selectedEmojis: Set<String> = []) {
        timelineProxy = TimelineProxyMock(.init())
        
        viewModel = EmojiPickerScreenViewModel(itemID: .randomEvent,
                                               selectedEmojis: selectedEmojis,
                                               emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                               timelineController: MockTimelineController(timelineProxy: timelineProxy))
    }
}
