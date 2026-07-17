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
    /// Any emojis that should be displayed as already selected.
    let selectedEmojis: Set<String>
    let emojiProvider: EmojiProviderProtocol
    /// A continuation that yields the selected emoji.
    let continuation: EmojiPickerScreenContinuation
}

enum EmojiPickerScreenCoordinatorAction {
    case dismiss
}

final class EmojiPickerScreenCoordinator: CoordinatorProtocol {
    private var viewModel: EmojiPickerScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<EmojiPickerScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<EmojiPickerScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EmojiPickerScreenCoordinatorParameters) {
        viewModel = EmojiPickerScreenViewModel(selectedEmojis: parameters.selectedEmojis,
                                               emojiProvider: parameters.emojiProvider,
                                               continuation: parameters.continuation)
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
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(EmojiPickerScreen(context: viewModel.context))
    }
}
