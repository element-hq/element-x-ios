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
struct EmojiPickerScreenViewModelTests {
    var emojiPickerStream: AsyncStream<String>!
    
    var viewModel: EmojiPickerScreenViewModel!
    var context: EmojiPickerScreenViewModel.Context {
        viewModel.context
    }
    
    @Test
    mutating func selectEmoji() async throws {
        // Given a freshly presented emoji picker.
        setupViewModel()
        let reaction = "👋"
        
        // When the user taps an emoji.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .emojiTapped(emoji: .init(id: "wave", value: reaction)))
        
        // Then the screen should dismiss and yield the emoji before finishing the stream.
        try await deferred.fulfill()
        var iterator = emojiPickerStream.makeAsyncIterator()
        #expect(await iterator.next() == reaction)
        #expect(await iterator.next() == nil)
    }
    
    @Test
    mutating func stopFinishesTheStream() async {
        // Given a freshly presented emoji picker.
        setupViewModel()
        
        // When it is stopped without a selection (e.g. the picker is dismissed).
        viewModel.stop()
        
        // Then the stream should finish without yielding an emoji.
        var iterator = emojiPickerStream.makeAsyncIterator()
        #expect(await iterator.next() == nil)
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(selectedEmojis: Set<String> = []) {
        let (stream, continuation) = AsyncStream<String>.makeStream()
        emojiPickerStream = stream
        
        viewModel = EmojiPickerScreenViewModel(selectedEmojis: selectedEmojis,
                                               emojiProvider: EmojiProvider(appSettings: .volatile()),
                                               continuation: continuation)
    }
}
