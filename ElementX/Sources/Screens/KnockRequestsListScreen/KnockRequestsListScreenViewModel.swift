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
            state.bindings.alertInfo = .init(id: .acceptAllRequests,
                                             title: L10n.screenKnockRequestsListAcceptAllAlertTitle,
                                             message: L10n.screenKnockRequestsListAcceptAllAlertDescription,
                                             primaryButton: .init(title: L10n.screenKnockRequestsListAcceptAllAlertConfirmButtonTitle,
                                                                  // TODO: Implement action
                                                                  action: nil),
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .acceptRequest(let userID):
            // TODO: Implement
            break
        case .declineRequest(let userID):
            state.bindings.alertInfo = .init(id: .declineRequest,
                                             title: L10n.screenKnockRequestsListDeclineAlertTitle,
                                             message: L10n.screenKnockRequestsListDeclineAlertDescription(userID),
                                             primaryButton: .init(title: L10n.screenKnockRequestsListDeclineAlertConfirmButtonTitle,
                                                                  role: .destructive,
                                                                  // TODO: Implement action
                                                                  action: nil),
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .ban(let userID):
            state.bindings.alertInfo = .init(id: .declineAndBan,
                                             title: L10n.screenKnockRequestsListBanAlertTitle,
                                             message: L10n.screenKnockRequestsListBanAlertDescription(userID),
                                             // TODO: Implement action
                                             primaryButton: .init(title: L10n.screenKnockRequestsListBanAlertConfirmButtonTitle,
                                                                  role: .destructive,
                                                                  action: nil),
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        }
    }
    
    // MARK: - Private
    
    private func setupSubscriptions() {
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo: roomInfo)
                Task { await self?.updatePermissions() }
            }
            .store(in: &cancellables)
        
        roomProxy.requestsToJoinPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requests in
                guard let self else { return }
                state.requests = requests.map(KnockRequestCellInfo.init)
            }
            .store(in: &cancellables)
    }
    
    private func updateRoomInfo(roomInfo: RoomInfoProxy) {
        switch roomInfo.joinRule {
        case .knock, .knockRestricted:
            state.isKnockableRoom = true
        default:
            state.isKnockableRoom = false
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

extension KnockRequestCellInfo {
    init(from proxy: RequestToJoinProxyProtocol) {
        self.init(id: proxy.eventID,
                  userID: proxy.userID,
                  displayName: proxy.displayName,
                  avatarURL: proxy.avatarURL,
                  timestamp: proxy.formattedTimestamp,
                  reason: proxy.reason)
    }
}
