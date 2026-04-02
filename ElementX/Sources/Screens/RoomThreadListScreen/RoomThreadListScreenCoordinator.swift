//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomThreadListScreenCoordinatorParameters {
    let threadListServiceProxy: RoomThreadListServiceProxyProtocol
    let mediaProvider: MediaProviderProtocol
}

enum RoomThreadListScreenCoordinatorAction {
    case presentThread(threadRootEventID: String)
}

final class RoomThreadListScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomThreadListScreenCoordinatorParameters
    private let viewModel: RoomThreadListScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<RoomThreadListScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomThreadListScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomThreadListScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = RoomThreadListScreenViewModel(threadListServiceProxy: parameters.threadListServiceProxy,
                                                  mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            MXLog.info("Coordinator: received view model action: \(action)")

            switch action {
            case .presentThread(let threadRootEventID):
                actionsSubject.send(.presentThread(threadRootEventID: threadRootEventID))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomThreadListScreen(context: viewModel.context))
    }
}
