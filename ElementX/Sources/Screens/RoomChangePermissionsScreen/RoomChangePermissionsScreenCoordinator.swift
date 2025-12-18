//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomChangePermissionsScreenCoordinatorParameters {
    let ownPowerLevel: RoomPowerLevel
    let permissions: RoomPermissions
    let roomProxy: JoinedRoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomChangePermissionsScreenCoordinatorAction {
    case complete
}

final class RoomChangePermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomChangePermissionsScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomChangePermissionsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomChangePermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomChangePermissionsScreenCoordinatorParameters) {
        viewModel = RoomChangePermissionsScreenViewModel(currentPermissions: parameters.permissions,
                                                         ownPowerLevel: parameters.ownPowerLevel,
                                                         roomProxy: parameters.roomProxy,
                                                         userIndicatorController: parameters.userIndicatorController,
                                                         analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .complete:
                actionsSubject.send(.complete)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomChangePermissionsScreen(context: viewModel.context))
    }
}
