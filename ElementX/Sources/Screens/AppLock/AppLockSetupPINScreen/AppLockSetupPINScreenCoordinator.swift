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

struct AppLockSetupPINScreenCoordinatorParameters {
    /// Whether the screen should start in create or unlock mode.
    /// Specifying confirm here will raise a fatal error.
    let initialMode: AppLockSetupPINScreenMode
    /// Whether the screen is mandatory or can be cancelled by the user.
    let isMandatory: Bool
    let appLockService: AppLockServiceProtocol
}

enum AppLockSetupPINScreenCoordinatorAction {
    /// The user succeeded PIN entry.
    case complete
    /// The user cancelled PIN entry.
    case cancel
    /// The user failed to remember their PIN to unlock.
    case forceLogout
}

final class AppLockSetupPINScreenCoordinator: CoordinatorProtocol {
    private let parameters: AppLockSetupPINScreenCoordinatorParameters
    private var viewModel: AppLockSetupPINScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AppLockSetupPINScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AppLockSetupPINScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AppLockSetupPINScreenCoordinatorParameters) {
        guard parameters.initialMode != .confirm else { fatalError(".confirm is an invalid initial mode") }
        
        self.parameters = parameters
        viewModel = AppLockSetupPINScreenViewModel(initialMode: parameters.initialMode,
                                                   isMandatory: parameters.isMandatory,
                                                   appLockService: parameters.appLockService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .complete:
                actionsSubject.send(.complete)
            case .cancel:
                actionsSubject.send(.cancel)
            case .forceLogout:
                actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(AppLockSetupPINScreen(context: viewModel.context))
    }
}
