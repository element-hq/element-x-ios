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

struct UserProfileScreenCoordinatorParameters {
    let userID: String
    let isPresentedModally: Bool
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let networkMonitor: NetworkMonitorProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let analytics: AnalyticsService
}

enum UserProfileScreenCoordinatorAction {
    case openDirectChat(roomID: String)
    case startCall(roomID: String)
    case dismiss
}

final class UserProfileScreenCoordinator: CoordinatorProtocol {
    private var viewModel: UserProfileScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<UserProfileScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserProfileScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: UserProfileScreenCoordinatorParameters) {
        viewModel = UserProfileScreenViewModel(userID: parameters.userID,
                                               isPresentedModally: parameters.isPresentedModally,
                                               clientProxy: parameters.clientProxy,
                                               mediaProvider: parameters.mediaProvider,
                                               networkMonitor: parameters.networkMonitor,
                                               userIndicatorController: parameters.userIndicatorController,
                                               analytics: parameters.analytics)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .openDirectChat(let roomID):
                actionsSubject.send(.openDirectChat(roomID: roomID))
            case .startCall(let roomID):
                actionsSubject.send(.startCall(roomID: roomID))
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(UserProfileScreen(context: viewModel.context))
    }
}
