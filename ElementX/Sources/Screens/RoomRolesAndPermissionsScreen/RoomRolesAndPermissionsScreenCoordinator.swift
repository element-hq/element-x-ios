//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomRolesAndPermissionsScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomRolesAndPermissionsScreenCoordinatorAction {
    case editRoles(RoomRolesAndPermissionsScreenRole)
    case editPermissions(permissions: RoomPermissions, group: RoomRolesAndPermissionsScreenPermissionsGroup)
    case demotedOwnUser
}

final class RoomRolesAndPermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomRolesAndPermissionsScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomRolesAndPermissionsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomRolesAndPermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomRolesAndPermissionsScreenCoordinatorParameters) {
        viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: parameters.roomProxy,
                                                           userIndicatorController: parameters.userIndicatorController,
                                                           analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .editRoles(let role):
                actionsSubject.send(.editRoles(role))
            case .editPermissions(let permissions, let group):
                actionsSubject.send(.editPermissions(permissions: permissions, group: group))
            case .demotedOwnUser:
                actionsSubject.send(.demotedOwnUser)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomRolesAndPermissionsScreen(context: viewModel.context))
    }
}
