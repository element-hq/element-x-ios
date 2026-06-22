//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SearchScreenCoordinatorParameters {
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let mediaProvider: MediaProviderProtocol
}

enum SearchScreenCoordinatorAction {
    case presentRoom(roomID: String)
    case cancel
}

final class SearchScreenCoordinator: CoordinatorProtocol {
    private let viewModel: SearchScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<SearchScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SearchScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SearchScreenCoordinatorParameters) {
        viewModel = SearchScreenViewModel(roomSummaryProvider: parameters.roomSummaryProvider,
                                          mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .presentRoom(let roomID):
                actionsSubject.send(.presentRoom(roomID: roomID))
            case .cancel:
                actionsSubject.send(.cancel)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(SearchScreen(context: viewModel.context))
    }
}
