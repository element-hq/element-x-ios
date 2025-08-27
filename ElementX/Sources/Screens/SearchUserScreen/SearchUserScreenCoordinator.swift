//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SearchUserScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userDiscoveryService: UserDiscoveryServiceProtocol
    let appSettings: AppSettings
}

enum SearchUserScreenCoordinatorAction {
    case close
    case selectUser(UserProfileProxy)
}

final class SearchUserScreenCoordinator: CoordinatorProtocol {
    private let parameters: SearchUserScreenCoordinatorParameters
    private var viewModel: SearchUserScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<SearchUserScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
        
    var actions: AnyPublisher<SearchUserScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SearchUserScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SearchUserScreenViewModel(userSession: parameters.userSession,
                                             userDiscoveryService: parameters.userDiscoveryService,
                                             appSettings: ServiceLocator.shared.settings)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.close)
            case .selectUser(let user):
                actionsSubject.send(.selectUser(user))
            }
        }
        .store(in: &cancellables)
    }
        
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(SearchUserScreenView(context: viewModel.context))
    }
}
