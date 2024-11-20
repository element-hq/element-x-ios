//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias KnockRequestsListScreenViewModelType = StateStoreViewModel<KnockRequestsListScreenViewState, KnockRequestsListScreenViewAction>

class KnockRequestsListScreenViewModel: KnockRequestsListScreenViewModelType, KnockRequestsListScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    
    private let actionsSubject: PassthroughSubject<KnockRequestsListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<KnockRequestsListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: KnockRequestsListScreenViewState(), mediaProvider: mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: KnockRequestsListScreenViewAction) {
        switch viewAction {
        case .acceptAllRequests:
            break
        case .acceptRequest(userID: let userID):
            break
        case .declineRequest(userID: let userID):
            break
        case .ban(userID: let userID):
            break
        }
    }
    
    // For testing purposes
    private init(initialViewState: KnockRequestsListScreenViewState) {
        roomProxy = JoinedRoomProxyMock(.init())
        super.init(initialViewState: initialViewState)
    }
}

extension KnockRequestsListScreenViewModel {
    static func mockWithInitialState(_ initialViewState: KnockRequestsListScreenViewState) -> KnockRequestsListScreenViewModel {
        .init(initialViewState: initialViewState)
    }
}
