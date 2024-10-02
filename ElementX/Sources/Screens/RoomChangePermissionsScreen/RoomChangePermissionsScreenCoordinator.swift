//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomChangePermissionsScreenCoordinatorParameters {
    let permissions: RoomPermissions
    let permissionsGroup: RoomRolesAndPermissionsScreenPermissionsGroup
    let roomProxy: JoinedRoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomChangePermissionsScreenCoordinatorAction {
    case complete
}

final class RoomChangePermissionsScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomChangePermissionsScreenCoordinatorParameters
    private var viewModel: RoomChangePermissionsScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomChangePermissionsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomChangePermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomChangePermissionsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomChangePermissionsScreenViewModel(currentPermissions: parameters.permissions,
                                                         group: parameters.permissionsGroup,
                                                         roomProxy: parameters.roomProxy,
                                                         userIndicatorController: parameters.userIndicatorController,
                                                         analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .complete:
                actionsSubject.send(.complete)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomChangePermissionsScreen(context: viewModel.context))
    }
}
