//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomRolesAndPermissionsScreenViewModelType = StateStoreViewModel<RoomRolesAndPermissionsScreenViewState, RoomRolesAndPermissionsScreenViewAction>

class RoomRolesAndPermissionsScreenViewModel: RoomRolesAndPermissionsScreenViewModelType, RoomRolesAndPermissionsScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    private var actionsSubject: PassthroughSubject<RoomRolesAndPermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomRolesAndPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(initialPermissions: RoomPermissions? = nil, roomProxy: JoinedRoomProxyProtocol, userIndicatorController: UserIndicatorControllerProtocol, analytics: AnalyticsService) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        super.init(initialViewState: RoomRolesAndPermissionsScreenViewState(permissions: initialPermissions))
        
        // Automatically update the admin/moderator counts.
        roomProxy.membersPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] members in
                self?.updateMembers(members)
            }
            .store(in: &cancellables)
        
        updateMembers(roomProxy.membersPublisher.value)
        
        // Automatically update the room permissions
        roomProxy.actionsPublisher
            .filter { $0 == .roomInfoUpdate }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { await self?.updatePermissions() }
            }
            .store(in: &cancellables)
        
        Task { await updatePermissions() }
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
        case .editPermissions(let permissionsGroup):
            editPermissions(group: permissionsGroup)
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
        state.administratorCount = members.filter { $0.role == .administrator && $0.isActive }.count
        state.moderatorCount = members.filter { $0.role == .moderator && $0.isActive }.count
    }
    
    private func updateOwnRole(_ role: RoomMemberDetails.Role) async {
        showSavingIndicator()
        
        // A task we can await until the room's info gets modified with the new power levels.
        let infoTask = Task { await roomProxy.actionsPublisher.values.first { $0 == .roomInfoUpdate } }
        
        switch await roomProxy.updatePowerLevelsForUsers([(userID: roomProxy.ownUserID, powerLevel: role.rustPowerLevel)]) {
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
    
    private func updatePermissions() async {
        switch await roomProxy.powerLevels() {
        case .success(let powerLevels):
            state.permissions = .init(powerLevels: powerLevels)
        case .failure:
            break
        }
    }
    
    private func editPermissions(group: RoomRolesAndPermissionsScreenPermissionsGroup) {
        guard let permissions = state.permissions else {
            state.bindings.alertInfo = AlertInfo(id: .error)
            MXLog.error("Missing permissions.")
            return
        }
        actionsSubject.send(.editPermissions(permissions: permissions, group: group))
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
