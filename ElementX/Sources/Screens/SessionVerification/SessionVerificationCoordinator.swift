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

struct SessionVerificationCoordinatorParameters {
    let sessionVerificationControllerProxy: SessionVerificationControllerProxyProtocol
}

final class SessionVerificationCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SessionVerificationCoordinatorParameters
    private let sessionVerificationHostingController: UIViewController
    private var sessionVerificationViewModel: SessionVerificationViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SessionVerificationCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = SessionVerificationViewModel(sessionVerificationControllerProxy: parameters.sessionVerificationControllerProxy)
        let view = SessionVerificationScreen(context: viewModel.context)
        sessionVerificationViewModel = viewModel
        sessionVerificationHostingController = UIHostingController(rootView: view)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("Did start.")
        sessionVerificationViewModel.callback = { [weak self] action in
            guard let self = self else { return }
            
            switch action {
            case .finished:
                self.callback?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        sessionVerificationHostingController
    }

    func stop() { }
}
