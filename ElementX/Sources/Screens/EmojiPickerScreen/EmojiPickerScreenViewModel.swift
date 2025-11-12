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
    private let itemID: TimelineItemIdentifier
    private let emojiProvider: EmojiProviderProtocol
    private let timelineController: TimelineControllerProtocol
    
    private var actionsSubject: PassthroughSubject<EmojiPickerScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<EmojiPickerScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(itemID: TimelineItemIdentifier, selectedEmojis: Set<String>, emojiProvider: EmojiProviderProtocol, timelineController: TimelineControllerProtocol) {
        let initialViewState = EmojiPickerScreenViewState(categories: [], selectedEmojis: selectedEmojis)
        self.itemID = itemID
        self.emojiProvider = emojiProvider
        self.timelineController = timelineController
        super.init(initialViewState: initialViewState)
        loadEmojis()
    }
    
    // MARK: - Public
    
    override func process(viewAction: EmojiPickerScreenViewAction) {
        switch viewAction {
        case let .search(searchString: searchString):
            Task {
                let categories = await emojiProvider.categories(searchString: searchString)
                state.categories = convert(emojiCategories: categories)
            }
        case let .emojiTapped(emoji: emoji):
            Task { await selectEmoji(emoji) }
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private

    private func loadEmojis() {
        Task(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let categories = await self.emojiProvider.categories(searchString: nil)
            self.state.categories = convert(emojiCategories: categories)
        }
    }
    
    private func convert(emojiCategories: [EmojiCategory]) -> [EmojiPickerEmojiCategoryViewData] {
        emojiCategories.compactMap { emojiCategory in
            let emojisViewData: [EmojiPickerEmojiViewData] = emojiCategory.emojis.compactMap { emojiItem in
                EmojiPickerEmojiViewData(id: "\(emojiCategory.id)-\(emojiItem.id)", value: emojiItem.unicode)
            }
            
            return EmojiPickerEmojiCategoryViewData(id: emojiCategory.id, emojis: emojisViewData)
        }
    }
    
    private func selectEmoji(_ emoji: EmojiPickerEmojiViewData) async {
        MXLog.debug("Selected \(emoji) for \(itemID)")
        emojiProvider.markEmojiAsFrequentlyUsed(emoji.value)
        
        guard case let .event(_, eventOrTransactionID) = itemID else { fatalError("Attempted to react to a virtual item.") }
        
        // There aren't any local echoes when the toggle redacts, so dismiss the screen early
        // until we have them: https://github.com/matrix-org/matrix-rust-sdk/issues/4162
        actionsSubject.send(.dismiss)
        
        await timelineController.toggleReaction(emoji.value, to: eventOrTransactionID)
    }
}
