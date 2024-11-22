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
        
        updateRoomInfo(roomInfo: roomProxy.infoPublisher.value)
        Task {
            await updatePermissions()
        }
        
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: KnockRequestsListScreenViewAction) {
        switch viewAction {
        case .acceptAllRequests:
            break
        case .acceptRequest(let userID):
            break
        case .declineRequest(let userID):
            break
        case .ban(let userID):
            break
        }
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        roomProxy.infoPublisher
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo: roomInfo)
                Task { await self?.updatePermissions() }
            }
            .store(in: &cancellables)
    }
    
    private func updateRoomInfo(roomInfo: RoomInfoProxy) {
        switch roomInfo.joinRule {
        case .knock, .knockRestricted:
            state.isKnockRoom = true
        default:
            state.isKnockRoom = false
        }
    }
    
    private func updatePermissions() async {
        state.canAccept = await (try? roomProxy.canUserInvite(userID: roomProxy.ownUserID).get()) == true
        state.canDecline = await (try? roomProxy.canUserKick(userID: roomProxy.ownUserID).get()) == true
        state.canBan = await (try? roomProxy.canUserBan(userID: roomProxy.ownUserID).get()) == true
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
