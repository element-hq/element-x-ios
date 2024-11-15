//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

// periphery:ignore:all - this is just a knockRequestsList remove this comment once generating the final file

import Combine
import SwiftUI

struct KnockRequestsListScreenCoordinatorParameters { }

enum KnockRequestsListScreenCoordinatorAction {
    case done
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

final class KnockRequestsListScreenCoordinator: CoordinatorProtocol {
    private let parameters: KnockRequestsListScreenCoordinatorParameters
    private let viewModel: KnockRequestsListScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<KnockRequestsListScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<KnockRequestsListScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: KnockRequestsListScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = KnockRequestsListScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .done:
                actionsSubject.send(.done)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(KnockRequestsListScreen(context: viewModel.context))
    }
}
