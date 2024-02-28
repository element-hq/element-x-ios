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

import Combine
import SwiftUI

typealias RoomRolesAndPermissionsScreenViewModelType = StateStoreViewModel<RoomRolesAndPermissionsScreenViewState, RoomRolesAndPermissionsScreenViewAction>

class RoomRolesAndPermissionsScreenViewModel: RoomRolesAndPermissionsScreenViewModelType, RoomRolesAndPermissionsScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private var actionsSubject: PassthroughSubject<RoomRolesAndPermissionsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<RoomRolesAndPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: RoomRolesAndPermissionsScreenViewState())
        
        roomProxy.membersPublisher.sink { [weak self] members in
            self?.updateMembers(members)
        }
        .store(in: &cancellables)
        
        updateMembers(roomProxy.membersPublisher.value)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomRolesAndPermissionsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .editRoles(let role):
            actionsSubject.send(.editRoles(role))
        case .editPermissions(let permissionsGroup):
            actionsSubject.send(.editPermissions(permissionsGroup))
        case .reset:
            break
        }
    }
    
    // MARK: - Members
    
    private func updateMembers(_ members: [RoomMemberProxyProtocol]) {
        state.administratorCount = members.filter { $0.role == .administrator }.count
        state.moderatorCount = members.filter { $0.role == .moderator }.count
    }
}
