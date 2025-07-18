//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ReceiveTransactionCoordinatorParams {
    let clientProxy: ClientProxyProtocol
}

enum ReceiveTransactionCoordinatorAction {
    case finish
}

final class ReceiveTransactionCoordinator: CoordinatorProtocol {
    private var viewModel: ReceiveTransactionViewModel
    
    private let actionsSubject: PassthroughSubject<ReceiveTransactionCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    var actions: AnyPublisher<ReceiveTransactionCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ReceiveTransactionCoordinatorParams) {
        viewModel = ReceiveTransactionViewModel(clientProxy: parameters.clientProxy)
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .finish:
                    actionsSubject.send(.finish)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(ReceiveTransactionView(context: viewModel.context))
    }
}
