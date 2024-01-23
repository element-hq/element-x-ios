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

import Combine
import SwiftUI

enum BugReportScreenCoordinatorAction {
    case cancel
    case viewLogs
    case finish
}

struct BugReportScreenCoordinatorParameters {
    let bugReportService: BugReportServiceProtocol
    let userID: String?
    let deviceID: String?
    
    let userIndicatorController: UserIndicatorControllerProtocol?
    let screenshot: UIImage?
    let isModallyPresented: Bool
}

final class BugReportScreenCoordinator: CoordinatorProtocol {
    private let parameters: BugReportScreenCoordinatorParameters
    private var viewModel: BugReportScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<BugReportScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<BugReportScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: BugReportScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = BugReportScreenViewModel(bugReportService: parameters.bugReportService,
                                             userID: parameters.userID,
                                             deviceID: parameters.deviceID,
                                             screenshot: parameters.screenshot,
                                             isModallyPresented: parameters.isModallyPresented)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel
            .actions
            .sink { [weak self] action in
                guard let self else { return }
                
                MXLog.info("BugReportViewModel did complete with result: \(action).")
                switch action {
                case .cancel:
                    actionsSubject.send(.cancel)
                case .viewLogs:
                    actionsSubject.send(.viewLogs)
                case let .submitStarted(progressPublisher):
                    startLoading(label: L10n.commonSending, progressPublisher: progressPublisher)
                case .submitFinished:
                    stopLoading()
                    actionsSubject.send(.finish)
                case .submitFailed(let error):
                    stopLoading()
                    showError(label: error.localizedDescription)
                }
            }
            .store(in: &cancellables)
    }

    func stop() {
        stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(BugReportScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private static let loadingIndicatorIdentifier = "BugReportLoading"
    
    private func startLoading(label: String = L10n.commonLoading, progressPublisher: CurrentValuePublisher<Double, Never>) {
        parameters.userIndicatorController?.submitIndicator(
            UserIndicator(id: Self.loadingIndicatorIdentifier,
                          type: .modal(progress: .published(progressPublisher), interactiveDismissDisabled: false, allowsInteraction: true),
                          title: label,
                          persistent: true)
        )
    }
    
    private func stopLoading() {
        parameters.userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
    
    private func showError(label: String) {
        parameters.userIndicatorController?.submitIndicator(UserIndicator(title: label, iconName: "xmark"))
    }
}
