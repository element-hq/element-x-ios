//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
    case editPermissions(ownPowerLevel: RoomPowerLevel, permissions: RoomPermissions)
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
            case .editPermissions(let ownPowerLevel, let permissions):
                actionsSubject.send(.editPermissions(ownPowerLevel: ownPowerLevel, permissions: permissions))
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
