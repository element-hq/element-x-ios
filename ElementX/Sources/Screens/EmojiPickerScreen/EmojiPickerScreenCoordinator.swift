//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct EmojiPickerScreenCoordinatorParameters {
    let itemID: TimelineItemIdentifier
    let selectedEmojis: Set<String>
    let emojiProvider: EmojiProviderProtocol
    let timelineController: TimelineControllerProtocol
}

enum EmojiPickerScreenCoordinatorAction {
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
        
        viewModel = EmojiPickerScreenViewModel(itemID: parameters.itemID,
                                               selectedEmojis: parameters.selectedEmojis,
                                               emojiProvider: parameters.emojiProvider,
                                               timelineController: parameters.timelineController)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(EmojiPickerScreen(context: viewModel.context))
    }
}
