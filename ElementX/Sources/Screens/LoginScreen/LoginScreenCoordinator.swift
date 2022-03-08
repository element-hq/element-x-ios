//
// Copyright 2021 New Vector Ltd
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

struct LoginScreenCoordinatorParameters {
    
}

final class LoginScreenCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: LoginScreenCoordinatorParameters
    private let loginScreenHostingController: UIViewController
    private var loginScreenViewModel: LoginScreenViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: ((LoginScreenViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: LoginScreenCoordinatorParameters) {
        self.parameters = parameters
        
        loginScreenViewModel = LoginScreenViewModel()
        let view = LoginScreen(context: loginScreenViewModel.context)
        
        loginScreenHostingController = UIHostingController(rootView: view)
        loginScreenHostingController.isModalInPresentation = true
        
        loginScreenViewModel.completion = { [weak self] result in
            MXLog.debug("[LoginScreenCoordinator] LoginScreenViewModel did complete.")
            guard let self = self else { return }
            self.completion?(result)
        }
    }
    
    // MARK: - Public
    func start() {
        
    }
    
    func toPresentable() -> UIViewController {
        return self.loginScreenHostingController
    }
}
