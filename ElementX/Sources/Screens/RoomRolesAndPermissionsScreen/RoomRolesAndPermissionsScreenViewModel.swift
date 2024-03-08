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

typealias RoomRolesAndPermissionsScreenViewModelType = StateStoreViewModel<RoomRolesAndPermissionsScreenViewState, RoomRolesAndPermissionsScreenViewAction>

class RoomRolesAndPermissionsScreenViewModel: RoomRolesAndPermissionsScreenViewModelType, RoomRolesAndPermissionsScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<RoomRolesAndPermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomRolesAndPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomProxy: RoomProxyProtocol, userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        super.init(initialViewState: RoomRolesAndPermissionsScreenViewState())
        
        roomProxy.membersPublisher.sink { [weak self] members in
            self?.updateMembers(members)
        }
        .store(in: &cancellables)
        
        updateMembers(roomProxy.membersPublisher.value)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomRolesAndPermissionsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .editRoles(let role):
            actionsSubject.send(.editRoles(role))
        case .editOwnUserRole:
            state.bindings.alertInfo = AlertInfo(id: .resetConfirmation,
                                                 title: L10n.screenRoomRolesAndPermissionsChangeMyRole,
                                                 message: L10n.screenRoomChangeRoleConfirmDemoteSelfDescription,
                                                 verticalButtons: [
                                                     .init(title: L10n.screenRoomRolesAndPermissionsChangeRoleDemoteToModerator, role: .destructive) {
                                                         Task { await self.updateOwnRole(.moderator) }
                                                     },
                                                     .init(title: L10n.screenRoomRolesAndPermissionsChangeRoleDemoteToMember, role: .destructive) {
                                                         Task { await self.updateOwnRole(.user) }
                                                     },
                                                     .init(title: L10n.actionCancel, role: .cancel) { }
                                                 ])
        case .editPermissions(let permissionsGroup):
            actionsSubject.send(.editPermissions(permissionsGroup))
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
        state.administratorCount = members.filter { $0.role == .administrator }.count
        state.moderatorCount = members.filter { $0.role == .moderator }.count
    }
    
    private func updateOwnRole(_ role: RoomMemberDetails.Role) async {
        showSavingIndicator()
        
        switch await roomProxy.updatePowerLevelsForUsers([(userID: roomProxy.ownUserID, powerLevel: role.rustPowerLevel)]) {
        case .success:
            showSuccessIndicator()
            actionsSubject.send(.demotedOwnUser)
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .error)
        }
        
        hideSavingIndicator()
    }
    
    private func resetPermissions() async {
        showSavingIndicator()
        
        switch await roomProxy.resetPowerLevels() {
        case .success(let success):
            showSuccessIndicator()
        case .failure(let failure):
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
