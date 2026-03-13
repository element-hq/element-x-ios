//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum LinkNewDeviceScreenCoordinatorAction {
    case linkMobileDevice(LinkNewDeviceService.LinkMobileProgressPublisher)
    case linkDesktopComputer
    case dismiss
}

struct LinkNewDeviceScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let orientationManager: OrientationManagerProtocol
}

final class LinkNewDeviceScreenCoordinator: CoordinatorProtocol {
    private let viewModel: LinkNewDeviceScreenViewModelProtocol
    private let orientationManager: OrientationManagerProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<LinkNewDeviceScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LinkNewDeviceScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: LinkNewDeviceScreenCoordinatorParameters) {
        viewModel = LinkNewDeviceScreenViewModel(clientProxy: parameters.clientProxy)
        orientationManager = parameters.orientationManager
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .linkMobileDevice(let progressPublisher):
                actionsSubject.send(.linkMobileDevice(progressPublisher))
            case .linkDesktopComputer:
                actionsSubject.send(.linkDesktopComputer)
            case .dismiss:
                actionsSubject.send(.dismiss)
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
        AnyView(LinkNewDeviceScreen(context: viewModel.context))
    }
}
