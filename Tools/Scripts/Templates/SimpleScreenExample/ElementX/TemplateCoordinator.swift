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

struct TemplateCoordinatorParameters {
    let promptType: TemplatePromptType
}

enum TemplateCoordinatorAction {
    case accept
    case cancel
}

final class TemplateCoordinator: CoordinatorProtocol {
    private let parameters: TemplateCoordinatorParameters
    private var viewModel: TemplateViewModelProtocol
    
    var callback: ((TemplateCoordinatorAction) -> Void)?
    
    init(parameters: TemplateCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = TemplateViewModel(promptType: parameters.promptType)
    }
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            MXLog.debug("TemplateViewModel did complete with result: \(action).")
            switch action {
            case .accept:
                self.callback?(.accept)
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }
        
    func toPresentable() -> AnyView {
        AnyView(TemplateScreen(context: viewModel.context))
    }
}
