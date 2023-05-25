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

typealias RoomDetailsScreenViewModelType = StateStoreViewModel<RoomDetailsScreenViewState, RoomDetailsScreenViewAction>

class RoomDetailsScreenViewModel: RoomDetailsScreenViewModelType, RoomDetailsScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private var members: [RoomMemberProxyProtocol] = []
    private var dmRecipient: RoomMemberProxyProtocol?
    private var accountOwner: RoomMemberProxyProtocol?
    
    @CancellableTask
    private var buildMembersDetailsTask: Task<Void, Never>?
    
    var callback: ((RoomDetailsScreenViewModelAction) -> Void)?

    init(roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: .init(roomId: roomProxy.id,
                                           canonicalAlias: roomProxy.canonicalAlias,
                                           isEncrypted: roomProxy.isEncrypted,
                                           isDirect: roomProxy.isDirect,
                                           title: roomProxy.roomTitle,
                                           topic: roomProxy.topic,
                                           avatarURL: roomProxy.avatarURL,
                                           permalink: roomProxy.permalink,
                                           bindings: .init()),
                   imageProvider: mediaProvider)
        
        setupSubscriptions()

        Task {
            await roomProxy.updateMembers()
        }
    }
    
    // MARK: - Public
    
    // swiftlint:disable:next cyclomatic_complexity
    override func process(viewAction: RoomDetailsScreenViewAction) {
        switch viewAction {
        case .processTapPeople:
            callback?(.requestMemberDetailsPresentation(members))
        case .processTapInvite:
            callback?(.requestInvitePeoplePresentation(members))
        case .processTapLeave:
            let joinedMembers = members.filter { $0.membership == .join }
            guard joinedMembers.count > 1 else {
                state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomId: roomProxy.id, state: .empty)
                return
            }
            state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem(roomId: roomProxy.id, state: roomProxy.isPublic ? .public : .private)
        case .confirmLeave:
            Task { await leaveRoom() }
        case .processTapIgnore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .ignore)
        case .processTapUnignore:
            state.bindings.ignoreUserRoomAlertItem = .init(action: .unignore)
        case .processTapEdit, .processTapAddTopic:
            guard let accountOwner else {
                MXLog.error("Missing account owner when presenting the room's edit details screen")
                return
            }
            callback?(.requestEditDetailsPresentation(accountOwner))
        case .ignoreConfirmed:
            Task { await ignore() }
        case .unignoreConfirmed:
            Task { await unignore() }
        }
    }
    
    // MARK: - Private

    private func setupSubscriptions() {
        switch roomProxy.registerTimelineListenerIfNeeded() {
        case .success, .failure(.roomListenerAlreadyRegistered):
            break
        case .failure:
            MXLog.error("Failed to register a room listener in room's details for the room \(roomProxy.id)")
        }
        
        roomProxy.membersPublisher
            .sink { [weak self] members in
                guard let self else { return }
                
                buildMembersDetailsTask = Task {
                    let roomMembersDetails = await self.buildMembersDetails(members: members)
                    
                    guard !Task.isCancelled else { return }
                    
                    if self.roomProxy.isDirect, self.roomProxy.isEncrypted, members.count == 2 {
                        self.dmRecipient = members.first(where: { !$0.isAccountOwner })
                    }

                    self.state.members = roomMembersDetails.members
                    self.state.joinedMembersCount = roomMembersDetails.joinedMembersCount
                    self.state.dmRecipient = self.dmRecipient.map(RoomMemberDetails.init(withProxy:))
                    self.state.canInviteUsers = roomMembersDetails.accountOwner?.canInviteUsers ?? false
                    self.state.canEditRoomName = roomMembersDetails.accountOwner?.canSendStateEvent(type: .roomName) ?? false
                    self.state.canEditRoomTopic = roomMembersDetails.accountOwner?.canSendStateEvent(type: .roomTopic) ?? false
                    self.state.canEditRoomAvatar = roomMembersDetails.accountOwner?.canSendStateEvent(type: .roomAvatar) ?? false
                    self.members = members
                    self.accountOwner = roomMembersDetails.accountOwner
                }
            }
            .store(in: &cancellables)
        
        roomProxy.updatesPublisher
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                self.state.title = self.roomProxy.roomTitle
                self.state.topic = self.roomProxy.topic
                self.state.avatarURL = self.roomProxy.avatarURL
            }
            .store(in: &cancellables)
    }
    
    private func buildMembersDetails(members: [RoomMemberProxyProtocol]) async -> RoomMembersDetails {
        await Task.detached {
            // accessing RoomMember's properties is very slow. We need to do it in a background thread.
            var roomMembersDetails: [RoomMemberDetails] = []
            var accountOwner: RoomMemberProxyProtocol?
            var joinedMembersCount = 0
            roomMembersDetails.reserveCapacity(members.count)
            
            for member in members {
                roomMembersDetails.append(RoomMemberDetails(withProxy: member))
                
                if member.membership == .join {
                    joinedMembersCount += 1
                }
                
                if accountOwner == nil, member.isAccountOwner {
                    accountOwner = member
                }
            }
            
            return .init(members: roomMembersDetails, joinedMembersCount: joinedMembersCount, accountOwner: accountOwner)
        }
        .value
    }
    
    private static let leaveRoomLoadingID = "LeaveRoomLoading"

    private func leaveRoom() async {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingID, type: .modal, title: L10n.commonLeavingRoom, persistent: true))
        let result = await roomProxy.leaveRoom()
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingID)
        switch result {
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
        case .success:
            callback?(.leftRoom)
        }
    }

    private func ignore() async {
        state.isProcessingIgnoreRequest = true
        let result = await dmRecipient?.ignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.dmRecipient?.isIgnored = true
        case .failure, .none:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }

    private func unignore() async {
        state.isProcessingIgnoreRequest = true
        let result = await dmRecipient?.unignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.dmRecipient?.isIgnored = false
        case .failure, .none:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }
}

private struct RoomMembersDetails {
    let members: [RoomMemberDetails]
    let joinedMembersCount: Int
    let accountOwner: RoomMemberProxyProtocol?
}
