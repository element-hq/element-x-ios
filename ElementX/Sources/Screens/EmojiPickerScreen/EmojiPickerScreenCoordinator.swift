//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    private var cancellables = Set<AnyCancellable>()
    
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
