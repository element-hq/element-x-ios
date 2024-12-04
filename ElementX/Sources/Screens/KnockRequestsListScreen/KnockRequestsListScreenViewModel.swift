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
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<KnockRequestsListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<KnockRequestsListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: JoinedRoomProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
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
                                                                  action: acceptAll),
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .acceptRequest(let eventID):
            acceptRequest(eventID: eventID)
        case .declineRequest(let eventID):
            guard let request = roomProxy.requestsToJoinPublisher.value.first(where: { $0.eventID == eventID }) else {
                return
            }
            state.bindings.alertInfo = .init(id: .declineRequest,
                                             title: L10n.screenKnockRequestsListDeclineAlertTitle,
                                             message: L10n.screenKnockRequestsListDeclineAlertDescription(request.userID),
                                             primaryButton: .init(title: L10n.screenKnockRequestsListDeclineAlertConfirmButtonTitle,
                                                                  role: .destructive,
                                                                  action: { [weak self] in self?.decline(request: request) }),
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        case .ban(let eventID):
            guard let request = roomProxy.requestsToJoinPublisher.value.first(where: { $0.eventID == eventID }) else {
                return
            }
            state.bindings.alertInfo = .init(id: .declineAndBan,
                                             title: L10n.screenKnockRequestsListBanAlertTitle,
                                             primaryButton: .init(title: L10n.screenKnockRequestsListBanAlertConfirmButtonTitle,
                                                                  role: .destructive,
                                                                  action: { [weak self] in self?.declineAndBan(request: request) }),
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil))
        }
    }
    
    // MARK: - Private
    
    private func acceptRequest(eventID: String) {
        guard let request = roomProxy.requestsToJoinPublisher.value.first(where: { $0.eventID == eventID }) else {
            return
        }
        state.handledEventIDs.insert(eventID)
        Task {
            switch await request.accept() {
            case .success:
                break
            case .failure:
                state.handledEventIDs.remove(eventID)
                userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            }
        }
    }
    
    private func decline(request: RequestToJoinProxyProtocol) {
        let eventID = request.eventID
        state.handledEventIDs.insert(eventID)
        Task {
            switch await request.decline() {
            case .success:
                break
            case .failure:
                state.handledEventIDs.remove(eventID)
                userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            }
        }
    }
    
    private func declineAndBan(request: RequestToJoinProxyProtocol) {
        let eventID = request.eventID
        state.handledEventIDs.insert(eventID)
        Task {
            switch await request.ban() {
            case .success:
                break
            case .failure:
                state.handledEventIDs.remove(eventID)
                userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
            }
        }
    }
    
    private func acceptAll() {
        let requests = roomProxy.requestsToJoinPublisher.value
        state.handledEventIDs.formUnion(Set(requests.map(\.eventID)))
        Task {
            let failedIDs = await withTaskGroup(of: (String, Result<Void, RequestToJoinProxyError>).self) { group in
                for request in requests {
                    group.addTask {
                        await (request.eventID, request.accept())
                    }
                }
                
                var failedIDs = [String]()
                for await result in group where result.1.isFailure {
                    failedIDs.append(result.0)
                }
                return failedIDs
            }
            state.handledEventIDs.subtract(failedIDs)
        }
    }
    
    private func setupSubscriptions() {
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo: roomInfo)
                Task { await self?.updatePermissions() }
            }
            .store(in: &cancellables)
        
        roomProxy.requestsToJoinPublisher
            .map { $0.map(KnockRequestCellInfo.init) }
            .removeDuplicates()
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .weakAssign(to: \.state.requests, on: self)
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
        userIndicatorController = UserIndicatorControllerMock()
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
