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

struct InviteUsersCoordinatorParameters {
    let userSession: UserSessionProtocol
    let usersProvider: UsersProviderProtocol
}

enum InviteUsersCoordinatorAction {
    case close
}

final class InviteUsersCoordinator: CoordinatorProtocol {
    private let parameters: InviteUsersCoordinatorParameters
    private let viewModel: InviteUsersViewModelProtocol
    private let actionsSubject: PassthroughSubject<InviteUsersCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<InviteUsersCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: InviteUsersCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = InviteUsersViewModel(userSession: parameters.userSession, usersProvider: parameters.usersProvider)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.actionsSubject.send(.close)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(InviteUsersScreen(context: viewModel.context))
    }
}
