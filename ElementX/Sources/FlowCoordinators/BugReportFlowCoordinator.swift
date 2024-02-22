//
// Copyright 2024 New Vector Ltd
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

struct BugReportFlowCoordinatorParameters {
    enum PresentationMode {
        case sheet(NavigationStackCoordinator)
        case push(NavigationStackCoordinator)
    }
    
    let presentationMode: PresentationMode
    let userIndicatorController: UserIndicatorControllerProtocol
    let bugReportService: BugReportServiceProtocol
    let userID: String?
    let deviceID: String?
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
                                                          userID: parameters.userID,
                                                          deviceID: parameters.deviceID,
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
