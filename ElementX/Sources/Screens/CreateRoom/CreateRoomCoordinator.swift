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

struct CreateRoomCoordinatorParameters {
    let userSession: UserSessionProtocol
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    let createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>
    let selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>
}

enum CreateRoomCoordinatorAction {
    case openRoom(withIdentifier: String)
    case deselectUser(UserProfileProxy)
    case updateDetails(CreateRoomFlowParameters)
}

final class CreateRoomCoordinator: CoordinatorProtocol {
    private let parameters: CreateRoomCoordinatorParameters
    private var viewModel: CreateRoomViewModelProtocol
    private let actionsSubject: PassthroughSubject<CreateRoomCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<CreateRoomCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CreateRoomCoordinatorParameters) {
        self.parameters = parameters
        viewModel = CreateRoomViewModel(userSession: parameters.userSession,
                                        userIndicatorController: parameters.userIndicatorController,
                                        createRoomParameters: parameters.createRoomParameters,
                                        selectedUsers: parameters.selectedUsers)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .deselectUser(let user):
                self.actionsSubject.send(.deselectUser(user))
            case .openRoom(let identifier):
                self.actionsSubject.send(.openRoom(withIdentifier: identifier))
            case .updateDetails(let details):
                self.actionsSubject.send(.updateDetails(details))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(CreateRoomScreen(context: viewModel.context))
    }
}
