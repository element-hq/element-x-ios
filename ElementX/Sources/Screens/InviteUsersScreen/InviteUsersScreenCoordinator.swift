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

struct InviteUsersScreenCoordinatorParameters {
    let selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>
    let roomType: InviteUsersScreenRoomType
    let mediaProvider: MediaProviderProtocol
    let userDiscoveryService: UserDiscoveryServiceProtocol
    weak var userIndicatorController: UserIndicatorControllerProtocol?
}

enum InviteUsersScreenCoordinatorAction {
    case cancel
    case proceed
    case invite(users: [String])
    case toggleUser(UserProfileProxy)
}

final class InviteUsersScreenCoordinator: CoordinatorProtocol {
    private let parameters: InviteUsersScreenCoordinatorParameters
    private let viewModel: InviteUsersScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<InviteUsersScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<InviteUsersScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: InviteUsersScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = InviteUsersScreenViewModel(selectedUsers: parameters.selectedUsers,
                                               roomType: parameters.roomType,
                                               mediaProvider: parameters.mediaProvider,
                                               userDiscoveryService: parameters.userDiscoveryService,
                                               appSettings: ServiceLocator.shared.settings,
                                               userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                actionsSubject.send(.cancel)
            case .proceed:
                actionsSubject.send(.proceed)
            case .invite(let users):
                actionsSubject.send(.invite(users: users))
            case .toggleUser(let user):
                actionsSubject.send(.toggleUser(user))
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(InviteUsersScreen(context: viewModel.context))
    }
}
