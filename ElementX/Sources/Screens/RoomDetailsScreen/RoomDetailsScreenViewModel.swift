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
    private let accountUserID: String
    private let roomProxy: RoomProxyProtocol

    private var accountOwner: RoomMemberProxyProtocol? {
        didSet { updatePowerLevelPermissions() }
    }

    private var dmRecipient: RoomMemberProxyProtocol?
    
    var callback: ((RoomDetailsScreenViewModelAction) -> Void)?
    
    init(accountUserID: String,
         roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.accountUserID = accountUserID
        self.roomProxy = roomProxy
        super.init(initialViewState: .init(roomId: roomProxy.id,
                                           canonicalAlias: roomProxy.canonicalAlias,
                                           isEncrypted: roomProxy.isEncrypted,
                                           isDirect: roomProxy.isDirect,
                                           permalink: roomProxy.permalink,
                                           title: roomProxy.roomTitle,
                                           topic: roomProxy.topic,
                                           avatarURL: roomProxy.avatarURL,
                                           joinedMembersCount: roomProxy.joinedMembersCount,
                                           bindings: .init()),
                   imageProvider: mediaProvider)
        
        setupRoomSubscription()
        fetchMembers()
    }
    
    // MARK: - Public
    
    // swiftlint:disable:next cyclomatic_complexity
    override func process(viewAction: RoomDetailsScreenViewAction) {
        switch viewAction {
        case .processTapPeople:
            callback?(.requestMemberDetailsPresentation)
        case .processTapInvite:
            callback?(.requestInvitePeoplePresentation)
        case .processTapLeave:
            guard state.joinedMembersCount > 1 else {
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

    private func setupRoomSubscription() {
        roomProxy.updatesPublisher
            .throttle(for: .milliseconds(200), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                self.state.title = self.roomProxy.roomTitle
                self.state.topic = self.roomProxy.topic
                self.state.avatarURL = self.roomProxy.avatarURL
                self.state.joinedMembersCount = self.roomProxy.joinedMembersCount
            }
            .store(in: &cancellables)
    }
    
    private func fetchMembers() {
        Task {
            await fetchMembersIfNeeded()
            await fetchAccountOwner()
        }
    }
    
    private func fetchMembersIfNeeded() async {
        // We need to fetch members just in 1-to-1 chat to get the member object for the other person
        guard roomProxy.isEncryptedOneToOneRoom else {
            return
        }
        
        roomProxy.membersPublisher
            .sink { [weak self] members in
                guard let self else { return }
                let dmRecipient = members.first(where: { !$0.isAccountOwner })
                self.dmRecipient = dmRecipient
                self.state.dmRecipient = dmRecipient.map(RoomMemberDetails.init(withProxy:))
            }
            .store(in: &cancellables)
        
        await roomProxy.updateMembers()
    }
    
    private func fetchAccountOwner() async {
        switch await roomProxy.getMember(userID: accountUserID) {
        case .success(let member):
            accountOwner = member
        case .failure(let error):
            MXLog.error("Failed (error: \(error) to get account owner member with id: \(accountUserID), in room: \(roomProxy.id)")
        }
    }
    
    private func updatePowerLevelPermissions() {
        state.canInviteUsers = accountOwner?.canInviteUsers ?? false
        state.canEditRoomName = accountOwner?.canSendStateEvent(type: .roomName) ?? false
        state.canEditRoomTopic = accountOwner?.canSendStateEvent(type: .roomTopic) ?? false
        state.canEditRoomAvatar = accountOwner?.canSendStateEvent(type: .roomAvatar) ?? false
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
