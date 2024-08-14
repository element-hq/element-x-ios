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

struct JoinRoomScreenCoordinatorParameters {
    let roomID: String
    let via: [String]
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let networkMonitor: NetworkMonitorProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum JoinRoomScreenCoordinatorAction {
    case joined
    case cancelled
}

final class JoinRoomScreenCoordinator: CoordinatorProtocol {
    private let viewModel: JoinRoomScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<JoinRoomScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<JoinRoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: JoinRoomScreenCoordinatorParameters) {
        viewModel = JoinRoomScreenViewModel(roomID: parameters.roomID,
                                            via: parameters.via,
                                            clientProxy: parameters.clientProxy,
                                            mediaProvider: parameters.mediaProvider,
                                            networkMonitor: parameters.networkMonitor,
                                            userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .joined:
                actionsSubject.send(.joined)
            case .cancelled:
                actionsSubject.send(.cancelled)
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(JoinRoomScreen(context: viewModel.context))
    }
}
