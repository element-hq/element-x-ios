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

struct StartChatScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    let navigationStackCoordinator: NavigationStackCoordinator?
    let userDiscoveryService: UserDiscoveryServiceProtocol
}

enum StartChatScreenCoordinatorAction {
    case close
    case openRoom(withIdentifier: String)
}

final class StartChatScreenCoordinator: CoordinatorProtocol {
    private let parameters: StartChatScreenCoordinatorParameters
    private var viewModel: StartChatScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<StartChatScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    private var createRoomParameters = CurrentValueSubject<CreateRoomFlowParameters, Never>(.init())
    private var createRoomParametersPublisher: CurrentValuePublisher<CreateRoomFlowParameters, Never> {
        createRoomParameters.asCurrentValuePublisher()
    }
    
    private let selectedUsers = CurrentValueSubject<[UserProfile], Never>([])
    private var selectedUsersPublisher: CurrentValuePublisher<[UserProfile], Never> {
        selectedUsers.asCurrentValuePublisher()
    }
    
    var actions: AnyPublisher<StartChatScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: StartChatScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StartChatScreenViewModel(userSession: parameters.userSession, userIndicatorController: parameters.userIndicatorController, userDiscoveryService: parameters.userDiscoveryService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.actionsSubject.send(.close)
            case .createRoom:
                // before creating a room we select the users we would like to invite in that room
                self.presentInviteUsersScreen()
            case .openRoom(let identifier):
                self.actionsSubject.send(.openRoom(withIdentifier: identifier))
            }
        }
        .store(in: &cancellables)
    }
        
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(StartChatScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentInviteUsersScreen() {
        let inviteParameters = InviteUsersScreenCoordinatorParameters(selectedUsers: selectedUsersPublisher,
                                                                      roomContext: .draftRoom,
                                                                      mediaProvider: parameters.userSession.mediaProvider,
                                                                      userDiscoveryService: parameters.userDiscoveryService)
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        coordinator.actions.sink { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .close:
                parameters.navigationStackCoordinator?.pop()
            case .proceed:
                openCreateRoomScreen()
            case .toggleUser(let user):
                toggleUser(user)
            }
        }
        .store(in: &cancellables)
        
        parameters.navigationStackCoordinator?.push(coordinator) { [weak self] in
            self?.createRoomParameters.send(.init())
            self?.selectedUsers.send([])
        }
    }
    
    private func openCreateRoomScreen() {
        let createParameters = CreateRoomCoordinatorParameters(userSession: parameters.userSession,
                                                               createRoomParameters: createRoomParametersPublisher,
                                                               selectedUsers: selectedUsersPublisher)
        let coordinator = CreateRoomCoordinator(parameters: createParameters)
        coordinator.actions.sink { [weak self] result in
            switch result {
            case .deselectUser(let user):
                self?.toggleUser(user)
            case .updateDetails(let details):
                self?.createRoomParameters.send(details)
            case .createRoom:
                break
            }
        }
        .store(in: &cancellables)
        
        parameters.navigationStackCoordinator?.push(coordinator)
    }
    
    // MARK: - Private
    
    private func toggleUser(_ user: UserProfile) {
        var selectedUsers = selectedUsers.value
        if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        self.selectedUsers.send(selectedUsers)
    }
}
