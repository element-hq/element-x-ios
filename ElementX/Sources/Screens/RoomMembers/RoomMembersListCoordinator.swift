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

struct RoomMembersListCoordinatorParameters {
    let navigationStackCoordinator: NavigationStackCoordinator
    let mediaProvider: MediaProviderProtocol
    let members: [RoomMemberProxyProtocol]
}

enum RoomMembersListCoordinatorAction { }

final class RoomMembersListCoordinator: CoordinatorProtocol {
    private let parameters: RoomMembersListCoordinatorParameters
    private var viewModel: RoomMembersListViewModelProtocol
    private var navigationStackCoordinator: NavigationStackCoordinator { parameters.navigationStackCoordinator }
    
    var callback: ((RoomMembersListCoordinatorAction) -> Void)?
    
    init(parameters: RoomMembersListCoordinatorParameters) {
        self.parameters = parameters

        viewModel = RoomMembersListViewModel(mediaProvider: parameters.mediaProvider,
                                             members: parameters.members)
    }
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case let .selectMember(member):
                self.selectMember(member)
            }
        }
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomMembersListScreen(context: viewModel.context))
    }

    // MARK: - Private

    private func selectMember(_ member: RoomMemberProxyProtocol) {
        let parameters = RoomMemberDetailsCoordinatorParameters(roomMemberProxy: member, mediaProvider: parameters.mediaProvider)
        let coordinator = RoomMemberDetailsCoordinator(parameters: parameters)

        navigationStackCoordinator.push(coordinator)
    }
}
