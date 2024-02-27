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
}

enum RoomRolesAndPermissionsScreenCoordinatorAction {
    case editRoles(RoomRolesAndPermissionsScreenRole)
    case editPermissions(RoomRolesAndPermissionsScreenPermissionsGroup)
}

final class RoomRolesAndPermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomRolesAndPermissionsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<RoomRolesAndPermissionsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<RoomRolesAndPermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomRolesAndPermissionsScreenCoordinatorParameters) {
        viewModel = RoomRolesAndPermissionsScreenViewModel(roomProxy: parameters.roomProxy)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .editRoles(let role):
                actionsSubject.send(.editRoles(role))
            case .editPermissions(let permissionsGroup):
                actionsSubject.send(.editPermissions(permissionsGroup))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomRolesAndPermissionsScreen(context: viewModel.context))
    }
}
