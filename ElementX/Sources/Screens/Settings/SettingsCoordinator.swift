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

struct SettingsCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let userSession: UserSessionProtocol
    let bugReportService: BugReportServiceProtocol
}

enum SettingsCoordinatorAction {
    case dismiss
    case logout
}

final class SettingsCoordinator: Coordinator, Presentable {
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: SettingsCoordinatorParameters
    private let settingsHostingController: UIViewController
    private var settingsViewModel: SettingsViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var statusIndicator: UserIndicator?

    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((SettingsCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SettingsCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = SettingsViewModel(withUserSession: parameters.userSession)
        let view = SettingsScreen(context: viewModel.context)
        settingsViewModel = viewModel
        settingsHostingController = UIHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: settingsHostingController)

        settingsViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("SettingsViewModel did complete with result: \(result).")
            switch result {
            case .close:
                self.callback?(.dismiss)
            case .toggleAnalytics:
                self.toggleAnalytics()
            case .reportBug:
                self.presentBugReportScreen()
            case .crash:
                self.parameters.bugReportService.crash()
            case .logout:
                self.confirmSignOut()
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
    
    private func toggleAnalytics() {
        if ElementSettings.shared.enableAnalytics {
            Analytics.shared.optOut()
        } else {
            Analytics.shared.optIn(with: parameters.userSession)
        }
    }

    private func presentBugReportScreen() {
        let params = BugReportCoordinatorParameters(bugReportService: parameters.bugReportService,
                                                    screenshot: nil)
        let coordinator = BugReportCoordinator(parameters: params)
        coordinator.completion = { [weak self, weak coordinator] in
            guard let self = self, let coordinator = coordinator else { return }
            self.parameters.navigationRouter.popModule(animated: true)
            self.remove(childCoordinator: coordinator)
            self.showSuccess(label: ElementL10n.done)
        }

        add(childCoordinator: coordinator)
        coordinator.start()
        navigationRouter.push(coordinator, animated: true) { [weak self] in
            guard let self = self else { return }

            self.remove(childCoordinator: coordinator)
        }
    }

    private func confirmSignOut() {
        let alert = UIAlertController(title: ElementL10n.actionSignOut,
                                      message: ElementL10n.actionSignOutConfirmationSimple,
                                      preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: ElementL10n.actionCancel, style: .cancel))
        alert.addAction(UIAlertAction(title: ElementL10n.actionSignOut, style: .destructive) { [weak self] _ in
            self?.callback?(.logout)
        })

        navigationRouter.present(alert, animated: true)
    }
    
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

    /// Show success indicator
    private func showSuccess(label: String) {
        statusIndicator = indicatorPresenter.present(.success(label: label))
    }
}
