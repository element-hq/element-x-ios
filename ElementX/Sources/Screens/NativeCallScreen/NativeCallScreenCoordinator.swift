//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct NativeCallScreenCoordinatorParameters {
    let controller: NativeCallController
    let roomProxy: JoinedRoomProxyProtocol
    let mediaProvider: MediaProviderProtocol
}

enum NativeCallScreenCoordinatorAction {
    case minimize
    case dismiss
}

final class NativeCallScreenCoordinator: CoordinatorProtocol {
    private let parameters: NativeCallScreenCoordinatorParameters
    private let viewModel: NativeCallScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<NativeCallScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<NativeCallScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NativeCallScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = NativeCallScreenViewModel(controller: parameters.controller, roomProxy: parameters.roomProxy, mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .minimize:
                actionsSubject.send(.minimize)
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NativeCallScreen(context: viewModel.context))
    }
}
