//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomRolesAndPermissionsScreenViewModelType = StateStoreViewModelV2<RoomRolesAndPermissionsScreenViewState, RoomRolesAndPermissionsScreenViewAction>

class RoomRolesAndPermissionsScreenViewModel: RoomRolesAndPermissionsScreenViewModelType, RoomRolesAndPermissionsScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    private var ownUser: RoomMemberDetails?
    
    private var actionsSubject: PassthroughSubject<RoomRolesAndPermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomRolesAndPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(initialPermissions: RoomPermissions? = nil, roomProxy: JoinedRoomProxyProtocol, userIndicatorController: UserIndicatorControllerProtocol, analytics: AnalyticsService) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        super.init(initialViewState: RoomRolesAndPermissionsScreenViewState(ownPowerLevel: roomProxy.membersPublisher.value.first { $0.userID == roomProxy.ownUserID }?.powerLevel ?? .value(Int(RoomRole.administrator.powerLevelValue)),
                                                                            permissions: initialPermissions))
        
        // Automatically update the admin/moderator counts.
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                self?.updateMembers(members)
            }
            .store(in: &cancellables)
        
        updateMembers(roomProxy.membersPublisher.value)
        
        // Automatically update the room permissions
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo: roomInfo)
            }
            .store(in: &cancellables)
        
        updateRoomInfo(roomInfo: roomProxy.infoPublisher.value)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomRolesAndPermissionsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .editRoles(let role):
            actionsSubject.send(.editRoles(role))
        case .editOwnUserRole:
            state.bindings.alertInfo = AlertInfo(id: .editOwnRole,
                                                 title: L10n.screenRoomRolesAndPermissionsChangeMyRole,
                                                 message: L10n.screenRoomChangeRoleConfirmDemoteSelfDescription,
                                                 primaryButton: .init(title: L10n.actionCancel, role: .cancel) { },
                                                 verticalButtons: [
                                                     .init(title: L10n.screenRoomRolesAndPermissionsChangeRoleDemoteToModerator, role: .destructive) {
                                                         Task { await self.updateOwnRole(.moderator) }
                                                     },
                                                     .init(title: L10n.screenRoomRolesAndPermissionsChangeRoleDemoteToMember, role: .destructive) {
                                                         Task { await self.updateOwnRole(.user) }
                                                     }
                                                 ])
        case .editPermissions:
            editPermissions()
        case .reset:
            state.bindings.alertInfo = AlertInfo(id: .resetConfirmation,
                                                 title: L10n.screenRoomRolesAndPermissionsResetConfirmTitle,
                                                 message: L10n.screenRoomRolesAndPermissionsResetConfirmDescription,
                                                 primaryButton: .init(title: L10n.actionReset, role: .destructive) {
                                                     Task { await self.resetPermissions() }
                                                 },
                                                 secondaryButton: .init(title: L10n.actionCancel, role: .cancel) { })
        }
    }

    // MARK: - Members
    
    private func updateMembers(_ members: [RoomMemberProxyProtocol]) {
        state.administratorsAndOwnersCount = members.filter { $0.role.isAdminOrHigher && $0.isActive }.count
        state.administratorCount = members.filter { $0.role == .administrator && $0.isActive }.count
        state.moderatorCount = members.filter { $0.role == .moderator && $0.isActive }.count
        if let ownUser = members.first(where: { $0.userID == roomProxy.ownUserID }) {
            state.ownPowerLevel = ownUser.powerLevel
        }
    }
    
    private func updateOwnRole(_ role: RoomRole) async {
        showSavingIndicator()
        
        // A task we can await until the room's info gets modified with the new power levels.
        // Note: Ignore the first value as the publisher is backed by a current value subject.
        let infoTask = Task { await roomProxy.infoPublisher.dropFirst().values.first { _ in true } }
        
        switch await roomProxy.updatePowerLevelsForUsers([(userID: roomProxy.ownUserID, powerLevel: role.powerLevelValue)]) {
        case .success:
            _ = await infoTask.value
            await roomProxy.updateMembers()
            
            analytics.trackRoomModeration(action: .ChangeMemberRole, role: role)
            
            actionsSubject.send(.demotedOwnUser)
            showSuccessIndicator()
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .error)
        }
        
        hideSavingIndicator()
    }
    
    // MARK: - Permissions
    
    private func updateRoomInfo(roomInfo: RoomInfoProxyProtocol) {
        if let powerLevels = roomInfo.powerLevels {
            state.permissions = .init(powerLevels: powerLevels.values)
        }
    }
    
    private func editPermissions() {
        guard let permissions = state.permissions else {
            state.bindings.alertInfo = AlertInfo(id: .error)
            MXLog.error("Missing permissions.")
            return
        }
        actionsSubject.send(.editPermissions(ownPowerLevel: state.ownPowerLevel, permissions: permissions))
    }
    
    private func resetPermissions() async {
        showSavingIndicator()
        
        switch await roomProxy.resetPowerLevels() {
        case .success:
            analytics.trackRoomModeration(action: .ResetPermissions, role: nil)
            showSuccessIndicator()
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .error)
        }
        
        hideSavingIndicator()
    }
        
    // MARK: Loading indicator
    
    private static let savingIndicatorID = "RolesAndPermissionsSaving"
    private static let successIndicatorID = "RolesAndPermissionsSuccess"
    
    private func showSavingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.savingIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonSaving,
                                                              persistent: true))
    }
    
    private func hideSavingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.savingIndicatorID)
    }
    
    private func showSuccessIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.successIndicatorID,
                                                              type: .toast,
                                                              title: L10n.commonSuccess,
                                                              iconName: "checkmark"))
    }
}
