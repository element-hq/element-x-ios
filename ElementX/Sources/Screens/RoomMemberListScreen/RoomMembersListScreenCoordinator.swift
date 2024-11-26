//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomMembersListScreenCoordinatorParameters {
    let mediaProvider: MediaProviderProtocol
    let roomProxy: JoinedRoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomMembersListScreenCoordinatorAction {
    case invite
    case selectedMember(RoomMemberProxyProtocol)
}

final class RoomMembersListScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomMembersListScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<RoomMembersListScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<RoomMembersListScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomMembersListScreenCoordinatorParameters) {
        viewModel = RoomMembersListScreenViewModel(roomProxy: parameters.roomProxy,
                                                   mediaProvider: parameters.mediaProvider,
                                                   userIndicatorController: parameters.userIndicatorController,
                                                   analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case let .selectMember(member):
                    actionsSubject.send(.selectedMember(member))
                case .invite:
                    actionsSubject.send(.invite)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomMembersListScreen(context: viewModel.context))
    }
}
