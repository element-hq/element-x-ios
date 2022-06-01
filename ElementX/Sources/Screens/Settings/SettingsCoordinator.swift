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

struct SettingsCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let bugReportService: BugReportServiceProtocol
}

final class SettingsCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SettingsCoordinatorParameters
    private let settingsHostingController: UIViewController
    private var settingsViewModel: SettingsViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    
    // MARK: - Setup
    
    init(parameters: SettingsCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = SettingsViewModel()
        let view = Settings(context: viewModel.context)
        settingsViewModel = viewModel
        settingsHostingController = UIHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: settingsHostingController)

        settingsViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[SettingsCoordinator] SettingsViewModel did complete with result: \(result).")
            switch result {
            case .reportBug:
                self.presentBugReportScreen()
            case .crash:
                self.parameters.bugReportService.crash()
            }
        }
    }
    
    // MARK: - Public
    
    func start() {
        // no-op
    }
    
    func toPresentable() -> UIViewController {
        settingsHostingController
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }

    private func presentBugReportScreen() {
        let params = BugReportCoordinatorParameters(bugReportService: parameters.bugReportService,
                                                    screenshot: nil)
        let coordinator = BugReportCoordinator(parameters: params)
        coordinator.completion = { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .cancel:
                self.parameters.navigationRouter.popModule(animated: true)
            default:
                break
            }
        }

        add(childCoordinator: coordinator)
        coordinator.start()
        self.parameters.navigationRouter.push(coordinator, animated: true) { [weak self] in
            guard let self = self else { return }

            self.remove(childCoordinator: coordinator)
        }
    }
}
