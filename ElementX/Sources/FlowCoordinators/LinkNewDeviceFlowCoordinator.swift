//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum LinkNewDeviceFlowCoordinatorAction {
    case requestOIDCAuthorisation(URL, OIDCAccountSettingsPresenter.Continuation)
    case dismiss
}

class LinkNewDeviceFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let flowParameters: CommonFlowParameters
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<LinkNewDeviceFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LinkNewDeviceFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.navigationStackCoordinator = navigationStackCoordinator
        self.flowParameters = flowParameters
    }
    
    func start(animated: Bool) {
        presentLinkNewDeviceScreen()
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    private func presentLinkNewDeviceScreen() {
        let coordinator = LinkNewDeviceScreenCoordinator(parameters: .init(clientProxy: flowParameters.userSession.clientProxy))
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .linkMobileDevice(let progressPublisher):
                    presentQRCodeScreen(mode: .linkMobile(progressPublisher))
                case .linkDesktopComputer:
                    presentQRCodeScreen(mode: .linkDesktop(flowParameters.userSession.clientProxy.linkNewDeviceService()))
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func presentQRCodeScreen(mode: QRCodeLoginScreenMode) {
        let coordinator = QRCodeLoginScreenCoordinator(parameters: .init(mode: mode,
                                                                         canSignInManually: false, // No need to worry about this when linking a device.
                                                                         orientationManager: flowParameters.appMediator.windowManager,
                                                                         appMediator: flowParameters.appMediator))
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .signInManually, .signedIn:
                    fatalError("QR linking shouldn't send sign-in actions.")
                case .dismiss:
                    navigationStackCoordinator.pop()
                case .requestOIDCAuthorisation(let url, let continuation):
                    actionsSubject.send(.requestOIDCAuthorisation(url, continuation))
                case .linkedDevice:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
}
