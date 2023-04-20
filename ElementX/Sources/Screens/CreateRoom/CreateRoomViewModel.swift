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

typealias CreateRoomViewModelType = StateStoreViewModel<CreateRoomViewState, CreateRoomViewAction>

class CreateRoomViewModel: CreateRoomViewModelType, CreateRoomViewModelProtocol {
    private var actionsSubject: PassthroughSubject<CreateRoomViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(selectedUsers: [UserProfile]) {
        super.init(initialViewState: CreateRoomViewState(selectedUsers: selectedUsers))
    }
    
    // MARK: - Public
    
    override func process(viewAction: CreateRoomViewAction) {
        switch viewAction {
        case .createRoom:
            actionsSubject.send(.createRoom)
        case .deselectUser(let user):
            state.selectedUsers.removeAll(where: { $0.userID == user.userID })
        case .selectPrivateRoom:
            break
        case .selectPublicRoom:
            break
        }
    }
}
