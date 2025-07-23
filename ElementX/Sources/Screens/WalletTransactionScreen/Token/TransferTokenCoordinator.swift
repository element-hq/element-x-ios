//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct TransferTokenCoordinatorParams {
    let meowPrice: ZeroCurrency?
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum TransferTokenCoordinatorAction {
    case transactionCompleted
    case finished
}

final class TransferTokenCoordinator: CoordinatorProtocol {
    private var viewModel: TransferTokenViewModel
    
    private let actionsSubject: PassthroughSubject<TransferTokenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    var actions: AnyPublisher<TransferTokenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: TransferTokenCoordinatorParams) {
        viewModel = TransferTokenViewModel(meowPrice: parameters.meowPrice,
                                           clientProxy: parameters.clientProxy,
                                           mediaProvider: parameters.mediaProvider,
                                           userIndicatorController: parameters.userIndicatorController)
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .transactionCompleted:
                    actionsSubject.send(.transactionCompleted)
                case .finished:
                    actionsSubject.send(.finished)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(TransferTokenView(context: viewModel.context))
    }
}
