//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a manageAuthorizedSpaces remove this comment once generating the final file

import Combine
import SwiftUI

struct ManageAuthorizedSpacesScreenCoordinatorParameters {
    let authorizedSpacesSelection: AuthorizedSpacesSelection
    let mediaProvider: MediaProviderProtocol
}

enum ManageAuthorizedSpacesScreenCoordinatorAction {
    case dismiss
}

final class ManageAuthorizedSpacesScreenCoordinator: CoordinatorProtocol {
    private let viewModel: ManageAuthorizedSpacesScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ManageAuthorizedSpacesScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ManageAuthorizedSpacesScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ManageAuthorizedSpacesScreenCoordinatorParameters) {
        viewModel = ManageAuthorizedSpacesScreenViewModel(authorizedSpacesSelection: parameters.authorizedSpacesSelection,
                                                          mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ManageAuthorizedSpacesScreen(context: viewModel.context))
    }
}
