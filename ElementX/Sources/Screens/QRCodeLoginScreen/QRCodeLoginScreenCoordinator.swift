//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct QRCodeLoginScreenCoordinatorParameters {
    let qrCodeLoginService: QRCodeLoginServiceProtocol
    let orientationManager: OrientationManagerProtocol
    let appMediator: AppMediatorProtocol
}

enum QRCodeLoginScreenCoordinatorAction {
    case cancel
    case signInManually
    case done(userSession: UserSessionProtocol)
}

final class QRCodeLoginScreenCoordinator: CoordinatorProtocol {
    private let viewModel: QRCodeLoginScreenViewModelProtocol
    private let orientationManager: OrientationManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<QRCodeLoginScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<QRCodeLoginScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: QRCodeLoginScreenCoordinatorParameters) {
        viewModel = QRCodeLoginScreenViewModel(qrCodeLoginService: parameters.qrCodeLoginService,
                                               appMediator: parameters.appMediator)
        orientationManager = parameters.orientationManager
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .signInManually:
                self.actionsSubject.send(.signInManually)
            case .cancel:
                self.actionsSubject.send(.cancel)
            case .done(let userSession):
                self.actionsSubject.send(.done(userSession: userSession))
            }
        }
        .store(in: &cancellables)
        
        orientationManager.setOrientation(.portrait)
        orientationManager.lockOrientation(.portrait)
    }
    
    func stop() {
        orientationManager.lockOrientation(.all)
    }
        
    func toPresentable() -> AnyView {
        AnyView(QRCodeLoginScreen(context: viewModel.context))
    }
}
