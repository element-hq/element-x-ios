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

import Combine
import SwiftUI

struct EmojiPickerScreenCoordinatorParameters {
    let emojiProvider: EmojiProviderProtocol
    let itemID: TimelineItemIdentifier
    let selectedEmojis: Set<String>
}

enum EmojiPickerScreenCoordinatorAction {
    case emojiSelected(emoji: String, itemID: TimelineItemIdentifier)
    case dismiss
}

final class EmojiPickerScreenCoordinator: CoordinatorProtocol {
    private let parameters: EmojiPickerScreenCoordinatorParameters
    private var viewModel: EmojiPickerScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<EmojiPickerScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<EmojiPickerScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EmojiPickerScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = EmojiPickerScreenViewModel(emojiProvider: parameters.emojiProvider)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case let .emojiSelected(emoji: emoji):
                    actionsSubject.send(.emojiSelected(emoji: emoji, itemID: self.parameters.itemID))
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(EmojiPickerScreen(context: viewModel.context, selectedEmojis: parameters.selectedEmojis))
    }
}
