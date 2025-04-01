//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomMembersListScreenViewModelType = StateStoreViewModel<RoomMembersListScreenViewState, RoomMembersListScreenViewAction>

class RoomMembersListScreenViewModel: RoomMembersListScreenViewModelType, RoomMembersListScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    private var members: [RoomMemberProxyProtocol] = []
    
    private var actionsSubject: PassthroughSubject<RoomMembersListScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<RoomMembersListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(initialMode: RoomMembersListScreenMode = .members,
         clientProxy: ClientProxyProtocol,
         roomProxy: JoinedRoomProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         analytics: AnalyticsService) {
        self.clientProxy = clientProxy
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        
        super.init(initialViewState: .init(joinedMembersCount: roomProxy.infoPublisher.value.joinedMembersCount,
                                           bindings: .init(mode: initialMode)),
                   mediaProvider: mediaProvider)
        
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
            var reason: String?
            let binding: Binding<String> = .init(get: { reason ?? "" },
                                                 set: { reason = $0.isEmpty ? nil : $0 })
            state.bindings.alertInfo = .init(id: .kickConfirmation,
                                             title: L10n.screenRoomMemberListKickMemberConfirmationTitle,
                                             message: L10n.screenRoomMemberListKickMemberConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                             secondaryButton: .init(title: L10n.screenRoomMemberListKickMemberConfirmationAction) { [weak self] in Task { await self?.kickMember(member, reason: reason) } },
                                             textFields: [.init(placeholder: L10n.commonReason,
                                                                text: binding,
                                                                autoCapitalization: .sentences,
                                                                autoCorrectionDisabled: false)])
        case .banMember(let member):
            var reason: String?
            let binding: Binding<String> = .init(get: { reason ?? "" },
                                                 set: { reason = $0.isEmpty ? nil : $0 })
            state.bindings.alertInfo = .init(id: .banConfirmation,
                                             title: L10n.screenRoomMemberListBanMemberConfirmationTitle,
                                             message: L10n.screenRoomMemberListBanMemberConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                             secondaryButton: .init(title: L10n.screenRoomMemberListBanMemberConfirmationAction) { [weak self] in Task { await self?.banMember(member, reason: reason) } },
                                             textFields: [.init(placeholder: L10n.commonReason,
                                                                text: binding,
                                                                autoCapitalization: .sentences,
                                                                autoCorrectionDisabled: false)])
        case .unbanMember(let member):
            Task { await unbanMember(member) }
        case .invite:
            actionsSubject.send(.invite)
        }
    }
    
    func stop() {
        hideLoadingIndicator(Self.setupMembersLoadingIndicatorIdentifier)
        hideLoadingIndicator(Self.updateStateLoadingIndicatorIdentifier)
    }
    
    // MARK: - Members
    
    private func setupMembers() {
        Task {
            showLoadingIndicator(Self.setupMembersLoadingIndicatorIdentifier)
            await roomProxy.updateMembers()
            hideLoadingIndicator(Self.setupMembersLoadingIndicatorIdentifier)
        }
        
        roomProxy.membersPublisher.combineLatest(roomProxy.identityStatusChangesPublisher)
            .filter { !$0.0.isEmpty }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members, _ in
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
            showLoadingIndicator(Self.updateStateLoadingIndicatorIdentifier)
            
            let members = members.sorted()
            let roomMembersDetails = await buildMembersDetails(members: members)
            self.members = members
            
            self.state = .init(joinedMembersCount: roomProxy.infoPublisher.value.joinedMembersCount,
                               joinedMembers: roomMembersDetails.joinedMembers,
                               invitedMembers: roomMembersDetails.invitedMembers,
                               bannedMembers: roomMembersDetails.bannedMembers,
                               bindings: state.bindings)
            
            self.state.canInviteUsers = await (try? roomProxy.canUserInvite(userID: roomProxy.ownUserID).get()) == true
            self.state.canKickUsers = await (try? roomProxy.canUserKick(userID: roomProxy.ownUserID).get()) == true
            self.state.canBanUsers = await (try? roomProxy.canUserBan(userID: roomProxy.ownUserID).get()) == true
            
            hideLoadingIndicator(Self.updateStateLoadingIndicatorIdentifier)
        }
    }
    
    private func buildMembersDetails(members: [RoomMemberProxyProtocol]) async -> RoomMembersDetails {
        await Task.detached { [clientProxy, roomProxy] in
            // accessing RoomMember's properties is very slow. We need to do it in a background thread.
            var invitedMembers: [RoomMemberListScreenEntry] = .init()
            var joinedMembers: [RoomMemberListScreenEntry] = .init()
            var bannedMembers: [RoomMemberListScreenEntry] = .init()
            
            for member in members {
                var verificationState: UserIdentityVerificationState = .notVerified
                if roomProxy.infoPublisher.value.isEncrypted, // We don't care about identity statuses on non-encrypted rooms
                   case let .success(userIdentity) = await clientProxy.userIdentity(for: member.userID),
                   let userIdentity {
                    verificationState = userIdentity.verificationState
                }
                
                switch member.membership {
                case .invite:
                    invitedMembers.append(.init(member: .init(withProxy: member), verificationState: verificationState))
                case .join:
                    joinedMembers.append(.init(member: .init(withProxy: member), verificationState: verificationState))
                case .ban:
                    bannedMembers.append(.init(member: .init(withProxy: member), verificationState: verificationState))
                default:
                    continue
                }
            }
            
            return .init(invitedMembers: invitedMembers,
                         joinedMembers: joinedMembers,
                         bannedMembers: bannedMembers.sorted { $0.member.id.localizedStandardCompare($1.member.id) == .orderedAscending }) // Re-sort ignoring display name.
        }
        .value
    }
    
    private func selectMember(_ member: RoomMemberDetails) {
        if member.isBanned { // No need to check canBan here, banned users are only shown when it is true.
            state.bindings.alertInfo = AlertInfo(id: .unbanConfirmation(member),
                                                 title: L10n.screenRoomMemberListManageMemberUnbanTitle,
                                                 message: L10n.screenRoomMemberListManageMemberUnbanMessage,
                                                 primaryButton: .init(title: L10n.screenRoomMemberListManageMemberUnbanAction) { [weak self] in
                                                     self?.context.send(viewAction: .unbanMember(member))
                                                 },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel) { })
            return
        }
        
        var actions = [RoomMembersListScreenManagementDetails.Action]()
        if state.canKickUsers, member.role != .administrator {
            actions.append(.kick)
        }
        if state.canBanUsers, member.role != .administrator {
            actions.append(.ban)
        }
        
        if !actions.isEmpty {
            state.bindings.memberToManage = .init(member: member, actions: actions)
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
    
    private func kickMember(_ member: RoomMemberDetails, reason: String?) async {
        let indicatorTitle = L10n.screenRoomMemberListRemovingUser(member.name ?? member.id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.kickUser(member.id, reason: reason) {
        case .success:
            state.bindings.memberToManage = nil
            hideManageMemberIndicator(title: indicatorTitle)
            analytics.trackRoomModeration(action: .KickMember, role: nil)
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func banMember(_ member: RoomMemberDetails, reason: String?) async {
        let indicatorTitle = L10n.screenRoomMemberListBanningUser(member.name ?? member.id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.banUser(member.id, reason: reason) {
        case .success:
            state.bindings.memberToManage = nil
            hideManageMemberIndicator(title: indicatorTitle)
            analytics.trackRoomModeration(action: .BanMember, role: nil)
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
            analytics.trackRoomModeration(action: .UnbanMember, role: nil)
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    // MARK: - Indicators
    
    private static let setupMembersLoadingIndicatorIdentifier = "\(RoomMembersListScreenViewModel.self)-SetupMembers"
    private static let updateStateLoadingIndicatorIdentifier = "\(RoomMembersListScreenViewModel.self)-UpdateState"
    
    private func showLoadingIndicator(_ identifier: String) {
        userIndicatorController.submitIndicator(UserIndicator(id: identifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: true),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(200))
    }
    
    private func hideLoadingIndicator(_ identifier: String) {
        userIndicatorController.retractIndicatorWithId(identifier)
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
    var invitedMembers: [RoomMemberListScreenEntry]
    var joinedMembers: [RoomMemberListScreenEntry]
    var bannedMembers: [RoomMemberListScreenEntry]
}
