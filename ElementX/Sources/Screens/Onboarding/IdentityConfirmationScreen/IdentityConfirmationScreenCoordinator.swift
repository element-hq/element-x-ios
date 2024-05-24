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

// periphery:ignore:all - this is just a identityConfirmation remove this comment once generating the final file

import Combine
import SwiftUI

struct IdentityConfirmationScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let appSettings: AppSettings
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum IdentityConfirmationScreenCoordinatorAction {
    case otherDevice
    case recoveryKey
    /// Only possible in debug builds.
    case skip
    case reset
}

final class IdentityConfirmationScreenCoordinator: CoordinatorProtocol {
    private let parameters: IdentityConfirmationScreenCoordinatorParameters
    private let viewModel: IdentityConfirmationScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<IdentityConfirmationScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<IdentityConfirmationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: IdentityConfirmationScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = IdentityConfirmationScreenViewModel(userSession: parameters.userSession,
                                                        appSettings: parameters.appSettings,
                                                        userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            MXLog.info("Coordinator: received view model action: \(action)")
            switch action {
            case .otherDevice:
                actionsSubject.send(.otherDevice)
            case .recoveryKey:
                actionsSubject.send(.recoveryKey)
            case .skip:
                actionsSubject.send(.skip)
            case .reset:
                actionsSubject.send(.reset)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(IdentityConfirmationScreen(context: viewModel.context))
    }
}
