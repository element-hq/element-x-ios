//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct InviteUsersScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>
    let roomType: InviteUsersScreenRoomType
    let mediaProvider: MediaProviderProtocol
    let userDiscoveryService: UserDiscoveryServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum InviteUsersScreenCoordinatorAction {
    case cancel
    case proceed
    case invite(users: [String])
    case toggleUser(UserProfileProxy)
}

final class InviteUsersScreenCoordinator: CoordinatorProtocol {
    private let viewModel: InviteUsersScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<InviteUsersScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<InviteUsersScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: InviteUsersScreenCoordinatorParameters) {
        viewModel = InviteUsersScreenViewModel(clientProxy: parameters.clientProxy,
                                               selectedUsers: parameters.selectedUsers,
                                               roomType: parameters.roomType,
                                               mediaProvider: parameters.mediaProvider,
                                               userDiscoveryService: parameters.userDiscoveryService,
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
