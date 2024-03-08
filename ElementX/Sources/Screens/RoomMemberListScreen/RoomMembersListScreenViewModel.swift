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

typealias RoomMembersListScreenViewModelType = StateStoreViewModel<RoomMembersListScreenViewState, RoomMembersListScreenViewAction>

class RoomMembersListScreenViewModel: RoomMembersListScreenViewModelType, RoomMembersListScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appSettings: AppSettings
    
    private var members: [RoomMemberProxyProtocol] = []
    
    private var actionsSubject: PassthroughSubject<RoomMembersListScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<RoomMembersListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(initialMode: RoomMembersListScreenMode = .members,
         roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.appSettings = appSettings
        
        super.init(initialViewState: .init(joinedMembersCount: roomProxy.joinedMembersCount,
                                           bindings: .init(mode: initialMode)),
                   imageProvider: mediaProvider)
        
        setupMembers()
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMembersListScreenViewAction) {
        switch viewAction {
        case .selectMember(let member):
            selectMember(member)
        case .showMemberDetails(let member):
            showMemberDetails(member)
        case .kickMember(let member):
            Task { await kickMember(member) }
        case .banMember(let member):
            Task { await banMember(member) }
        case .unbanMember(let member):
            Task { await unbanMember(member) }
        case .invite:
            actionsSubject.send(.invite)
        }
    }
    
    func stop() {
        hideLoader()
    }
    
    // MARK: - Members
    
    private func setupMembers() {
        Task {
            showLoader()
            await roomProxy.updateMembers()
            hideLoader()
        }
        
        roomProxy.membersPublisher
            .filter { !$0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                self?.updateState(members: members)
            }
            .store(in: &cancellables)
        
        roomProxy.timeline.timelineProvider.membershipChangePublisher.sink { [roomProxy] _ in
            Task { await roomProxy.updateMembers() }
        }
        .store(in: &cancellables)
    }
    
    private func updateState(members: [RoomMemberProxyProtocol]) {
        Task {
            showLoader()
            
            let members = members.sorted()
            let roomMembersDetails = await buildMembersDetails(members: members)
            self.members = members
            self.state = .init(joinedMembersCount: roomProxy.joinedMembersCount,
                               joinedMembers: roomMembersDetails.joinedMembers,
                               invitedMembers: roomMembersDetails.invitedMembers,
                               bannedMembers: roomMembersDetails.bannedMembers,
                               bindings: state.bindings)
            
            async let canInviteUsers = roomProxy.canUserInvite(userID: roomProxy.ownUserID)
            async let canKickUsers = roomProxy.canUserKick(userID: roomProxy.ownUserID)
            async let canBanUsers = roomProxy.canUserBan(userID: roomProxy.ownUserID)
            self.state.canInviteUsers = await canInviteUsers == .success(true)
            self.state.canKickUsers = await canKickUsers == .success(true)
            self.state.canBanUsers = await canBanUsers == .success(true)
            
            hideLoader()
        }
    }
    
    private func buildMembersDetails(members: [RoomMemberProxyProtocol]) async -> RoomMembersDetails {
        await Task.detached {
            // accessing RoomMember's properties is very slow. We need to do it in a background thread.
            var invitedMembers: [RoomMemberDetails] = .init()
            var joinedMembers: [RoomMemberDetails] = .init()
            var bannedMembers: [RoomMemberDetails] = .init()
            
            for member in members {
                switch member.membership {
                case .invite:
                    invitedMembers.append(.init(withProxy: member))
                case .join:
                    joinedMembers.append(.init(withProxy: member))
                case .ban:
                    bannedMembers.append(.init(withProxy: member))
                default:
                    continue
                }
            }
            
            return .init(invitedMembers: invitedMembers,
                         joinedMembers: joinedMembers,
                         bannedMembers: bannedMembers.sorted { $0.id.localizedStandardCompare($1.id) == .orderedAscending }) // Re-sort ignoring display name.
        }
        .value
    }
    
    private func selectMember(_ member: RoomMemberDetails) {
        if appSettings.roomModerationEnabled, state.canKickUsers || state.canBanUsers {
            if member.isBanned {
                state.bindings.alertInfo = AlertInfo(id: .unbanConfirmation(member),
                                                     title: L10n.screenRoomMemberListManageMemberUnbanTitle,
                                                     message: L10n.screenRoomMemberListManageMemberUnbanMessage,
                                                     primaryButton: .init(title: L10n.screenRoomMemberListManageMemberUnbanAction) { [weak self] in
                                                         self?.context.send(viewAction: .unbanMember(member))
                                                     },
                                                     secondaryButton: .init(title: L10n.actionCancel, role: .cancel) { })
            } else {
                state.bindings.memberToManage = member
            }
        } else {
            showMemberDetails(member)
        }
    }
    
    private func showMemberDetails(_ member: RoomMemberDetails) {
        guard let member = members.first(where: { $0.userID == member.id }) else {
            MXLog.error("Selected member \(member.id) not found")
            return
        }
        actionsSubject.send(.selectMember(member))
        state.bindings.memberToManage = nil
    }
    
    // MARK: - Member Management
    
    private func kickMember(_ member: RoomMemberDetails) async {
        let indicatorTitle = L10n.screenRoomMemberListRemovingUser(member.name ?? member.id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.kickUser(member.id) {
        case .success:
            state.bindings.memberToManage = nil
            hideManageMemberIndicator(title: indicatorTitle)
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func banMember(_ member: RoomMemberDetails) async {
        let indicatorTitle = L10n.screenRoomMemberListBanningUser(member.name ?? member.id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.banUser(member.id) {
        case .success:
            state.bindings.memberToManage = nil
            hideManageMemberIndicator(title: indicatorTitle)
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func unbanMember(_ member: RoomMemberDetails) async {
        let indicatorTitle = L10n.screenRoomMemberListUnbanningUser(member.name ?? member.id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.unbanUser(member.id) {
        case .success:
            state.bindings.memberToManage = nil
            hideManageMemberIndicator(title: indicatorTitle)
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    // MARK: - Indicators
    
    private let userIndicatorID = UUID().uuidString
    
    private func showLoader() {
        userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: true),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(200))
    }
    
    private func hideLoader() {
        userIndicatorController.retractIndicatorWithId(userIndicatorID)
    }
    
    private func showManageMemberIndicator(title: String) {
        userIndicatorController.submitIndicator(UserIndicator(id: title,
                                                              type: .toast(progress: .indeterminate),
                                                              title: title,
                                                              persistent: true))
    }
    
    private func hideManageMemberIndicator(title: String) {
        userIndicatorController.retractIndicatorWithId(title)
    }
    
    private func showManageMemberFailure(title: String) {
        userIndicatorController.retractIndicatorWithId(title)
        userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonFailed, iconName: "xmark"))
    }
}

private struct RoomMembersDetails {
    var invitedMembers: [RoomMemberDetails]
    var joinedMembers: [RoomMemberDetails]
    var bannedMembers: [RoomMemberDetails]
}
