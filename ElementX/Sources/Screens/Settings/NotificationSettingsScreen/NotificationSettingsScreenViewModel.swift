//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias NotificationSettingsScreenViewModelType = StateStoreViewModel<NotificationSettingsScreenViewState, NotificationSettingsScreenViewAction>

class NotificationSettingsScreenViewModel: NotificationSettingsScreenViewModelType, NotificationSettingsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSettingsScreenViewModelAction, Never> = .init()
    private let appSettings: AppSettings
    private let userNotificationCenter: UserNotificationCenterProtocol
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    // periphery:ignore - cancellable tasks get cancelled when reassigned
    @CancellableTask private var fetchSettingsTask: Task<Void, Error>?
    
    var actions: AnyPublisher<NotificationSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appSettings: AppSettings, userNotificationCenter: UserNotificationCenterProtocol, notificationSettingsProxy: NotificationSettingsProxyProtocol, isModallyPresented: Bool) {
        self.appSettings = appSettings
        self.userNotificationCenter = userNotificationCenter
        self.notificationSettingsProxy = notificationSettingsProxy
        
        let bindings = NotificationSettingsScreenViewStateBindings(enableNotifications: appSettings.enableNotifications)
        super.init(initialViewState: NotificationSettingsScreenViewState(bindings: bindings, isModallyPresented: isModallyPresented))
                
        // Listen for changes to AppSettings.
        appSettings.$enableNotifications
            .weakAssign(to: \.state.bindings.enableNotifications, on: self)
            .store(in: &cancellables)
        
        setupDidBecomeActiveSubscription()
        setupNotificationSettingsSubscription()
    }
    
    func fetchInitialContent() {
        fetchSettings()
    }
        
    // MARK: - Public
    
    override func process(viewAction: NotificationSettingsScreenViewAction) {
        switch viewAction {
        case .changedEnableNotifications:
            toggleNotifications()
        case .groupChatsTapped:
            actionsSubject.send(.editDefaultMode(chatType: .groupChat))
        case .directChatsTapped:
            actionsSubject.send(.editDefaultMode(chatType: .oneToOneChat))
        case .roomMentionChanged:
            guard let settings = state.settings, settings.roomMentionsEnabled != state.bindings.roomMentionsEnabled else {
                return
            }
            Task { await enableRoomMention(state.bindings.roomMentionsEnabled) }
        case .callsChanged:
            guard let settings = state.settings, settings.callsEnabled != state.bindings.callsEnabled else {
                return
            }
            Task { await enableCalls(state.bindings.callsEnabled) }
        case .invitationsChanged:
            guard let settings = state.settings, settings.invitationsEnabled != state.bindings.invitationsEnabled else {
                return
            }
            Task { await enableInvitations(state.bindings.invitationsEnabled) }
        case .close:
            actionsSubject.send(.close)
        case .fixConfigurationMismatchTapped:
            Task { await fixConfigurationMismatch() }
        }
    }
    
    // MARK: - Private
        
    func readSystemAuthorizationStatus() async {
        state.isUserPermissionGranted = await userNotificationCenter.authorizationStatus() == .authorized
    }

    func toggleNotifications() {
        appSettings.enableNotifications.toggle()
    }
    
    private func setupDidBecomeActiveSubscription() {
        // Refresh authorization status uppon UIApplication.didBecomeActiveNotification notification
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.readSystemAuthorizationStatus()
                }
            }
            .store(in: &cancellables)
        
        Task {
            await readSystemAuthorizationStatus()
        }
    }
    
    private func setupNotificationSettingsSubscription() {
        notificationSettingsProxy.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                
                switch callback {
                case .settingsDidChange:
                    self.fetchSettings()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchSettings() {
        fetchSettingsTask = Task {
            var inconsistentSettings: [NotificationSettingsScreenInvalidSetting] = []
            // Group chats
            var groupChatsMode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: false, isOneToOne: false)
            let encryptedGroupChatsMode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: true, isOneToOne: false)

            // Direct chats
            var directChatsMode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: false, isOneToOne: true)
            let encryptedDirectChatsMode = await notificationSettingsProxy.getDefaultRoomNotificationMode(isEncrypted: true, isOneToOne: true)
                        
            // Old clients were having specific settings for encrypted and unencrypted rooms,
            // so it's possible for `group chats` and `direct chats` settings to be inconsistent (e.g. encrypted `direct chats` can have a different mode that unencrypted `direct chats`)
            if groupChatsMode != encryptedGroupChatsMode {
                groupChatsMode = .allMessages
                // a default setting for a chat can only be `.allMessages` or `.mentionsAndKeywordsOnly`.
                inconsistentSettings.append(.init(chatType: .groupChat, isEncrypted: encryptedGroupChatsMode != .allMessages))
            }
            if directChatsMode != encryptedDirectChatsMode {
                directChatsMode = .allMessages
                // a default setting for a chat can only be `.allMessages` or `.mentionsAndKeywordsOnly`.
                inconsistentSettings.append(.init(chatType: .oneToOneChat, isEncrypted: encryptedDirectChatsMode != .allMessages))
            }
            
            // The following calls may fail if the associated push rule doesn't exist
            let roomMentionsEnabled = try? await notificationSettingsProxy.isRoomMentionEnabled()
            let callEnabled = try? await notificationSettingsProxy.isCallEnabled()
            let invitationsEnabled = try? await notificationSettingsProxy.isInviteForMeEnabled()
                        
            guard !Task.isCancelled else { return }

            let notificationSettings = NotificationSettingsScreenSettings(groupChatsMode: groupChatsMode,
                                                                          directChatsMode: directChatsMode,
                                                                          roomMentionsEnabled: roomMentionsEnabled,
                                                                          callsEnabled: callEnabled,
                                                                          invitationsEnabled: invitationsEnabled,
                                                                          inconsistentSettings: inconsistentSettings)

            state.settings = notificationSettings
            state.bindings.roomMentionsEnabled = notificationSettings.roomMentionsEnabled ?? false
            state.bindings.callsEnabled = notificationSettings.callsEnabled ?? false
            state.bindings.invitationsEnabled = notificationSettings.invitationsEnabled ?? false
        }
    }
    
    private func fixConfigurationMismatch() async {
        guard let settings = state.settings, !settings.inconsistentSettings.isEmpty, !state.fixingConfigurationMismatch else { return }
        state.fixingConfigurationMismatch = true
        
        var failures: [NotificationSettingsScreenInvalidSetting] = []
        for inconsistentSetting in settings.inconsistentSettings {
            do {
                try await notificationSettingsProxy.setDefaultRoomNotificationMode(isEncrypted: inconsistentSetting.isEncrypted, isOneToOne: inconsistentSetting.chatType == .oneToOneChat, mode: .allMessages)
            } catch {
                failures.append(inconsistentSetting)
            }
        }
        
        if !failures.isEmpty {
            state.bindings.alertInfo = AlertInfo(id: .fixMismatchConfigurationFailed,
                                                 title: L10n.commonError,
                                                 message: L10n.screenNotificationSettingsFailedFixingConfiguration,
                                                 primaryButton: .init(title: L10n.actionOk, action: nil))
        }
        state.fixingConfigurationMismatch = false
    }
    
    private func enableRoomMention(_ enable: Bool) async {
        guard let notificationSettings = state.settings else { return }
        do {
            state.applyingChange = true
            MXLog.info("setRoomMentionEnabled(\(enable))")
            try await notificationSettingsProxy.setRoomMentionEnabled(enabled: enable)
        } catch {
            state.bindings.alertInfo = AlertInfo(id: .alert)
            state.bindings.roomMentionsEnabled = notificationSettings.roomMentionsEnabled ?? false
        }
        state.applyingChange = false
    }
        
    func enableCalls(_ enable: Bool) async {
        guard let notificationSettings = state.settings else { return }
        do {
            state.applyingChange = true
            MXLog.info("setCallEnabled(\(enable))")
            try await notificationSettingsProxy.setCallEnabled(enabled: enable)
        } catch {
            state.bindings.alertInfo = AlertInfo(id: .alert)
            state.bindings.callsEnabled = notificationSettings.callsEnabled ?? false
        }
        state.applyingChange = false
    }
    
    func enableInvitations(_ enable: Bool) async {
        guard let notificationSettings = state.settings else { return }
        do {
            state.applyingChange = true
            MXLog.info("setInviteForMeEnabled(\(enable))")
            try await notificationSettingsProxy.setInviteForMeEnabled(enabled: enable)
        } catch {
            state.bindings.alertInfo = AlertInfo(id: .alert)
            state.bindings.callsEnabled = notificationSettings.invitationsEnabled ?? false
        }
        state.applyingChange = false
    }
}

extension UNUserNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}
