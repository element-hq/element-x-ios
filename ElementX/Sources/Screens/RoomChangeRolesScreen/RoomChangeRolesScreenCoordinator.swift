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
