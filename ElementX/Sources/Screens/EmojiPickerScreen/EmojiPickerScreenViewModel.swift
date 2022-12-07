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

import SwiftUI

typealias EmojiPickerScreenViewModelType = StateStoreViewModel<EmojiPickerScreenViewState, EmojiPickerScreenViewAction>

class EmojiPickerScreenViewModel: EmojiPickerScreenViewModelType, EmojiPickerScreenViewModelProtocol {
    var callback: ((EmojiPickerScreenViewModelAction) -> Void)?
    
    private let emojiProvider: EmojiProviderProtocol
    
    init(emojiProvider: EmojiProviderProtocol) {
        let initialViewState = EmojiPickerScreenViewState(categories: [])
        self.emojiProvider = emojiProvider
        super.init(initialViewState: initialViewState)
        loadEmojis()
    }
    
    // MARK: - Public
    
    override func process(viewAction: EmojiPickerScreenViewAction) async {
        switch viewAction {
        case let .search(searchString: searchString):
            let categories = await emojiProvider.getCategories(searchString: searchString)
            state.categories = convert(emojiCategories: categories)
        case let .emojiTapped(emoji: emoji):
            callback?(.emojiSelected(emoji: emoji.value))
        }
    }
    
    // MARK: - Private

    private func loadEmojis() {
        Task(priority: .userInitiated) { [weak self] in
            let categories = await emojiProvider.getCategories(searchString: nil)
            self?.state.categories = convert(emojiCategories: categories)
        }
    }
    
    private func convert(emojiCategories: [EmojiCategory]) -> [EmojiPickerEmojiCategoryViewData] {
        emojiCategories.compactMap { emojiCategory in
            
            let emojisViewData: [EmojiPickerEmojiViewData] = emojiCategory.emojis.compactMap { emojiItem in
                
                guard let firstSkin = emojiItem.skins.first else {
                    return nil
                }
                return EmojiPickerEmojiViewData(id: emojiItem.id, value: firstSkin)
            }
            
            return EmojiPickerEmojiCategoryViewData(id: emojiCategory.id, emojis: emojisViewData)
        }
    }
}
