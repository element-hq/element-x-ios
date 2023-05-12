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
    private var createRoomParameters: CreateRoomFlowParameters
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>,
         selectedUsers: CurrentValuePublisher<[UserProfile], Never>) {
        let parameters = createRoomParameters.value
        self.createRoomParameters = parameters
        let bindings = CreateRoomViewStateBindings(roomName: parameters.name, roomTopic: parameters.topic, isRoomPrivate: parameters.isRoomPrivate)

        super.init(initialViewState: CreateRoomViewState(selectedUsers: selectedUsers.value, bindings: bindings), imageProvider: userSession.mediaProvider)
        
        selectedUsers
            .sink { [weak self] users in
                self?.state.selectedUsers = users
            }
            .store(in: &cancellables)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: CreateRoomViewAction) {
        switch viewAction {
        case .createRoom:
            actionsSubject.send(.createRoom)
        case .deselectUser(let user):
            actionsSubject.send(.deselectUser(user))
        }
    }
    
    // MARK: - Private

    private func setupBindings() {
        context.$viewState
            .map(\.bindings)
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] bindings in
                guard let self else { return }
                createRoomParameters.name = bindings.roomName
                createRoomParameters.topic = bindings.roomTopic
                createRoomParameters.isRoomPrivate = bindings.isRoomPrivate
                actionsSubject.send(.updateDetails(createRoomParameters))
            }
            .store(in: &cancellables)
    }
}
