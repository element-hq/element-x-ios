//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum RemoteLogoutFlowCoordinatorAction {
    case complete
}

/// Tells the user about each account that the server logged out, one after the other.
class RemoteLogoutFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationRootCoordinator: NavigationRootCoordinator
    /// Any other accounts waiting to be shown after the current one.
    private var pendingUserSessionDetails: [UserSessionDetails]
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RemoteLogoutFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RemoteLogoutFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSessionDetails: UserSessionDetails, navigationRootCoordinator: NavigationRootCoordinator) {
        pendingUserSessionDetails = [userSessionDetails]
        self.navigationRootCoordinator = navigationRootCoordinator
    }
    
    func start(animated: Bool) {
        showNextRemoteLogoutScreen()
    }
    
    /// Shows another logged out account once those before it have been shown.
    func appendAdditionalSession(_ userSessionDetails: UserSessionDetails) {
        pendingUserSessionDetails.append(userSessionDetails)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        navigationRootCoordinator.setRootCoordinator(nil, animated: animated)
    }
    
    // MARK: - Private
    
    private func showNextRemoteLogoutScreen() {
        guard !pendingUserSessionDetails.isEmpty else {
            actionsSubject.send(.complete)
            return
        }
        
        let coordinator = RemoteLogoutScreenCoordinator(parameters: .init(userSessionDetails: pendingUserSessionDetails.removeFirst()))
        coordinator.actionsPublisher
            .sink { [weak self] action in
                switch action {
                case .done:
                    self?.showNextRemoteLogoutScreen()
                }
            }
            .store(in: &cancellables)
        
        navigationRootCoordinator.setRootCoordinator(coordinator)
    }
}
