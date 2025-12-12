//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum LinkNewDeviceFlowCoordinatorAction {
    case requestOIDCAuthorisation(URL)
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
                    presentLinkNewDeviceQRCodeScreen(mode: .generateQRCode(progressPublisher))
                case .linkDesktopComputer:
                    presentLinkNewDeviceQRCodeScreen(mode: .scanQRCode)
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.setRootCoordinator(coordinator)
    }
    
    private func presentLinkNewDeviceQRCodeScreen(mode: LinkNewDeviceQRCodeScreenMode) {
        let coordinator = LinkNewDeviceQRCodeScreenCoordinator(parameters: .init(mode: mode,
                                                                                 linkNewDeviceService: flowParameters.userSession.clientProxy.linkNewDeviceService(),
                                                                                 orientationManager: flowParameters.appMediator.windowManager,
                                                                                 appMediator: flowParameters.appMediator,
                                                                                 appSettings: flowParameters.appSettings))
        coordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .cancel:
                    navigationStackCoordinator.pop()
                case .done:
                    actionsSubject.send(.dismiss)
                case .requestOIDCAuthorisation(let url):
                    actionsSubject.send(.requestOIDCAuthorisation(url))
                }
            }
            .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator)
    }
}
