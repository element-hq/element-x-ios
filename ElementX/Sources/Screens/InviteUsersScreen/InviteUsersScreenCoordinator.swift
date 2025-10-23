//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct InviteUsersScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>?
    let roomType: InviteUsersScreenRoomType
    let userDiscoveryService: UserDiscoveryServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
}

enum InviteUsersScreenCoordinatorAction {
    case dismiss
    case proceed(selectedUsers: [UserProfileProxy])
}

final class InviteUsersScreenCoordinator: CoordinatorProtocol {
    private let viewModel: InviteUsersScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<InviteUsersScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<InviteUsersScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: InviteUsersScreenCoordinatorParameters) {
        viewModel = InviteUsersScreenViewModel(userSession: parameters.userSession,
                                               selectedUsers: parameters.selectedUsers,
                                               roomType: parameters.roomType,
                                               userDiscoveryService: parameters.userDiscoveryService,
                                               userIndicatorController: parameters.userIndicatorController,
                                               appSettings: parameters.appSettings)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            case .proceed(let selectedUsers):
                actionsSubject.send(.proceed(selectedUsers: selectedUsers))
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(InviteUsersScreen(context: viewModel.context))
    }
}
