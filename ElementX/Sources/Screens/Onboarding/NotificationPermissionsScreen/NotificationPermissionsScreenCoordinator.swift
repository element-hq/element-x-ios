//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct NotificationPermissionsScreenCoordinatorParameters {
    let notificationManager: NotificationManagerProtocol
}

enum NotificationPermissionsScreenCoordinatorAction {
    case done
}

final class NotificationPermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: NotificationPermissionsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationPermissionsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<NotificationPermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationPermissionsScreenCoordinatorParameters) {
        viewModel = NotificationPermissionsScreenViewModel(notificationManager: parameters.notificationManager)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    actionsSubject.send(.done)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NotificationPermissionsScreen(context: viewModel.context))
    }
}
