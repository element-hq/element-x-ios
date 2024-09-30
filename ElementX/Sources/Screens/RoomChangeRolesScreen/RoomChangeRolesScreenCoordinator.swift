//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomChangeRolesScreenCoordinatorParameters {
    let mode: RoomMemberDetails.Role
    let roomProxy: JoinedRoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomChangeRolesScreenCoordinatorAction {
    case complete
}

final class RoomChangeRolesScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomChangeRolesScreenCoordinatorParameters
    private let viewModel: RoomChangeRolesScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<RoomChangeRolesScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomChangeRolesScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomChangeRolesScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomChangeRolesScreenViewModel(mode: parameters.mode,
                                                   roomProxy: parameters.roomProxy,
                                                   mediaProvider: parameters.mediaProvider,
                                                   userIndicatorController: parameters.userIndicatorController,
                                                   analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .complete:
                self.actionsSubject.send(.complete)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomChangeRolesScreen(context: viewModel.context))
    }
}
