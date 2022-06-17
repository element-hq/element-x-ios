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

struct BugReportCoordinatorParameters {
    let bugReportService: BugReportServiceProtocol
    let screenshot: UIImage?
}

final class BugReportCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: BugReportCoordinatorParameters
    private let bugReportHostingController: UIViewController
    private var bugReportViewModel: BugReportViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    private var errorIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: BugReportCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = BugReportViewModel(bugReportService: parameters.bugReportService,
                                           screenshot: parameters.screenshot)
        let view = BugReport(context: viewModel.context)
        bugReportViewModel = viewModel
        bugReportHostingController = UIHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: bugReportHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[BugReportCoordinator] did start.")
        bugReportViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[BugReportCoordinator] BugReportViewModel did complete with result: \(result).")
            switch result {
            case .submitStarted:
                self.startLoading()
            case .submitFinished:
                self.stopLoading()
                self.completion?()
            case .submitFailed(let error):
                self.stopLoading()
                self.showError(label: error.localizedDescription)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        bugReportHostingController
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label,
                                                               isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }

    /// Show success indicator
    private func showSuccess(label: String) {
        errorIndicator = indicatorPresenter.present(.success(label: label))
    }

    /// Show error indicator
    private func showError(label: String) {
        errorIndicator = indicatorPresenter.present(.error(label: label))
    }
}
