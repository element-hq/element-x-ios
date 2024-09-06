//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    let userSession: UserSessionProtocol?
    
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
                                             clientProxy: parameters.userSession?.clientProxy,
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
    
    private static let loadingIndicatorIdentifier = "\(BugReportScreenCoordinator.self)-Loading"
    
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
