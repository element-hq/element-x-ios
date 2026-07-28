//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomMessageSearchScreenCoordinatorParameters {
    let searchService: SearchServiceProxyProtocol
    let userID: String
    let mediaProvider: MediaProviderProtocol
}

enum RoomMessageSearchScreenCoordinatorAction {
    case presentEvent(eventID: String)
}

final class RoomMessageSearchScreenCoordinator: CoordinatorProtocol {
    private let viewModel: RoomMessageSearchScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<RoomMessageSearchScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomMessageSearchScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: RoomMessageSearchScreenCoordinatorParameters) {
        viewModel = RoomMessageSearchScreenViewModel(searchService: parameters.searchService,
                                                     userID: parameters.userID,
                                                     mediaProvider: parameters.mediaProvider)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .presentEvent(let eventID):
                actionsSubject.send(.presentEvent(eventID: eventID))
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomMessageSearchScreen(context: viewModel.context))
    }
}
