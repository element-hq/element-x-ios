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
    let navigationController: NavigationController
    let userSession: UserSessionProtocol
    let bugReportService: BugReportServiceProtocol
}

enum SettingsCoordinatorAction {
    case dismiss
    case logout
}

final class SettingsCoordinator: CoordinatorProtocol {
    private let navigationController: NavigationController
    private let userSession: UserSessionProtocol
    private let bugReportService: BugReportServiceProtocol
    private var viewModel: SettingsViewModelProtocol
    
//    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
//    private var loadingIndicator: UserIndicator?
//    private var statusIndicator: UserIndicator?

    var callback: ((SettingsCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: SettingsCoordinatorParameters) {
        navigationController = parameters.navigationController
        userSession = parameters.userSession
        bugReportService = parameters.bugReportService
        
//        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: settingsHostingController)

        viewModel = SettingsViewModel(withUserSession: parameters.userSession)
        viewModel.callback = { [weak self] result in
            guard let self else { return }
            MXLog.debug("SettingsViewModel did complete with result: \(result).")
            switch result {
            case .close:
                self.callback?(.dismiss)
            case .toggleAnalytics:
                self.toggleAnalytics()
            case .reportBug:
                self.presentBugReportScreen()
            case .crash:
                self.bugReportService.crash()
            case .logout:
                self.callback?(.logout)
            }
        }
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(SettingsScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func toggleAnalytics() {
        if ElementSettings.shared.enableAnalytics {
            Analytics.shared.optOut()
        } else {
            Analytics.shared.optIn(with: userSession)
        }
    }

    private func presentBugReportScreen() {
        let params = BugReportCoordinatorParameters(bugReportService: bugReportService,
                                                    screenshot: nil,
                                                    isModallyPresented: false)
        let coordinator = BugReportCoordinator(parameters: params)
        coordinator.completion = { [weak self] result in
            switch result {
            case .finish:
                self?.showSuccess(label: ElementL10n.done)
            default:
                break
            }
            
            self?.navigationController.pop()
        }
        
        navigationController.push(coordinator)
    }

    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
//        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
//        loadingIndicator = nil
    }

    /// Show success indicator
    private func showSuccess(label: String) {
//        statusIndicator = indicatorPresenter.present(.success(label: label))
    }
}
