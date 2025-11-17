//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct StickerPickerScreenCoordinatorParameters {
    let stickerPackService: StickerPackServiceProtocol
    let clientProxy: ClientProxyProtocol
}

final class StickerPickerScreenCoordinator: CoordinatorProtocol {
    private var viewModel: StickerPickerScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<StickerPickerScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()

    var actions: AnyPublisher<StickerPickerScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: StickerPickerScreenCoordinatorParameters) {
        viewModel = StickerPickerScreenViewModel(stickerPackService: parameters.stickerPackService,
                                                  clientProxy: parameters.clientProxy)
    }

    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }

                switch action {
                case .stickerSelected(let sticker):
                    actionsSubject.send(.stickerSelected(sticker))
                case .cancel:
                    actionsSubject.send(.cancel)
                }
            }
            .store(in: &cancellables)
    }

    func toPresentable() -> AnyView {
        AnyView(StickerPickerScreen(context: viewModel.context))
    }
}
