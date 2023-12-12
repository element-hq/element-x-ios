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

struct AppLockScreenCoordinatorParameters {
    /// The service used to unlock the app.
    let appLockService: AppLockServiceProtocol
}

enum AppLockScreenCoordinatorAction {
    /// The user has successfully unlocked the app.
    case appUnlocked
    /// The user failed to unlock the app (or forgot their PIN).
    case forceLogout
}

final class AppLockScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AppLockScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AppLockScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AppLockScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AppLockScreenCoordinatorParameters) {
        viewModel = AppLockScreenViewModel(appLockService: parameters.appLockService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .appUnlocked:
                self.actionsSubject.send(.appUnlocked)
            case .forceLogout:
                self.actionsSubject.send(.forceLogout)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(AppLockScreen(context: viewModel.context))
    }
}
