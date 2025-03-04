//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct CreateFeedScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
}

enum CreateFeedScreenCoordinatorAction {
    
}

final class CreateFeedScreenCoordinator: CoordinatorProtocol {
    private var viewModel: CreateFeedScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<CreateFeedScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<CreateFeedScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CreateFeedScreenCoordinatorParameters) {
        viewModel = CreateFeedScreenViewModel(clientProxy: parameters.userSession.clientProxy,
                                              mediaProvider: parameters.userSession.mediaProvider)
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
            }
            .store(in: &cancellables)
    }
            
    func toPresentable() -> AnyView {
        AnyView(CreateFeedScreen(context: viewModel.context))
    }
}
