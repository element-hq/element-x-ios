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

final class SessionVerificationCoordinator: CoordinatorProtocol {
    private let parameters: SessionVerificationCoordinatorParameters
    private var viewModel: SessionVerificationViewModelProtocol
    
    var callback: (() -> Void)?
    
    init(parameters: SessionVerificationCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SessionVerificationViewModel(sessionVerificationControllerProxy: parameters.sessionVerificationControllerProxy)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .finished:
                self.callback?()
            }
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(SessionVerificationScreen(context: viewModel.context))
    }
}
