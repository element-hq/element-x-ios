//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct QRCodeLoginScreenCoordinatorParameters {
    let mode: QRCodeLoginScreenMode
    let canSignInManually: Bool
    let orientationManager: OrientationManagerProtocol
    let appMediator: AppMediatorProtocol
}

enum QRCodeLoginScreenCoordinatorAction: CustomStringConvertible {
    /// Restart the flow.
    ///
    /// This action should only be sent when linking a new device. When logging in it
    /// is handled internally within the screen.
    case startOver
    case signInManually
    case signedIn(userSession: UserSessionProtocol)
    case requestOIDCAuthorisation(URL, OIDCAccountSettingsPresenter.Continuation)
    case linkedDevice
    /// Cancel the flow (dismiss the modal).
    case cancel
    
    var description: String {
        switch self {
        case .startOver: "startOver"
        case .signInManually: "signInManually"
        case .signedIn: "signedIn"
        case .requestOIDCAuthorisation: "requestOIDCAuthorisation"
        case .linkedDevice: "linkedDevice"
        case .cancel: "cancel"
        }
    }
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
        viewModel = QRCodeLoginScreenViewModel(mode: parameters.mode,
                                               canSignInManually: parameters.canSignInManually,
                                               appMediator: parameters.appMediator)
        orientationManager = parameters.orientationManager
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .signInManually:
                actionsSubject.send(.signInManually)
            case .startOver:
                actionsSubject.send(.startOver)
            case .signedIn(let userSession):
                actionsSubject.send(.signedIn(userSession: userSession))
            case .requestOIDCAuthorisation(let url, let continuation):
                actionsSubject.send(.requestOIDCAuthorisation(url, continuation))
            case .linkedDevice:
                actionsSubject.send(.linkedDevice)
            case .cancel:
                actionsSubject.send(.cancel)
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
