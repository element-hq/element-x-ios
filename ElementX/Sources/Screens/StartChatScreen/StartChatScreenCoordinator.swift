//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct StartChatScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userDiscoveryService: UserDiscoveryServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
    let analytics: AnalyticsService
}

enum StartChatScreenCoordinatorAction {
    case close
    case createRoom
    case openRoom(roomID: String)
    case openRoomDirectorySearch
}

final class StartChatScreenCoordinator: CoordinatorProtocol {
    private let parameters: StartChatScreenCoordinatorParameters
    private var viewModel: StartChatScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
        
    private let actionsSubject: PassthroughSubject<StartChatScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<StartChatScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: StartChatScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StartChatScreenViewModel(userSession: parameters.userSession,
                                             analytics: parameters.analytics,
                                             userIndicatorController: parameters.userIndicatorController,
                                             userDiscoveryService: parameters.userDiscoveryService,
                                             appSettings: parameters.appSettings)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.close)
            case .createRoom:
                actionsSubject.send(.createRoom)
            case .showRoom(let roomID):
                actionsSubject.send(.openRoom(roomID: roomID))
            case .openRoomDirectorySearch:
                actionsSubject.send(.openRoomDirectorySearch)
            }
        }
        .store(in: &cancellables)
    }
        
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(StartChatScreen(context: viewModel.context))
    }
}
