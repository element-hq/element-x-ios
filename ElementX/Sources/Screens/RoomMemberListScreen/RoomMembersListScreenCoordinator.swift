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

struct RoomMembersListScreenCoordinatorParameters {
    let roomProxy: RoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let networkMonitor: NetworkMonitorProtocol
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
                                                   networkMonitor: parameters.networkMonitor,
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
