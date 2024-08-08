//
// Copyright 2022 New Vector Ltd
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
