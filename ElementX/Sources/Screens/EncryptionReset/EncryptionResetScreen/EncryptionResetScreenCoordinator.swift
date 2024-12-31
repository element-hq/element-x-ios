//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum EncryptionResetScreenCoordinatorAction {
    case requestOIDCAuthorisation(URL)
    case requestPassword(passwordPublisher: PassthroughSubject<String, Never>)
    case resetFinished
    case cancel
}

struct EncryptionResetScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class EncryptionResetScreenCoordinator: CoordinatorProtocol {
    private let parameters: EncryptionResetScreenCoordinatorParameters
    private let viewModel: EncryptionResetScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<EncryptionResetScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EncryptionResetScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EncryptionResetScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = EncryptionResetScreenViewModel(clientProxy: parameters.clientProxy,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .requestOIDCAuthorisation(let url):
                self.actionsSubject.send(.requestOIDCAuthorisation(url))
            case .requestPassword(let passwordPublisher):
                self.actionsSubject.send(.requestPassword(passwordPublisher: passwordPublisher))
            case .resetFinished:
                self.actionsSubject.send(.resetFinished)
            case .cancel:
                self.actionsSubject.send(.cancel)
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(EncryptionResetScreen(context: viewModel.context))
    }
}
