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

struct ReportContentCoordinatorParameters {
    let promptType: ReportContentPromptType
}

enum ReportContentCoordinatorAction {
    case accept
    case cancel
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

final class ReportContentCoordinator: CoordinatorProtocol {
    private let parameters: ReportContentCoordinatorParameters
    private var viewModel: ReportContentViewModelProtocol
    
    var callback: ((ReportContentCoordinatorAction) -> Void)?
    
    init(parameters: ReportContentCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ReportContentViewModel(promptType: parameters.promptType)
    }
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .accept:
                MXLog.info("User accepted the prompt.")
                self.callback?(.accept)
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }
        
    func toPresentable() -> AnyView {
        AnyView(ReportContentScreen(context: viewModel.context))
    }
}
