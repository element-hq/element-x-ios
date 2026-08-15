//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftUI

typealias ManageRoomMemberSheetViewModelType = StateStoreViewModelV2<ManageRoomMemberSheetViewState, ManageRoomMemberSheetViewAction>

class ManageRoomMemberSheetViewModel: ManageRoomMemberSheetViewModelType, ManageRoomMemberSheetViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analyticsService: AnalyticsServiceProtocol
    private let mediaProvider: MediaProviderProtocol
    
    private var actionsSubject: PassthroughSubject<ManageRoomMemberSheetViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<ManageRoomMemberSheetViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(memberDetails: ManageRoomMemberDetails,
         permissions: ManageRoomMemberPermissions,
         roomProxy: JoinedRoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         analyticsService: AnalyticsServiceProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.userIndicatorController = userIndicatorController
        self.roomProxy = roomProxy
        self.analyticsService = analyticsService
        self.mediaProvider = mediaProvider
        super.init(initialViewState: .init(memberDetails: memberDetails, permissions: permissions), mediaProvider: mediaProvider)

        state.bindings.selectedRole = state.memberRole ?? .user
    }

    override func process(viewAction: ManageRoomMemberSheetViewAction) {
        switch viewAction {
        case .kick:
            displayAlert(.kick)
        case .ban:
            displayAlert(.ban)
        case .displayDetails:
            actionsSubject.send(.dismiss(shouldShowDetails: true))
        case .unban:
            displayAlert(.unban)
        case .updateRole(let role):
            confirmRoleUpdate(role)
        case .displayAvatar(let url):
            Task { await displayFullScreenAvatar(url) }
        }
    }
    
    private func displayAlert(_ alertType: ManageRoomMemberSheetViewAlertType) {
        let memberID = state.memberDetails.id
        let memberName = state.memberDetails.name
        
        var reason: String?
        let binding: Binding<String> = .init(get: { reason ?? "" },
                                             set: { reason = $0.isBlank ? nil : $0 })
        switch alertType {
        case .kick:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenBottomSheetManageRoomMemberKickMemberConfirmationTitle,
                                             message: roomProxy.infoPublisher.value.isSpace ? L10n.screenBottomSheetManageRoomMemberKickMemberFromSpaceConfirmationDescription : L10n.screenBottomSheetManageRoomMemberKickMemberConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                             secondaryButton: .init(title: L10n.screenBottomSheetManageRoomMemberKickMemberConfirmationAction) { [weak self] in Task { await self?.kickMember(id: memberID, name: memberName, reason: reason) } },
                                             textFields: [.init(placeholder: L10n.commonReason,
                                                                text: binding,
                                                                autoCapitalization: .sentences,
                                                                autoCorrectionDisabled: false)])
        case .ban:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenBottomSheetManageRoomMemberBanMemberConfirmationTitle,
                                             message: roomProxy.infoPublisher.value.isSpace ? L10n.screenBottomSheetManageRoomMemberBanMemberFromSpaceConfirmationDescription : L10n.screenBottomSheetManageRoomMemberBanMemberConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                             secondaryButton: .init(title: L10n.screenBottomSheetManageRoomMemberBanMemberConfirmationAction) { [weak self] in Task { await self?.banMember(id: memberID, name: memberName, reason: reason) } },
                                             textFields: [.init(placeholder: L10n.commonReason,
                                                                text: binding,
                                                                autoCapitalization: .sentences,
                                                                autoCorrectionDisabled: false)])
        case .unban:
            state.bindings.alertInfo = .init(id: alertType,
                                             title: L10n.screenBottomSheetManageRoomMemberUnbanMemberConfirmationTitle,
                                             message: L10n.screenBottomSheetManageRoomMemberUnbanMemberConfirmationDescription,
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                             secondaryButton: .init(title: L10n.screenBottomSheetManageRoomMemberUnbanMemberConfirmationAction) { [weak self] in Task { await self?.unbanMember(id: memberID, name: memberName) } })
        case .promoteToAdmin, .promoteToOwner:
            break // Built directly in confirmRoleUpdate.
        }
    }
    
    private func confirmRoleUpdate(_ role: RoomRole) {
        guard let currentRole = state.memberRole, role != currentRole else { return }

        let revertSelection = { [weak self] in
            guard let self else { return }
            state.bindings.selectedRole = currentRole
        }

        if role == .owner {
            state.bindings.alertInfo = .init(id: .promoteToOwner,
                                             title: L10n.screenRoomChangeRoleConfirmChangeOwnersTitle,
                                             message: L10n.screenRoomChangeRoleConfirmChangeOwnersDescription,
                                             primaryButton: .init(title: L10n.actionContinue, role: .destructive) { [weak self] in Task { await self?.updateRole(role) } },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: revertSelection))
        } else if role == .administrator, state.permissions.ownPowerLevel.role == .administrator {
            // Promoting to your own power level can't be undone.
            state.bindings.alertInfo = .init(id: .promoteToAdmin,
                                             title: L10n.screenRoomChangeRoleConfirmAddAdminTitle,
                                             message: L10n.screenRoomChangeRoleConfirmAddAdminDescription,
                                             primaryButton: .init(title: L10n.actionContinue) { [weak self] in Task { await self?.updateRole(role) } },
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel, action: revertSelection))
        } else {
            Task { await updateRole(role) }
        }
    }

    private func updateRole(_ role: RoomRole) async {
        let indicatorTitle = L10n.commonSaving
        showManageMemberIndicator(title: indicatorTitle)

        // A task we can await until the room's info gets modified with the new power levels.
        // Note: Ignore the first value as the publisher is backed by a current value subject.
        let infoTask = Task {
            var iterator = roomProxy.infoPublisher.values.makeAsyncIterator()
            _ = await iterator.next(isolation: #isolation) // The publisher's current value.
            _ = await iterator.next(isolation: #isolation)
        }

        switch await roomProxy.updatePowerLevelsForUsers([(userID: state.memberDetails.id, powerLevel: role.powerLevelValue)]) {
        case .success:
            hideManageMemberIndicator(title: indicatorTitle)
            analyticsService.trackRoomModeration(action: .ChangeMemberRole, role: role)
            actionsSubject.send(.dismiss(shouldShowDetails: false))

            // Refresh the members once the new power levels are in so role badges update.
            _ = await infoTask.value
            await roomProxy.updateMembers()
        case .failure:
            infoTask.cancel()
            showManageMemberFailure(title: indicatorTitle)
            state.bindings.selectedRole = state.memberRole ?? .user
        }
    }

    private func kickMember(id: String, name: String?, reason: String?) async {
        let indicatorTitle = L10n.screenBottomSheetManageRoomMemberRemovingUser(name ?? id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.kickUser(id, reason: reason) {
        case .success:
            hideManageMemberIndicator(title: indicatorTitle)
            analyticsService.trackRoomModeration(action: .KickMember, role: nil)
            actionsSubject.send(.dismiss(shouldShowDetails: false))
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func banMember(id: String, name: String?, reason: String?) async {
        let indicatorTitle = L10n.screenBottomSheetManageRoomMemberBanningUser(name ?? id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.banUser(id, reason: reason) {
        case .success:
            hideManageMemberIndicator(title: indicatorTitle)
            analyticsService.trackRoomModeration(action: .BanMember, role: nil)
            actionsSubject.send(.dismiss(shouldShowDetails: false))
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func unbanMember(id: String, name: String?) async {
        let indicatorTitle = L10n.screenBottomSheetManageRoomMemberUnbanningUser(name ?? id)
        showManageMemberIndicator(title: indicatorTitle)
        
        switch await roomProxy.unbanUser(id) {
        case .success:
            hideManageMemberIndicator(title: indicatorTitle)
            analyticsService.trackRoomModeration(action: .UnbanMember, role: nil)
            actionsSubject.send(.dismiss(shouldShowDetails: false))
        case .failure:
            showManageMemberFailure(title: indicatorTitle)
        }
    }
    
    private func displayFullScreenAvatar(_ url: URL) async {
        let loadingIndicatorIdentifier = "manageRoomMemberAvatarLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier) }
        
        state.bindings.mediaPreviewItem = await MediaPreviewItem.load(from: url, title: state.memberDetails.name, using: mediaProvider)
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
        userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonFailed, icon: \.close))
    }
}

extension ManageRoomMemberSheetViewModel: Identifiable {
    var id: String {
        state.memberDetails.id
    }
}
