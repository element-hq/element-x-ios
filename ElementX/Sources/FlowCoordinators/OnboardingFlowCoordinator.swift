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

class OnboardingFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let rootNavigationStackCoordinator: NavigationStackCoordinator
    private var navigationStackCoordinator: NavigationStackCoordinator!
    
    private var cancellables = Set<AnyCancellable>()
    
    init(userSession: UserSessionProtocol,
         navigationStackCoordinator: NavigationStackCoordinator) {
        self.userSession = userSession
        rootNavigationStackCoordinator = navigationStackCoordinator
    }
    
    func start() {
        presentIdentityConfirmationScreen()
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    // MARK: - Private
    
    private func presentIdentityConfirmationScreen() {
        navigationStackCoordinator = NavigationStackCoordinator()
        
        let parameters = IdentityConfirmationScreenCoordinatorParameters(userSession: userSession)
        let coordinator = IdentityConfirmationScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .otherDevice:
                Task {
                    await self.presentSessionVerification()
                }
            case .recoveryKey:
                presentRecoveryKeyWhatever()
            case .reset:
                presentAccountResetStuff()
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
        
        rootNavigationStackCoordinator.setFullScreenCoverCoordinator(navigationStackCoordinator)
    }
    
    private func presentSessionVerification() async {
        guard case let .success(sessionVerificationController) = await userSession.clientProxy.sessionVerificationControllerProxy() else {
            fatalError("The sessionVerificationController should aways be valid at this point")
        }
        
        let parameters = SessionVerificationScreenCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationController,
                                                                        recoveryState: .disabled)
        
        let coordinator = SessionVerificationScreenCoordinator(parameters: parameters)
        
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .recoveryKey:
                    break
                case .done:
                    break
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
    
    private func presentRecoveryKeyWhatever() {
        
    }
    
    private func presentAccountResetStuff() {
        
    }
}
