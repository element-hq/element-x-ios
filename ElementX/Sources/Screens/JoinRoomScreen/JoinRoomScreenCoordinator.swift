//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct JoinRoomScreenCoordinatorParameters {
    let source: JoinRoomScreenSource
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let appSettings: AppSettings
}

enum JoinRoomScreenSource {
    case generic(roomID: String, via: [String])
    case space(SpaceServiceRoomProtocol)
    
    func roomIDAndVia() -> (roomID: String, via: [String]) {
        switch self {
        case let .generic(roomID: roomID, via: via):
            return (roomID: roomID, via: via)
        case let .space(spaceServiceRoom):
            return (roomID: spaceServiceRoom.id, via: spaceServiceRoom.via)
        }
    }
}

enum JoinRoomScreenJoinDetails {
    case roomID(String)
    case space(SpaceRoomListProxyProtocol)
}

enum JoinRoomScreenCoordinatorAction {
    case joined(JoinRoomScreenJoinDetails)
    case cancelled
    case presentDeclineAndBlock(userID: String)
}

final class JoinRoomScreenCoordinator: CoordinatorProtocol {
    private let viewModel: JoinRoomScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<JoinRoomScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<JoinRoomScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: JoinRoomScreenCoordinatorParameters) {
        viewModel = JoinRoomScreenViewModel(source: parameters.source,
                                            appSettings: parameters.appSettings,
                                            userSession: parameters.userSession,
                                            userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .joined(let details):
                actionsSubject.send(.joined(details))
            case .dismiss:
                actionsSubject.send(.cancelled)
            case .presentDeclineAndBlock(let userID):
                actionsSubject.send(.presentDeclineAndBlock(userID: userID))
            }
        }
        .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
        
    func toPresentable() -> AnyView {
        AnyView(JoinRoomScreen(context: viewModel.context))
    }
}
