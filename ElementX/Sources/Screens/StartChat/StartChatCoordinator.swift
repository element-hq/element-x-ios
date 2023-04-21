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

struct StartChatCoordinatorParameters {
    let userSession: UserSessionProtocol
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    let navigationStackCoordinator: NavigationStackCoordinator?
    let userDiscoveryService: UserDiscoveryServiceProtocol
}

enum StartChatCoordinatorAction {
    case close
    case openRoom(withIdentifier: String)
}

final class StartChatCoordinator: CoordinatorProtocol {
    private let parameters: StartChatCoordinatorParameters
    private var viewModel: StartChatViewModelProtocol
    private let actionsSubject: PassthroughSubject<StartChatCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<StartChatCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: StartChatCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StartChatViewModel(userSession: parameters.userSession, userIndicatorController: parameters.userIndicatorController, userDiscoveryService: parameters.userDiscoveryService)
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
        let inviteParameters = InviteUsersCoordinatorParameters(userSession: parameters.userSession, userDiscoveryService: parameters.userDiscoveryService)
        let coordinator = InviteUsersCoordinator(parameters: inviteParameters)
        coordinator.actions.sink { [weak self] result in
            switch result {
            case .close:
                self?.parameters.navigationStackCoordinator?.pop()
            }
        }
        .store(in: &cancellables)
        parameters.navigationStackCoordinator?.push(coordinator)
    }
}
