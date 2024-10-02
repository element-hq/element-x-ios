//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias EmojiPickerScreenViewModelType = StateStoreViewModel<EmojiPickerScreenViewState, EmojiPickerScreenViewAction>

class EmojiPickerScreenViewModel: EmojiPickerScreenViewModelType, EmojiPickerScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<EmojiPickerScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<EmojiPickerScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let emojiProvider: EmojiProviderProtocol
    
    init(emojiProvider: EmojiProviderProtocol) {
        let initialViewState = EmojiPickerScreenViewState(categories: [])
        self.emojiProvider = emojiProvider
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
            actionsSubject.send(.emojiSelected(emoji: emoji.value))
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
                EmojiPickerEmojiViewData(id: emojiItem.id, value: emojiItem.unicode)
            }
            
            return EmojiPickerEmojiCategoryViewData(id: emojiCategory.id, emojis: emojisViewData)
        }
    }
}
