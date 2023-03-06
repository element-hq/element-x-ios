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

struct StartChatCoordinatorParameters {
    let userSession: UserSessionProtocol
}

enum StartChatCoordinatorAction {
    case close
}

final class StartChatCoordinator: CoordinatorProtocol {
    private let parameters: StartChatCoordinatorParameters
    private var viewModel: StartChatViewModelProtocol
    
    var callback: ((StartChatCoordinatorAction) -> Void)?
    
    init(parameters: StartChatCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StartChatViewModel(withUserSession: parameters.userSession)
    }
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.callback?(.close)
            case .createRoom:
                // TODO: start create room flow
                break
            }
        }
    }
        
    func toPresentable() -> AnyView {
        AnyView(StartChatScreen(context: viewModel.context))
    }
}
