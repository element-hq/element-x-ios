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
    private let roomProxy: RoomProxyProtocol
    private var members: [RoomMemberProxyProtocol] = []
    @CancellableTask private var showLoaderTask: Task<Void, Never>?
    
    var callback: ((RoomMembersListScreenViewModelAction) -> Void)?

    init(roomProxy: RoomProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: .init(joinedMembersCount: roomProxy.joinedMembersCount),
                   imageProvider: mediaProvider)
        
        setupMembers()
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
        case .invite:
            callback?(.invite)
        }
    }
    
    // MARK: - Private
    
    private func setupMembers() {
        Task {
            showLoader()
            await roomProxy.updateMembers()
            hideLoader()
        }
        
        roomProxy.membersPublisher
            .filter { !$0.isEmpty }
            .first()
            .sink { [weak self] members in
                self?.updateState(members: members)
            }
            .store(in: &cancellables)
    }
    
    private func updateState(members: [RoomMemberProxyProtocol]) {
        Task {
            showLoader()
            let roomMembersDetails = await buildMembersDetails(members: members)
            self.members = members
            self.state = .init(joinedMembersCount: roomProxy.joinedMembersCount,
                               joinedMembers: roomMembersDetails.joinedMembers,
                               invitedMembers: roomMembersDetails.invitedMembers)
            self.state.canInviteUsers = roomMembersDetails.accountOwner?.canInviteUsers ?? false
            hideLoader()
        }
    }
    
    private func buildMembersDetails(members: [RoomMemberProxyProtocol]) async -> RoomMembersDetails {
        await Task.detached {
            // accessing RoomMember's properties is very slow. We need to do it in a background thread.
            var invitedMembers: [RoomMemberDetails] = .init()
            var joinedMembers: [RoomMemberDetails] = .init()
            var accountOwner: RoomMemberProxyProtocol?
            
            for member in members {
                if accountOwner == nil, member.isAccountOwner {
                    accountOwner = member
                }
                
                switch member.membership {
                case .invite:
                    invitedMembers.append(.init(withProxy: member))
                case .join:
                    joinedMembers.append(.init(withProxy: member))
                default:
                    continue
                }
            }
            
            return .init(invitedMembers: invitedMembers, joinedMembers: joinedMembers, accountOwner: accountOwner)
        }
        .value
    }
    
    private let userIndicatorID = UUID().uuidString
    
    private func showLoader() {
        showLoaderTask = ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID, type: .modal, title: L10n.commonLoading, persistent: true), delay: .milliseconds(200))
    }
    
    private func hideLoader() {
        showLoaderTask = nil
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(userIndicatorID)
    }
}

private struct RoomMembersDetails {
    var invitedMembers: [RoomMemberDetails]
    var joinedMembers: [RoomMemberDetails]
    var accountOwner: RoomMemberProxyProtocol?
}
