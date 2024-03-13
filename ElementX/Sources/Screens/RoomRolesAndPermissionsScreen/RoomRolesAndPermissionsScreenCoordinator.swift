//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

// periphery:ignore:all - this is just a roomRolesAndPermissions remove this comment once generating the final file

import Combine
import SwiftUI

struct RoomRolesAndPermissionsScreenCoordinatorParameters {
    let roomProxy: RoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
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
                                                           userIndicatorController: parameters.userIndicatorController)
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
