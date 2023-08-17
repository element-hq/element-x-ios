//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

typealias InvitesScreenViewModelType = StateStoreViewModel<InvitesScreenViewState, InvitesScreenViewAction>

class InvitesScreenViewModel: InvitesScreenViewModelType, InvitesScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let appSettings: AppSettings
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let notificationCenterProtocol: NotificationCenterProtocol
    
    private let previouslySeenInvites: Set<String>
    private let actionsSubject: PassthroughSubject<InvitesScreenViewModelAction, Never> = .init()

    var actions: AnyPublisher<InvitesScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol,
         appSettings: AppSettings,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         notificationCenterProtocol: NotificationCenterProtocol = NotificationCenter.default) {
        self.userSession = userSession
        self.appSettings = appSettings
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        self.notificationCenterProtocol = notificationCenterProtocol
        
        previouslySeenInvites = appSettings.seenInvites
        super.init(initialViewState: InvitesScreenViewState(), imageProvider: userSession.mediaProvider)
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InvitesScreenViewAction) {
        switch viewAction {
        case .accept(let invite):
            accept(invite: invite)
        case .decline(let invite):
            startDeclineFlow(invite: invite)
        case .appeared:
            notificationCenterProtocol.post(name: .invitesScreenAppeared, object: nil)
        }
    }
    
    // MARK: - Private
    
    private var clientProxy: ClientProxyProtocol {
        userSession.clientProxy
    }
    
    private var inviteSummaryProvider: RoomSummaryProviderProtocol? {
        clientProxy.inviteSummaryProvider
    }
    
    private func setupSubscriptions() {
        guard let inviteSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        inviteSummaryProvider.roomListPublisher
            .removeDuplicates()
            .sink { [weak self] roomSummaries in
                guard let self else { return }
                
                let invites: [InvitesScreenRoomDetails] = roomSummaries.compactMap { summary in
                    guard case .filled(let details) = summary else {
                        return nil
                    }
                    return InvitesScreenRoomDetails(roomDetails: details, isUnread: !self.previouslySeenInvites.contains(details.id))
                }
                
                self.state.invites = invites
                self.appSettings.seenInvites = Set(invites.map(\.roomDetails.id))
            }
            .store(in: &cancellables)
    }

    private func startDeclineFlow(invite: InvitesScreenRoomDetails) {
        let roomPlaceholder = invite.isDirect ? (invite.roomDetails.inviter?.displayName ?? invite.roomDetails.name) : invite.roomDetails.name
        let title = invite.isDirect ? L10n.screenInvitesDeclineDirectChatTitle : L10n.screenInvitesDeclineChatTitle
        let message = invite.isDirect ? L10n.screenInvitesDeclineDirectChatMessage(roomPlaceholder) : L10n.screenInvitesDeclineChatMessage(roomPlaceholder)
        
        state.bindings.alertInfo = .init(id: true,
                                         title: title,
                                         message: message,
                                         primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                         secondaryButton: .init(title: L10n.actionDecline, role: .destructive, action: { self.decline(invite: invite) }))
    }
    
    private func accept(invite: InvitesScreenRoomDetails) {
        Task {
            let roomID = invite.roomDetails.id
            defer {
                userIndicatorController.retractIndicatorWithId(roomID)
            }
            
            userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
            
            guard let roomProxy = await clientProxy.roomForIdentifier(roomID) else {
                displayError(.failedAcceptingInvite)
                return
            }
            
            switch await roomProxy.acceptInvitation() {
            case .success:
                actionsSubject.send(.openRoom(withIdentifier: roomID))
                analytics.trackJoinedRoom(isDM: roomProxy.isDirect, isSpace: roomProxy.isSpace, activeMemberCount: UInt(roomProxy.activeMembersCount))
            case .failure(let error):
                displayError(error)
            }
        }
    }
    
    private func decline(invite: InvitesScreenRoomDetails) {
        Task {
            let roomID = invite.roomDetails.id
            defer {
                userIndicatorController.retractIndicatorWithId(roomID)
            }
            
            userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
            
            guard let roomProxy = await clientProxy.roomForIdentifier(roomID) else {
                displayError(.failedRejectingInvite)
                return
            }
            
            let result = await roomProxy.rejectInvitation()
            
            if case .failure(let error) = result {
                displayError(error)
            }
        }
    }
    
    private func displayError(_ error: RoomProxyError) {
        state.bindings.alertInfo = .init(id: true,
                                         title: L10n.commonError,
                                         message: L10n.errorUnknown)
    }
}
