//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Combine
import SwiftUI

struct FindFriendsScreenCoordinatorParameters {
    let contactDiscoveryService: ContactDiscoveryServiceProtocol
    let clientProxy: ClientProxyProtocol
    let accessToken: String
}

enum FindFriendsScreenCoordinatorAction {
    case startedChat(roomID: String)
    case close
}

final class FindFriendsScreenCoordinator: CoordinatorProtocol {
    private let viewModel: FindFriendsScreenViewModelProtocol

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<FindFriendsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<FindFriendsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: FindFriendsScreenCoordinatorParameters) {
        viewModel = FindFriendsScreenViewModel(contactDiscoveryService: parameters.contactDiscoveryService,
                                               clientProxy: parameters.clientProxy,
                                               accessToken: parameters.accessToken)
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            guard let self else { return }
            switch action {
            case let .startedChat(roomID):
                actionsSubject.send(.startedChat(roomID: roomID))
            case .close:
                actionsSubject.send(.close)
            }
        }
        .store(in: &cancellables)
    }

    func toPresentable() -> AnyView {
        AnyView(FindFriendsScreen(context: viewModel.context))
    }
}
