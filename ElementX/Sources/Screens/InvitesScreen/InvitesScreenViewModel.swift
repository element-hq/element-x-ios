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
    private var actionsSubject: PassthroughSubject<InvitesScreenViewModelAction, Never> = .init()
    private let userSession: UserSessionProtocol
    private let previouslySeenInvites: Set<String>
    
    var actions: AnyPublisher<InvitesScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
        previouslySeenInvites = ServiceLocator.shared.settings.seenInvites
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
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomSummaries in
                guard let self else { return }
                
                let invites = self.buildInvites(from: roomSummaries)
                ServiceLocator.shared.settings.seenInvites = Set(invites.map(\.roomDetails.id))
                self.state.invites = invites
                
                for invite in invites {
                    self.fetchInviter(for: invite.roomDetails.id)
                }
            }
            .store(in: &cancellables)
    }
    
    private func buildInvites(from summaries: [RoomSummary]) -> [InvitesScreenRoomDetails] {
        summaries.compactMap { summary in
            guard case .filled(let details) = summary else {
                return nil
            }
            return InvitesScreenRoomDetails(roomDetails: details, isUnread: !previouslySeenInvites.contains(details.id))
        }
    }
    
    private func fetchInviter(for roomID: String) {
        Task {
            guard let room: RoomProxyProtocol = await self.clientProxy.roomForIdentifier(roomID) else {
                return
            }
            
            let inviter: RoomMemberProxyProtocol? = await room.inviter()
            
            guard let inviter, let inviteIndex = state.invites?.firstIndex(where: { $0.roomDetails.id == roomID }) else {
                return
            }
            
            state.invites?[inviteIndex].inviter = inviter
        }
    }
    
    private func startDeclineFlow(invite: InvitesScreenRoomDetails) {
        let roomPlaceholder = invite.isDirect ? (invite.inviter?.displayName ?? invite.roomDetails.name) : invite.roomDetails.name
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
                ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(roomID)
            }
            
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
            
            guard let roomProxy = await clientProxy.roomForIdentifier(roomID) else {
                displayError(.failedAcceptingInvite)
                return
            }
            
            switch await roomProxy.acceptInvitation() {
            case .success:
                actionsSubject.send(.openRoom(withIdentifier: roomID))
            case .failure(let error):
                displayError(error)
            }
        }
    }
    
    private func decline(invite: InvitesScreenRoomDetails) {
        Task {
            let roomID = invite.roomDetails.id
            defer {
                ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(roomID)
            }
            
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
            
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
