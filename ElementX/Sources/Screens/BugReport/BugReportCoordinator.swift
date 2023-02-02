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
    weak var userNotificationController: UserNotificationControllerProtocol?
    let screenshot: UIImage?
    let isModallyPresented: Bool
}

final class BugReportCoordinator: CoordinatorProtocol {
    private let parameters: BugReportCoordinatorParameters
    private var viewModel: BugReportViewModelProtocol

    var completion: ((BugReportCoordinatorResult) -> Void)?
    
    init(parameters: BugReportCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = BugReportViewModel(bugReportService: parameters.bugReportService,
                                       screenshot: parameters.screenshot,
                                       isModallyPresented: parameters.isModallyPresented)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] result in
            guard let self else { return }
            MXLog.info("BugReportViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?(.cancel)
            case let .submitStarted(progressTracker):
                self.startLoading(progressTracker: progressTracker)
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
    
    static let loadingIndicatorIdentifier = "BugReportLoading"
    
    private func startLoading(label: String = ElementL10n.loading, progressTracker: ProgressTracker) {
        parameters.userNotificationController?.submitNotification(
            UserNotification(id: Self.loadingIndicatorIdentifier,
                             type: .modal,
                             title: label,
                             persistent: true,
                             progressTracker: progressTracker)
        )
    }
    
    private func stopLoading() {
        parameters.userNotificationController?.retractNotificationWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showError(label: String) {
        parameters.userNotificationController?.submitNotification(UserNotification(title: label))
    }
}
