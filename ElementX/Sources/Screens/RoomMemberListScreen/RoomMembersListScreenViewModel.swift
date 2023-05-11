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

import SwiftUI

typealias RoomMembersListScreenViewModelType = StateStoreViewModel<RoomMembersListScreenViewState, RoomMembersListScreenViewAction>

class RoomMembersListScreenViewModel: RoomMembersListScreenViewModelType, RoomMembersListScreenViewModelProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let members: [RoomMemberProxyProtocol]
    
    var callback: ((RoomMembersListScreenViewModelAction) -> Void)?

    init(mediaProvider: MediaProviderProtocol, members: [RoomMemberProxyProtocol]) {
        self.mediaProvider = mediaProvider
        self.members = members
        super.init(initialViewState: .init(), imageProvider: mediaProvider)
        
        buildMembersDetails(members: members)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMembersListScreenViewAction) {
        switch viewAction {
        case .selectMember(let id):
            guard let member = members.first(where: { $0.userID == id }) else {
                MXLog.error("Selected member \(id) not found")
                return
            }
            callback?(.selectMember(member))
        }
    }
    
    // MARK: - Private
    
    func buildMembersDetails(members: [RoomMemberProxyProtocol]) {
        Task {
            let indicatorId = UUID().uuidString
            defer {
                ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(indicatorId)
            }
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: indicatorId, type: .modal, title: L10n.commonLoading, persistent: true))
            
            let (invitedMembers, joinedMembers) = await split(members: members)
            self.state = .init(joinedMembers: joinedMembers, invitedMembers: invitedMembers)
        }
    }
    
    func split(members: [RoomMemberProxyProtocol]) async -> (invited: [RoomMemberDetails], joined: [RoomMemberDetails]) {
        await Task.detached {
            // accessing RoomMember's properties is very slow. We need to do it in a background thread.
            let invitedMembers = members
                .filter { $0.membership == .invite }
                .map(RoomMemberDetails.init(withProxy:))
            
            let joinedMembers = members
                .filter { $0.membership == .join }
                .map(RoomMemberDetails.init(withProxy:))
            
            return (invitedMembers, joinedMembers)
        }
        .value
    }
}
