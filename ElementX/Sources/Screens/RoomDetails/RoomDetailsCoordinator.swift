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

struct RoomDetailsCoordinatorParameters {
    let navigationStackCoordinator: NavigationStackCoordinator
    let roomProxy: RoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
}

enum RoomDetailsCoordinatorAction {
    case cancel
    case leftRoom
}

final class RoomDetailsCoordinator: CoordinatorProtocol {
    private let parameters: RoomDetailsCoordinatorParameters
    private var viewModel: RoomDetailsViewModelProtocol
    private var navigationStackCoordinator: NavigationStackCoordinator { parameters.navigationStackCoordinator }
    
    var callback: ((RoomDetailsCoordinatorAction) -> Void)?
    
    init(parameters: RoomDetailsCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomDetailsViewModel(roomProxy: parameters.roomProxy,
                                         mediaProvider: parameters.mediaProvider)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .requestMemberDetailsPresentation(let members):
                self.presentRoomMemberDetails(members)
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
    
    private func presentRoomMemberDetails(_ members: [RoomMemberProxy]) {
        let params = RoomMemberDetailsCoordinatorParameters(mediaProvider: parameters.mediaProvider,
                                                            members: members)
        let coordinator = RoomMemberDetailsCoordinator(parameters: params)
        coordinator.callback = { [weak self] _ in
            self?.navigationStackCoordinator.pop()
        }
        
        navigationStackCoordinator.push(coordinator)
    }
}
