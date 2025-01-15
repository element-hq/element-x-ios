//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SecurityAndPrivacyScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SecurityAndPrivacyScreenCoordinatorAction {
    case displayEditAddressScreen
}

final class SecurityAndPrivacyScreenCoordinator: CoordinatorProtocol {
    private let viewModel: SecurityAndPrivacyScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SecurityAndPrivacyScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SecurityAndPrivacyScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecurityAndPrivacyScreenCoordinatorParameters) {
        viewModel = SecurityAndPrivacyScreenViewModel(roomProxy: parameters.roomProxy,
                                                      clientProxy: parameters.clientProxy,
                                                      userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .displayEditAddressScreen:
                actionsSubject.send(.displayEditAddressScreen)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SecurityAndPrivacyScreen(context: viewModel.context))
    }
}
