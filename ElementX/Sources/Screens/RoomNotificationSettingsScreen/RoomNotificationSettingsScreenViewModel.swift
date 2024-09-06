//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomNotificationSettingsScreenViewModelType = StateStoreViewModel<RoomNotificationSettingsScreenViewState, RoomNotificationSettingsScreenViewAction>

class RoomNotificationSettingsScreenViewModel: RoomNotificationSettingsScreenViewModelType, RoomNotificationSettingsScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<RoomNotificationSettingsScreenViewModelAction, Never> = .init()
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    private let roomProxy: JoinedRoomProxyProtocol
    
    // periphery:ignore - cancellable tasks cancel when reassigned
    @CancellableTask private var fetchNotificationSettingsTask: Task<Void, Error>?
    
    var actions: AnyPublisher<RoomNotificationSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(notificationSettingsProxy: NotificationSettingsProxyProtocol, roomProxy: JoinedRoomProxyProtocol, displayAsUserDefinedRoomSettings: Bool) {
        let bindings = RoomNotificationSettingsScreenViewStateBindings()
        self.notificationSettingsProxy = notificationSettingsProxy
        self.roomProxy = roomProxy
        let navigationTitle = displayAsUserDefinedRoomSettings ? roomProxy.roomTitle : L10n.screenRoomDetailsNotificationTitle
        let customSettingsSectionHeader = displayAsUserDefinedRoomSettings ? L10n.screenRoomNotificationSettingsRoomCustomSettingsTitle : L10n.screenRoomNotificationSettingsCustomSettingsTitle
        super.init(initialViewState: RoomNotificationSettingsScreenViewState(bindings: bindings,
                                                                             displayAsUserDefinedRoomSettings: displayAsUserDefinedRoomSettings,
                                                                             navigationTitle: navigationTitle,
                                                                             customSettingsSectionHeader: customSettingsSectionHeader))
        
        setupNotificationSettingsSubscription()
        fetchNotificationSettings()
    }
        
    // MARK: - Public
    
    override func process(viewAction: RoomNotificationSettingsScreenViewAction) {
        switch viewAction {
        case .changedAllowCustomSettings:
            toogleCustomSetting()
        case .setCustomMode(let mode):
            setCustomMode(mode)
        case .customSettingFootnoteLinkTapped:
            actionsSubject.send(.openGlobalSettings)
        case .deleteCustomSettingTapped:
            Task { await deleteCustomSetting() }
        }
    }
    
    // MARK: - Private

    private func setupNotificationSettingsSubscription() {
        notificationSettingsProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .settingsDidChange:
                    self.fetchNotificationSettings()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchNotificationSettings() {
        fetchNotificationSettingsTask = Task {
            await fetchRoomNotificationSettings()
        }
    }
    
    private func fetchRoomNotificationSettings() async {
        state.shouldDisplayMentionsOnlyDisclaimer = roomProxy.isEncrypted ? await !notificationSettingsProxy.canPushEncryptedEventsToDevice() : false
        do {
            // `isOneToOne` here is not the same as `isDirect` on the room. From the point of view of the push rule, a one-to-one room is a room with exactly two active members.
            let settings = try await notificationSettingsProxy.getNotificationSettings(roomId: roomProxy.id,
                                                                                       isEncrypted: roomProxy.isEncrypted,
                                                                                       isOneToOne: roomProxy.activeMembersCount == 2)
            guard !Task.isCancelled else { return }
            state.notificationSettingsState = .loaded(settings: settings)
            if !state.isRestoringDefaultSetting {
                state.bindings.allowCustomSetting = !settings.isDefault
            }
        } catch {
            state.notificationSettingsState = .error
            displayError(.loadingSettingsFailed)
        }
    }
    
    private func toogleCustomSetting() {
        guard case .loaded(let settings) = state.notificationSettingsState else { return }
        guard state.bindings.allowCustomSetting == settings.isDefault else { return }
        
        if state.bindings.allowCustomSetting {
            setCustomMode(settings.mode)
        } else {
            restoreDefaultSetting()
        }
    }
    
    private func restoreDefaultSetting() {
        state.isRestoringDefaultSetting = true
        Task {
            do {
                try await notificationSettingsProxy.restoreDefaultNotificationMode(roomId: roomProxy.id)
            } catch {
                displayError(.restoreDefaultFailed)
            }
            state.isRestoringDefaultSetting = false
        }
    }
    
    private func setCustomMode(_ mode: RoomNotificationModeProxy) {
        // Check if the new mode is already the current one
        if case .loaded(let currentSettings) = state.notificationSettingsState {
            if !currentSettings.isDefault, currentSettings.mode == mode {
                return
            }
        }
        
        state.pendingCustomMode = mode
        Task {
            do {
                try await notificationSettingsProxy.setNotificationMode(roomId: roomProxy.id, mode: mode)
            } catch {
                displayError(.setModeFailed)
            }
            state.pendingCustomMode = nil
        }
    }
    
    private func displayError(_ type: RoomNotificationSettingsScreenErrorType) {
        switch type {
        case .loadingSettingsFailed:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: L10n.screenRoomNotificationSettingsErrorLoadingSettings)
        case .setModeFailed:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: L10n.screenRoomNotificationSettingsErrorSettingMode)

        case .restoreDefaultFailed:
            state.bindings.alertInfo = AlertInfo(id: type,
                                                 title: L10n.commonError,
                                                 message: L10n.screenRoomNotificationSettingsErrorRestoringDefault)
        }
    }
    
    private func deleteCustomSetting() async {
        state.deletingCustomSetting = true
        do {
            try await notificationSettingsProxy.restoreDefaultNotificationMode(roomId: roomProxy.id)
            actionsSubject.send(.dismiss)
        } catch {
            displayError(.restoreDefaultFailed)
        }
        state.deletingCustomSetting = false
    }
}
