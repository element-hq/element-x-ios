//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct LinkNewDeviceQRCodeScreenCoordinatorParameters {
    let mode: LinkNewDeviceQRCodeScreenMode
    let linkNewDeviceService: LinkNewDeviceService
    let orientationManager: OrientationManagerProtocol
    let appMediator: AppMediatorProtocol
    let appSettings: AppSettings
}

enum LinkNewDeviceQRCodeScreenCoordinatorAction {
    case cancel
    case done
    case requestOIDCAuthorisation(URL)
}

final class LinkNewDeviceQRCodeScreenCoordinator: CoordinatorProtocol {
    private let viewModel: LinkNewDeviceQRCodeScreenViewModelProtocol
    private let orientationManager: OrientationManagerProtocol
    private let appSettings: AppSettings

    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<LinkNewDeviceQRCodeScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LinkNewDeviceQRCodeScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: LinkNewDeviceQRCodeScreenCoordinatorParameters) {
        viewModel = LinkNewDeviceQRCodeScreenViewModel(mode: parameters.mode,
                                                       linkNewDeviceService: parameters.linkNewDeviceService,
                                                       appMediator: parameters.appMediator)
        orientationManager = parameters.orientationManager
        appSettings = parameters.appSettings
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .cancel:
                actionsSubject.send(.cancel)
            case .done:
                actionsSubject.send(.done)
            case .requestOIDCAuthorisation(let url):
                actionsSubject.send(.requestOIDCAuthorisation(url))
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
        AnyView(LinkNewDeviceQRCodeScreen(context: viewModel.context))
    }
}
