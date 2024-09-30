//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct GlobalSearchScreenCoordinatorParameters {
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let mediaProvider: MediaProviderProtocol
}

enum GlobalSearchControllerAction {
    case dismiss
    case select(roomID: String)
}

@MainActor
class GlobalSearchScreenCoordinator: CoordinatorProtocol {
    private let viewModel: GlobalSearchScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<GlobalSearchControllerAction, Never> = .init()
    var actions: AnyPublisher<GlobalSearchControllerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: GlobalSearchScreenCoordinatorParameters) {
        viewModel = GlobalSearchScreenViewModel(roomSummaryProvider: parameters.roomSummaryProvider,
                                                mediaProvider: parameters.mediaProvider)
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                case .select(let roomID):
                    actionsSubject.send(.select(roomID: roomID))
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(GlobalSearchScreen(context: viewModel.context))
    }
}
