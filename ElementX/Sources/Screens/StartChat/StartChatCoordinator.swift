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

import SwiftUI

struct StartChatCoordinatorParameters {
    let userSession: UserSessionProtocol
    weak var userIndicatorController: UserIndicatorControllerProtocol?
    let navigationStackCoordinator: NavigationStackCoordinator?
}

enum StartChatCoordinatorAction {
    case close
    case openRoom(withIdentifier: String)
}

final class StartChatCoordinator: CoordinatorProtocol {
    private let parameters: StartChatCoordinatorParameters
    private var viewModel: StartChatViewModelProtocol
    
    var callback: ((StartChatCoordinatorAction) -> Void)?
    
    init(parameters: StartChatCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StartChatViewModel(userSession: parameters.userSession, userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.callback?(.close)
            case .createRoom:
                self.presentInviteUsersScreen()
            case .openRoom(let identifier):
                self.callback?(.openRoom(withIdentifier: identifier))
            }
        }
    }
        
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(StartChatScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentInviteUsersScreen() {
        let params = InviteUsersInRoomCoordinatorParameters()
        let coordinator = InviteUsersInRoomCoordinator(parameters: params)
        coordinator.callback = { [weak self] result in
            switch result {
            case .close:
                self?.parameters.navigationStackCoordinator?.pop()
            }
        }
        parameters.navigationStackCoordinator?.push(coordinator)
    }
}
