//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@MainActor
struct EmojiPickerScreenViewModelTests {
    var emojiPickerStream: AsyncStream<EmojiPickerItem>!
    
    var viewModel: EmojiPickerScreenViewModel!
    var context: EmojiPickerScreenViewModel.Context {
        viewModel.context
    }
    
    @Test("Tapping an emoji dismisses the picker and yields it")
    mutating func selectEmoji() async throws {
        // Given a freshly presented emoji picker.
        setupViewModel()
        let reaction = "👋"
        
        // When the user taps an emoji.
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .emojiTapped(emoji: .init(id: "wave", item: .emoji(reaction))))
        
        // Then the screen should dismiss and yield the emoji before finishing the stream.
        try await deferred.fulfill()
        var iterator = emojiPickerStream.makeAsyncIterator()
        #expect(await iterator.next() == .emoji(reaction))
        #expect(await iterator.next() == nil)
    }
    
    @Test("Stopping without a selection finishes the stream")
    mutating func stopWithoutSelection() async {
        // Given a freshly presented emoji picker.
        setupViewModel()
        
        // When it is stopped without a selection (e.g. the picker is dismissed).
        viewModel.stop()
        
        // Then the stream should finish without yielding an emoji.
        var iterator = emojiPickerStream.makeAsyncIterator()
        #expect(await iterator.next() == nil)
    }
    
    @Test("Only the room's emoticon packs are offered, can be searched and are selected as custom images")
    mutating func selectCustomImage() async throws {
        // Given an emoji picker for a room with an emoticon pack and a sticker-only pack.
        let wave = try makeCustomImage("wave")
        let blobcat = try makeCustomImage("blobcat")
        let sticker = try makeCustomImage("sticker")
        let imagePackProvider = ImagePackProviderMock()
        imagePackProvider.imagePacksReturnValue = .success([
            ImagePack(id: "emoticons", displayName: "Emoticons", isEmoticonPack: true, isStickerPack: false, images: [wave, blobcat]),
            ImagePack(id: "stickers", displayName: "Stickers", isEmoticonPack: false, isStickerPack: true, images: [sticker])
        ])
        let userSettings = UserSettings.mock()
        setupViewModel(imagePackProvider: imagePackProvider, userSettings: userSettings)
        var deferredCategories = deferFulfillment(context.observe(\.viewState.categories)) { $0.first?.name == "Emoticons" }
        try await deferredCategories.fulfill()
        
        // Then only the emoticon pack should be offered, before the emoji categories.
        #expect(context.viewState.categories.filter { !$0.customImages.isEmpty }.map(\.name) == ["Emoticons"])
        #expect(context.viewState.categories.first?.customImages == [wave, blobcat])
        
        // When searching.
        deferredCategories = deferFulfillment(context.observe(\.viewState.categories)) { $0.first?.emojis.count == 1 }
        context.send(viewAction: .search(searchString: "BLOB"))
        try await deferredCategories.fulfill()
        
        // Then only the matching images should be offered.
        #expect(context.viewState.categories.first?.customImages == [blobcat])
        
        // When the user taps an image.
        let image = try #require(context.viewState.categories.first?.emojis.first)
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .emojiTapped(emoji: image))
        
        // Then the screen should dismiss and yield the image.
        try await deferred.fulfill()
        var iterator = emojiPickerStream.makeAsyncIterator()
        #expect(await iterator.next() == .customImage(blobcat))
        #expect(await iterator.next() == nil)
        
        // And the image should be offered first as frequently used the next time.
        setupViewModel(imagePackProvider: imagePackProvider, userSettings: userSettings)
        deferredCategories = deferFulfillment(context.observe(\.viewState.categories)) { $0.first?.id == EmojiCategory.frequentlyUsedCategoryIdentifier }
        try await deferredCategories.fulfill()
        #expect(context.viewState.categories.first?.customImages == [blobcat])
    }
    
    @Test("The sticker picker only offers the sticker packs and yields the picked sticker")
    mutating func selectSticker() async throws {
        // Given a sticker picker for a room with an emoticon pack and a sticker pack.
        let wave = try makeCustomImage("wave")
        let sticker = try makeCustomImage("sticker")
        let imagePackProvider = ImagePackProviderMock()
        imagePackProvider.imagePacksReturnValue = .success([
            ImagePack(id: "emoticons", displayName: "Emoticons", isEmoticonPack: true, isStickerPack: false, images: [wave]),
            ImagePack(id: "stickers", displayName: "Stickers", attribution: "By Alice", isEmoticonPack: false, isStickerPack: true, images: [sticker])
        ])
        let userSettings = UserSettings.mock()
        setupViewModel(mode: .sticker, imagePackProvider: imagePackProvider, userSettings: userSettings)
        let deferredCategories = deferFulfillment(context.observe(\.viewState.categories)) { !$0.isEmpty }
        try await deferredCategories.fulfill()
        
        // Then only the sticker pack should be offered, credited to its author, without any emojis.
        #expect(context.viewState.categories.map(\.name) == ["Stickers"])
        #expect(context.viewState.categories.first?.subtitle == "By Alice")
        
        // When the user taps the sticker.
        let item = try #require(context.viewState.categories.first?.emojis.first)
        let deferred = deferFulfillment(viewModel.actions) { $0 == .dismiss }
        context.send(viewAction: .emojiTapped(emoji: item))
        
        // Then the sticker should be yielded, without becoming a frequently used reaction.
        try await deferred.fulfill()
        var iterator = emojiPickerStream.makeAsyncIterator()
        #expect(await iterator.next() == .customImage(sticker))
        #expect(EmojiProvider(userSettings: userSettings).frequentlyUsedSystemEmojis().isEmpty)
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(mode: EmojiPickerScreenMode = .reaction, selectedEmojis: Set<String> = [], imagePackProvider: ImagePackProviderProtocol? = nil, userSettings: UserSettings = .mock()) {
        let (stream, continuation) = AsyncStream<EmojiPickerItem>.makeStream()
        emojiPickerStream = stream
        
        viewModel = EmojiPickerScreenViewModel(mode: mode,
                                               selectedEmojis: selectedEmojis,
                                               emojiProvider: EmojiProvider(userSettings: userSettings),
                                               imagePackProvider: imagePackProvider,
                                               continuation: continuation)
    }
    
    private func makeCustomImage(_ shortcode: String) throws -> ImagePack.Image {
        try ImagePack.Image(shortcode: shortcode, body: shortcode, mediaSource: MediaSourceProxy(url: #require(URL(string: "mxc://example.org/\(shortcode)")), mimeType: nil))
    }
}

private extension EmojiPickerEmojiCategoryViewData {
    var customImages: [ImagePack.Image] {
        emojis.compactMap { emoji in
            guard case let .customImage(image) = emoji.item else { return nil }
            return image
        }
    }
}
