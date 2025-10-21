//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a reportRoom remove this comment once generating the final file

import Combine
import SwiftUI

struct ReportRoomScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ReportRoomScreenCoordinatorAction {
    case dismiss(shouldLeaveRoom: Bool)
}

final class ReportRoomScreenCoordinator: CoordinatorProtocol {
    private let parameters: ReportRoomScreenCoordinatorParameters
    private let viewModel: ReportRoomScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<ReportRoomScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ReportRoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ReportRoomScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = ReportRoomScreenViewModel(roomProxy: parameters.roomProxy,
                                              userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss(let shouldLeaveRoom):
                actionsSubject.send(.dismiss(shouldLeaveRoom: shouldLeaveRoom))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(ReportRoomScreen(context: viewModel.context))
    }
}
