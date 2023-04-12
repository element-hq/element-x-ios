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

typealias InvitesListViewModelType = StateStoreViewModel<InvitesListViewState, InvitesListViewAction>

class InvitesListViewModel: InvitesListViewModelType, InvitesListViewModelProtocol {
    private var actionsSubject: PassthroughSubject<InvitesListViewModelAction, Never> = .init()
    private let userSession: UserSessionProtocol
    
    var actions: AnyPublisher<InvitesListViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol) {
        self.userSession = userSession
        super.init(initialViewState: InvitesListViewState(), imageProvider: userSession.mediaProvider)
        setupSubscriptions()
    }
    
    // MARK: - Public
    
    override func process(viewAction: InvitesListViewAction) { }
    
    // MARK: - Private
    
    private var invitesSummaryProvider: RoomSummaryProviderProtocol? {
        userSession.clientProxy.invitesSummaryProvider
    }
    
    private func setupSubscriptions() {
        guard let invitesSummaryProvider else {
            MXLog.error("Room summary provider unavailable")
            return
        }
        
        invitesSummaryProvider.roomListPublisher
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
        Task { @MainActor in
            guard let room: RoomProxyProtocol = await self.userSession.clientProxy.roomForIdentifier(roomID) else {
                return
            }
            
            let inviter: RoomMemberProxyProtocol? = await room.inviter()
            
            guard let inviter, let inviteIndex = state.invites?.firstIndex(where: { $0.roomDetails.id == roomID }) else {
                return
            }
            
            state.invites?[inviteIndex].inviter = inviter
        }
    }
}

private extension Array where Element == RoomSummary {
    var invites: [Invite] {
        compactMap { summary in
            guard case .filled(let details) = summary else {
                return nil
            }
            return .init(roomDetails: details)
        }
    }
}
