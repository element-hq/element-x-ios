//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SpacesScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let selectedSpacePublisher: CurrentValuePublisher<String?, Never>
    let appSettings: AppSettings
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SpacesScreenCoordinatorAction {
    case selectSpace(SpaceRoomListProxyProtocol)
    case showSettings
    case showCreateSpace
}

final class SpacesScreenCoordinator: CoordinatorProtocol {
    private let parameters: SpacesScreenCoordinatorParameters
    private let viewModel: SpacesScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SpacesScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpacesScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SpacesScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SpacesScreenViewModel(userSession: parameters.userSession,
                                          selectedSpacePublisher: parameters.selectedSpacePublisher,
                                          appSettings: parameters.appSettings,
                                          userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .selectSpace(let spaceRoomListProxy):
                actionsSubject.send(.selectSpace(spaceRoomListProxy))
            case .showSettings:
                actionsSubject.send(.showSettings)
            case .showCreateSpace:
                actionsSubject.send(.showCreateSpace)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpacesScreen(context: viewModel.context))
    }
}
