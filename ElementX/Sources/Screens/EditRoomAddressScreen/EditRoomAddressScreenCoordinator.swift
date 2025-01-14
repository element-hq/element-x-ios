//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

// periphery:ignore:all - this is just a editRoomAddress remove this comment once generating the final file

import Combine
import SwiftUI

struct EditRoomAddressScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum EditRoomAddressScreenCoordinatorAction {
    case dismiss
}

final class EditRoomAddressScreenCoordinator: CoordinatorProtocol {
    private let viewModel: EditRoomAddressScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<EditRoomAddressScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<EditRoomAddressScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: EditRoomAddressScreenCoordinatorParameters) {
        viewModel = EditRoomAddressScreenViewModel(roomProxy: parameters.roomProxy,
                                                   clientProxy: parameters.clientProxy,
                                                   userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(EditRoomAddressScreen(context: viewModel.context))
    }
}
