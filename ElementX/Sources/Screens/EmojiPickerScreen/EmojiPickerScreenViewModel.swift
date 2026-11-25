//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias EmojiPickerScreenViewModelType = StateStoreViewModelV2<EmojiPickerScreenViewState, EmojiPickerScreenViewAction>

class EmojiPickerScreenViewModel: EmojiPickerScreenViewModelType, EmojiPickerScreenViewModelProtocol {
    private let emojiProvider: EmojiProviderProtocol
    private let imagePackProvider: ImagePackProviderProtocol?
    private let continuation: EmojiPickerScreenContinuation
    
    private var imagePacks: [EmojiPickerEmojiCategoryViewData] = []
    private var searchString = ""
    
    private var actionsSubject: PassthroughSubject<EmojiPickerScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<EmojiPickerScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(mode: EmojiPickerScreenMode = .reaction,
         selectedEmojis: Set<String>,
         emojiProvider: EmojiProviderProtocol,
         imagePackProvider: ImagePackProviderProtocol? = nil,
         mediaProvider: MediaProviderProtocol? = nil,
         continuation: EmojiPickerScreenContinuation) {
        let initialViewState = EmojiPickerScreenViewState(mode: mode, categories: [], selectedEmojis: selectedEmojis)
        self.emojiProvider = emojiProvider
        self.imagePackProvider = imagePackProvider
        self.continuation = continuation
        super.init(initialViewState: initialViewState, mediaProvider: mediaProvider)
        Task { await updateCategories() }
        Task { await loadImagePacks() }
    }
    
    // MARK: - Public
    
    func stop() {
        continuation.finish() // Ensure the continuation always finishes even without a selection.
    }
    
    override func process(viewAction: EmojiPickerScreenViewAction) {
        switch viewAction {
        case let .search(searchString: searchString):
            self.searchString = searchString
            Task { await updateCategories() }
        case let .emojiTapped(emoji: emoji):
            selectEmoji(emoji)
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    /// Shows the frequently used emojis and images first, then the image packs, then the emoji categories.
    private func updateCategories() async {
        let searchString = searchString
        let emojiCategories = await emojiProvider.categories(searchString: searchString)
            .filter { $0.id != EmojiCategory.frequentlyUsedCategoryIdentifier }
        let categories = filter(imagePacks: imagePacks, searchString: searchString) + convert(emojiCategories: emojiCategories)
        
        let itemsByKey = Dictionary(categories.flatMap(\.emojis).map { ($0.item.key, $0.item) }) { first, _ in first }
        let frequentlyUsed = emojiProvider.frequentlyUsedSystemEmojis().prefix(20).compactMap { key in
            itemsByKey[key].map { EmojiPickerEmojiViewData(id: "\(EmojiCategory.frequentlyUsedCategoryIdentifier)-\(key)", item: $0) }
        }
        
        state.categories = if frequentlyUsed.isEmpty {
            categories
        } else {
            [EmojiPickerEmojiCategoryViewData(id: EmojiCategory.frequentlyUsedCategoryIdentifier, emojis: frequentlyUsed)] + categories
        }
    }
    
    private func loadImagePacks() async {
        guard let imagePackProvider, case let .success(packs) = await imagePackProvider.imagePacks() else { return }
        
        imagePacks = packs.filter(\.isEmoticonPack).map { pack in
            let images = pack.images.map { EmojiPickerEmojiViewData(id: "\(pack.id)-\($0.shortcode)", item: .customImage($0)) }
            return EmojiPickerEmojiCategoryViewData(id: pack.id, emojis: images, customName: pack.displayName ?? L10n.a11yCustomEmoji)
        }
        await updateCategories()
    }
    
    private func filter(imagePacks: [EmojiPickerEmojiCategoryViewData], searchString: String) -> [EmojiPickerEmojiCategoryViewData] {
        guard !searchString.isBlank else { return imagePacks }
        
        return imagePacks.compactMap { pack in
            let images = pack.emojis.filter { emoji in
                guard case let .customImage(image) = emoji.item else { return false }
                return image.shortcode.localizedCaseInsensitiveContains(searchString)
            }
            return images.isEmpty ? nil : EmojiPickerEmojiCategoryViewData(id: pack.id, emojis: images, customName: pack.customName)
        }
    }
    
    private func convert(emojiCategories: [EmojiCategory]) -> [EmojiPickerEmojiCategoryViewData] {
        emojiCategories.compactMap { emojiCategory in
            let emojisViewData: [EmojiPickerEmojiViewData] = emojiCategory.emojis.compactMap { emojiItem in
                EmojiPickerEmojiViewData(id: "\(emojiCategory.id)-\(emojiItem.id)", item: .emoji(emojiItem.unicode))
            }
            
            return EmojiPickerEmojiCategoryViewData(id: emojiCategory.id, emojis: emojisViewData)
        }
    }
    
    private func selectEmoji(_ emoji: EmojiPickerEmojiViewData) {
        emojiProvider.markEmojiAsFrequentlyUsed(emoji.item.key)
        
        continuation.yield(emoji.item)
        continuation.finish()
        
        actionsSubject.send(.dismiss)
    }
}
