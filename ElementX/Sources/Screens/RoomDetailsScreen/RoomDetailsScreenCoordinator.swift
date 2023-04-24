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

import SwiftUI

struct RoomDetailsScreenCoordinatorParameters {
    let navigationStackCoordinator: NavigationStackCoordinator
    let roomProxy: RoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
}

enum RoomDetailsScreenCoordinatorAction {
    case cancel
    case leftRoom
}

final class RoomDetailsScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomDetailsScreenCoordinatorParameters
    private var viewModel: RoomDetailsScreenViewModelProtocol
    private var navigationStackCoordinator: NavigationStackCoordinator { parameters.navigationStackCoordinator }
    
    var callback: ((RoomDetailsScreenCoordinatorAction) -> Void)?
    
    init(parameters: RoomDetailsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomDetailsScreenViewModel(roomProxy: parameters.roomProxy,
                                               mediaProvider: parameters.mediaProvider)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .requestMemberDetailsPresentation(let members):
                self.presentRoomMembersList(members)
            case .cancel:
                self.callback?(.cancel)
            case .leftRoom:
                self.callback?(.leftRoom)
            }
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomDetailsScreen(context: viewModel.context))
    }
    
    private func presentRoomMembersList(_ members: [RoomMemberProxyProtocol]) {
        let params = RoomMembersListScreenCoordinatorParameters(navigationStackCoordinator: navigationStackCoordinator,
                                                                mediaProvider: parameters.mediaProvider,
                                                                members: members)
        let coordinator = RoomMembersListScreenCoordinator(parameters: params)
        
        navigationStackCoordinator.push(coordinator)
    }
}
