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

struct RoomMembersListScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let mediaProvider: MediaProviderProtocol
    let roomProxy: RoomProxyProtocol
}

enum RoomMembersListScreenCoordinatorAction {
    case invite
}

final class RoomMembersListScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomMembersListScreenCoordinatorParameters
    private var viewModel: RoomMembersListScreenViewModelProtocol
    private var navigationStackCoordinator: NavigationStackCoordinator? {
        parameters.navigationStackCoordinator
    }
    
    var callback: ((RoomMembersListScreenCoordinatorAction) -> Void)?
    
    init(parameters: RoomMembersListScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomMembersListScreenViewModel(roomProxy: parameters.roomProxy,
                                                   mediaProvider: parameters.mediaProvider,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case let .selectMember(member):
                self.selectMember(member)
            case .invite:
                callback?(.invite)
            }
        }
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomMembersListScreen(context: viewModel.context))
    }

    // MARK: - Private

    private func selectMember(_ member: RoomMemberProxyProtocol) {
        let parameters = RoomMemberDetailsScreenCoordinatorParameters(roomProxy: parameters.roomProxy,
                                                                      roomMemberProxy: member,
                                                                      mediaProvider: parameters.mediaProvider,
                                                                      userIndicatorController: ServiceLocator.shared.userIndicatorController)
        let coordinator = RoomMemberDetailsScreenCoordinator(parameters: parameters)

        navigationStackCoordinator?.push(coordinator)
    }
}
