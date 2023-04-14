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

typealias InvitesViewModelType = StateStoreViewModel<InvitesViewState, InvitesViewAction>

class InvitesViewModel: InvitesViewModelType, InvitesViewModelProtocol {
    private var actionsSubject: PassthroughSubject<InvitesViewModelAction, Never> = .init()
    private let userSession: UserSessionProtocol
    
    var actions: AnyPublisher<InvitesViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
        super.init(initialViewState: InvitesViewState(), imageProvider: userSession.mediaProvider)
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InvitesViewAction) {
        switch viewAction {
        case .accept(let invite):
            accept(invite: invite)
        case .decline(let invite):
            decline(invite: invite)
        }
    }
    
    // MARK: - Private
    
    private var clientProxy: ClientProxyProtocol {
        userSession.clientProxy
    }
    
    private var invitesSummaryProvider: RoomSummaryProviderProtocol? {
        clientProxy.invitesSummaryProvider
    }
    
    private func setupSubscriptions() {
        guard let invitesSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        invitesSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomSummaries in
                guard let self else { return }
                
                let invites = roomSummaries.invites
                self.state.invites = invites
                
                for invite in invites {
                    self.fetchInviter(for: invite.roomDetails.id)
                }
            }
            .store(in: &cancellables)
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
    
    private func accept(invite: InvitesRoomDetails) {
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
            let result = await roomProxy.acceptInvitation()
            
            displayErrorIfNeeded(result)
        }
    }
    
    private func decline(invite: InvitesRoomDetails) {
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
            
            displayErrorIfNeeded(result)
        }
    }
    
    private func displayErrorIfNeeded(_ result: Result<Void, RoomProxyError>) {
        guard case .failure(let error) = result else {
            return
        }
        displayError(error)
    }
    
    private func displayError(_ error: RoomProxyError) {
        #warning("Assign alertInfo here")
    }
}

private extension Array where Element == RoomSummary {
    var invites: [InvitesRoomDetails] {
        compactMap { summary in
            guard case .filled(let details) = summary else {
                return nil
            }
            return .init(roomDetails: details)
        }
    }
}
