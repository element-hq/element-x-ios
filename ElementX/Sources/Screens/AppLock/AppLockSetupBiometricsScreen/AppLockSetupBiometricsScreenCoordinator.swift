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

struct AppLockSetupBiometricsScreenCoordinatorParameters {
    let appLockService: AppLockServiceProtocol
}

enum AppLockSetupBiometricsScreenCoordinatorAction {
    case `continue`
}

final class AppLockSetupBiometricsScreenCoordinator: CoordinatorProtocol {
    private let parameters: AppLockSetupBiometricsScreenCoordinatorParameters
    private var viewModel: AppLockSetupBiometricsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AppLockSetupBiometricsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AppLockSetupBiometricsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AppLockSetupBiometricsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = AppLockSetupBiometricsScreenViewModel(appLockService: parameters.appLockService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .continue:
                self.actionsSubject.send(.continue)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(AppLockSetupBiometricsScreen(context: viewModel.context))
    }
}
