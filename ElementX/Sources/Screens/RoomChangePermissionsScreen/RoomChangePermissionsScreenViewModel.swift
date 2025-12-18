//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias RoomChangePermissionsScreenViewModelType = StateStoreViewModelV2<RoomChangePermissionsScreenViewState, RoomChangePermissionsScreenViewAction>

class RoomChangePermissionsScreenViewModel: RoomChangePermissionsScreenViewModelType, RoomChangePermissionsScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    private var actionsSubject: PassthroughSubject<RoomChangePermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomChangePermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(currentPermissions: RoomPermissions,
         ownPowerLevel: RoomPowerLevel,
         roomProxy: JoinedRoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         analytics: AnalyticsService) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        super.init(initialViewState: .init(ownPowerLevel: ownPowerLevel,
                                           currentPermissions: currentPermissions,
                                           isSpace: roomProxy.infoPublisher.value.isSpace))
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomChangePermissionsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .save:
            Task { await save() }
        case .cancel:
            confirmDiscardChanges()
        }
    }
    
    // MARK: - Private
    
    private func save() async {
        guard state.hasChanges else {
            MXLog.warning("Nothing to save.")
            return
        }
        
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        var changes = RoomPowerLevelChanges()
        let changedSettings = state.bindings.settings.values
            .flatMap { $0 }
            .filter { state.currentPermissions[keyPath: $0.keyPath] != $0.value }
        for setting in changedSettings {
            changes[keyPath: setting.rustKeyPath] = setting.value
        }
        
        switch await roomProxy.applyPowerLevelChanges(changes) {
        case .success:
            MXLog.info("Success")
            trackChanges(changedSettings)
            actionsSubject.send(.complete)
        case .failure:
            context.alertInfo = AlertInfo(id: .generic)
            return
        }
    }
    
    private func confirmDiscardChanges() {
        state.bindings.alertInfo = AlertInfo(id: .discardChanges,
                                             title: L10n.screenRoomChangeRoleUnsavedChangesTitle,
                                             message: L10n.screenRoomChangeRoleUnsavedChangesDescription,
                                             primaryButton: .init(title: L10n.actionSave) { Task { await self.save() } },
                                             secondaryButton: .init(title: L10n.actionDiscard, role: .cancel) { self.actionsSubject.send(.complete) })
    }
    
    // MARK: Loading indicator
    
    private static let indicatorID = "SavingRoomPermissions"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.indicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonSaving,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.indicatorID)
    }
    
    // MARK: Analytics
    
    private func trackChanges(_ settings: [RoomPermissionsSetting]) {
        for setting in settings {
            switch setting.keyPath {
            case \.ban: analytics.trackRoomModeration(action: .ChangePermissionsBanMembers, role: setting.roleValue)
            case \.invite: analytics.trackRoomModeration(action: .ChangePermissionsInviteUsers, role: setting.roleValue)
            case \.kick: analytics.trackRoomModeration(action: .ChangePermissionsKickMembers, role: setting.roleValue)
            case \.redact: analytics.trackRoomModeration(action: .ChangePermissionsRedactMessages, role: setting.roleValue)
            case \.eventsDefault: analytics.trackRoomModeration(action: .ChangePermissionsSendMessages, role: setting.roleValue)
            case \.roomName: analytics.trackRoomModeration(action: .ChangePermissionsRoomName, role: setting.roleValue)
            case \.roomAvatar: analytics.trackRoomModeration(action: .ChangePermissionsRoomAvatar, role: setting.roleValue)
            case \.roomTopic: analytics.trackRoomModeration(action: .ChangePermissionsRoomTopic, role: setting.roleValue)
            default: MXLog.warning("Unexpected change: \(setting.keyPath).")
            }
        }
    }
}
