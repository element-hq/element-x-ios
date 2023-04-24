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

final class AnalyticsPromptScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AnalyticsPromptScreenViewModel

    var callback: (@MainActor () -> Void)?
    
    init() {
        viewModel = AnalyticsPromptScreenViewModel()
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] result in
            guard let self else { return }
            
            switch result {
            case .enable:
                MXLog.info("Enable Analytics")
                ServiceLocator.shared.analytics.optIn()
                self.callback?()
            case .disable:
                MXLog.info("Disable Analytics")
                ServiceLocator.shared.analytics.optOut()
                self.callback?()
            }
        }
    }
    
    func toPresentable() -> AnyView {
        AnyView(AnalyticsPromptScreen(context: viewModel.context))
    }
}
