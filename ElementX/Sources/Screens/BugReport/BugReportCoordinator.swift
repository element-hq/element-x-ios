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

enum BugReportCoordinatorResult {
    case cancel
    case finish
}

struct BugReportCoordinatorParameters {
    let bugReportService: BugReportServiceProtocol
    let screenshot: UIImage?
    let isModallyPresented: Bool
}

final class BugReportCoordinator: CoordinatorProtocol {
    private let parameters: BugReportCoordinatorParameters
    private var viewModel: BugReportViewModelProtocol
    
//    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
//    private var loadingIndicator: UserIndicator?
//    private var statusIndicator: UserIndicator?
    
    var completion: ((BugReportCoordinatorResult) -> Void)?
    
    init(parameters: BugReportCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = BugReportViewModel(bugReportService: parameters.bugReportService,
                                       screenshot: parameters.screenshot,
                                       isModallyPresented: parameters.isModallyPresented)
        
//        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: bugReportHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] result in
            guard let self else { return }
            MXLog.debug("BugReportViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case .submitStarted:
                self.startLoading()
            case .submitFinished:
                self.stopLoading()
                self.completion?(.finish)
            case .submitFailed(let error):
                self.stopLoading()
                self.showError(label: error.localizedDescription)
            }
        }
    }

    func stop() {
        stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(BugReportScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
//        loadingIndicator = indicatorPresenter.present(.loading(label: label,
//                                                               isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
//        loadingIndicator = nil
    }

    /// Show error indicator
    private func showError(label: String) {
//        statusIndicator = indicatorPresenter.present(.error(label: label))
    }
}
