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

final class TemplateCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TemplateCoordinatorParameters
    private let templateHostingController: UIViewController
    private var templateViewModel: TemplateViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var activityIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((TemplateCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: TemplateCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = TemplateViewModel(promptType: parameters.promptType)
        let view = TemplateScreen(context: viewModel.context)
        templateViewModel = viewModel
        templateHostingController = UIHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: templateHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("Did start.")
        templateViewModel.callback = { [weak self] action in
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
    
    func toPresentable() -> UIViewController {
        templateHostingController
    }

    func stop() {
        stopLoading()
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
        activityIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        activityIndicator = nil
    }
}
