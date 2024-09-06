//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

struct BugReportFlowCoordinatorParameters {
    enum PresentationMode {
        case sheet(NavigationStackCoordinator)
        case push(NavigationStackCoordinator)
    }
    
    let presentationMode: PresentationMode
    let userIndicatorController: UserIndicatorControllerProtocol
    let bugReportService: BugReportServiceProtocol
    let userSession: UserSessionProtocol?
}

class BugReportFlowCoordinator: FlowCoordinatorProtocol {
    private let parameters: BugReportFlowCoordinatorParameters
    private var cancellables = Set<AnyCancellable>()
    
    private var internalNavigationStackCoordinator: NavigationStackCoordinator?
    
    private var isModallyPresented: Bool {
        switch parameters.presentationMode {
        case .sheet:
            return true
        case .push:
            return false
        }
    }
    
    init(parameters: BugReportFlowCoordinatorParameters) {
        self.parameters = parameters
    }
    
    func start() {
        presentBugReportScreen()
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func presentBugReportScreen() {
        let params = BugReportScreenCoordinatorParameters(bugReportService: parameters.bugReportService,
                                                          userSession: parameters.userSession,
                                                          userIndicatorController: parameters.userIndicatorController,
                                                          screenshot: nil,
                                                          isModallyPresented: isModallyPresented)
        let coordinator = BugReportScreenCoordinator(parameters: params)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                dismiss()
            case .viewLogs:
                presentLogViewerScreen()
            case .finish:
                showSuccess(label: L10n.actionDone)
                dismiss()
            }
        }
        .store(in: &cancellables)
        
        switch parameters.presentationMode {
        case .sheet(let navigationStackCoordinator):
            let internalNavigationStackCoordinator = NavigationStackCoordinator()
            internalNavigationStackCoordinator.setRootCoordinator(coordinator)
            navigationStackCoordinator.setSheetCoordinator(internalNavigationStackCoordinator)
            self.internalNavigationStackCoordinator = internalNavigationStackCoordinator
        case .push(let navigationStackCoordinator):
            internalNavigationStackCoordinator = navigationStackCoordinator
            navigationStackCoordinator.push(coordinator)
        }
    }
    
    private func presentLogViewerScreen() {
        let coordinator = LogViewerScreenCoordinator()
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .done:
                internalNavigationStackCoordinator?.pop()
            }
        }
        .store(in: &cancellables)
        
        internalNavigationStackCoordinator?.push(coordinator)
    }
    
    private func dismiss() {
        switch parameters.presentationMode {
        case .push(let navigationStackCoordinator):
            navigationStackCoordinator.pop()
        case .sheet(let navigationStackCoordinator):
            navigationStackCoordinator.setSheetCoordinator(nil)
        }
    }
    
    private func showSuccess(label: String) {
        parameters.userIndicatorController.submitIndicator(UserIndicator(title: label))
    }
}
