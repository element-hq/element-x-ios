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
    private let createRoomParameters: CreateRoomVolatileParameters
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol, createRoomParameters: CreateRoomVolatileParameters) {
        let bindings = CreateRoomViewStateBindings(roomName: createRoomParameters.name, roomTopic: createRoomParameters.topic, isRoomPrivate: createRoomParameters.isRoomPrivate)
        self.createRoomParameters = createRoomParameters
        super.init(initialViewState: CreateRoomViewState(selectedUsers: createRoomParameters.selectedUsers, bindings: bindings), imageProvider: userSession.mediaProvider)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: CreateRoomViewAction) {
        switch viewAction {
        case .createRoom:
            actionsSubject.send(.createRoom)
        case .deselectUser(let user):
            state.selectedUsers.removeAll(where: { $0.userID == user.userID })
            actionsSubject.send(.deselectUser(user))
        case .selectPrivateRoom:
            state.bindings.isRoomPrivate = true
        case .selectPublicRoom:
            state.bindings.isRoomPrivate = false
        }
    }
    
    // MARK: - Private

    private func setupBindings() {
        context.$viewState
            .map(\.bindings)
            .sink { [weak self] bindings in
                self?.createRoomParameters.name = bindings.roomName
                self?.createRoomParameters.topic = bindings.roomTopic
                self?.createRoomParameters.isRoomPrivate = bindings.isRoomPrivate
            }
            .store(in: &cancellables)
    }
}
