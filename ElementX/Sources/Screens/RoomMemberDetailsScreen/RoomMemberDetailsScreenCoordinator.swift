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

struct RoomMemberDetailsScreenCoordinatorParameters {
    let userID: String
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum RoomMemberDetailsScreenCoordinatorAction {
    case openUserProfile
    case openDirectChat(roomID: String)
    case startCall(roomID: String)
}

final class RoomMemberDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomMemberDetailsScreenViewModelProtocol

    private let actionsSubject: PassthroughSubject<RoomMemberDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<RoomMemberDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: RoomMemberDetailsScreenCoordinatorParameters) {
        viewModel = RoomMemberDetailsScreenViewModel(userID: parameters.userID,
                                                     roomProxy: parameters.roomProxy,
                                                     clientProxy: parameters.clientProxy,
                                                     mediaProvider: parameters.mediaProvider,
                                                     userIndicatorController: parameters.userIndicatorController,
                                                     analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openUserProfile:
                actionsSubject.send(.openUserProfile)
            case .openDirectChat(let roomID):
                actionsSubject.send(.openDirectChat(roomID: roomID))
            case .startCall(let roomID):
                actionsSubject.send(.startCall(roomID: roomID))
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }

    func toPresentable() -> AnyView {
        AnyView(RoomMemberDetailsScreen(context: viewModel.context))
    }
}
