//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias NotificationSettingsScreenViewModelType = StateStoreViewModelV2<NotificationSettingsScreenViewState, NotificationSettingsScreenViewAction>

class NotificationSettingsScreenViewModel: NotificationSettingsScreenViewModelType, NotificationSettingsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSettingsScreenViewModelAction, Never> = .init()
    private let appSettings: AppSettings
    private let userNotificationCenter: UserNotificationCenterProtocol
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    // periphery:ignore - cancellable tasks get cancelled when reassigned
    @CancellableTask private var fetchSettingsTask: Task<Void, Error>?
    private let notificationTonePreviewer: AudioPlayerProtocol
    private let notificationToneManager: NotificationToneManagerProtocol

    var actions: AnyPublisher<NotificationSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appSettings: AppSettings,
         userNotificationCenter: UserNotificationCenterProtocol,
         notificationToneManager: NotificationToneManagerProtocol,
         notificationSettingsProxy: NotificationSettingsProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         isModallyPresented: Bool) {
        self.appSettings = appSettings
        self.userNotificationCenter = userNotificationCenter
        self.notificationSettingsProxy = notificationSettingsProxy
        self.userIndicatorController = userIndicatorController
        notificationTonePreviewer = AudioPlayer()
        self.notificationToneManager = notificationToneManager
        
        let bindings = NotificationSettingsScreenViewStateBindings(enableNotifications: appSettings.enableNotifications)
        super.init(initialViewState: NotificationSettingsScreenViewState(bindings: bindings,
                                                                         isModallyPresented: isModallyPresented,
                                                                         selectedAlertTone: appSettings.selectedNotificationTone ?? NotificationToneManager.defaultElementXMessageTone,
                                                                         availableCustomTones: notificationToneManager.customTones()))

        // Listen for changes to AppSettings.
        appSettings.$enableNotifications
            .weakAssign(to: \.state.bindings.enableNotifications, on: self)
            .store(in: &cancellables)
        
        appSettings.$selectedNotificationTone
            .map { $0 ?? NotificationToneManager.defaultElementXMessageTone }
            .weakAssign(to: \.state.selectedAlertTone, on: self)
            .store(in: &cancellables)
        
        setupDidBecomeActiveSubscription()
        setupNotificationSettingsSubscription()
        
        notificationTonePreviewer.actions
            .receive(on: DispatchQueue.main)
            .sink { action in
                guard case .didFailWithError(let error) = action else {
                    return
                }
                let userIndicator = UserIndicator(type: .toast,
                                                  title: UntranslatedL10n.screenNotificationSettingsSoundPreviewSoundErrorTitle,
                                                  iconName: "exclamationmark.triangle.fill")
                userIndicatorController.submitIndicator(userIndicator)
                MXLog.error("Error previewing alert tone: \(error)")
            }
            .store(in: &cancellables)
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
        case .selectAlertTone(let alertTone):
            setSelectedTone(alertTone)
        case .addedCustomAlertTone(let result):
            Task {
                await self.addCustomAlertTone(from: result)
            }
        case .deleteCustomAlertTones(let tones):
            deleteAlertTones(tones)
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

    /// Imports the audio file at the given sandboxed URL into the tone library, refreshing the available custom tones on success.
    private func addCustomAlertTone(from urlResult: Result<URL, Error>) async {
        do {
            let url = try urlResult.get()
            guard url.startAccessingSecurityScopedResource() else {
                throw NotificationToneManager.ManagerError.couldNotAccessSandboxedResource
            }
            defer { url.stopAccessingSecurityScopedResource() }
            try await notificationToneManager.addNewToneToLibrary(from: url)
            state.availableCustomTones = notificationToneManager.customTones()
        } catch {
            MXLog.error("Error importing custom tone url: \(error)")
            userIndicatorController.submitIndicator(.init(type: .toast,
                                                          title: UntranslatedL10n.screenNotificationSettingsSoundImportSoundErrorTitle,
                                                          iconName: "exclamationmark.triangle.fill"))
        }
    }
    
    private func setSelectedTone(_ alertTone: NotificationTone) {
        do {
            notificationTonePreviewer.load(sourceURL: alertTone.location, playbackURL: alertTone.location, autoplay: true)
            try notificationToneManager.setSelectedTone(alertTone)
            MXLog.info("Successfully set selected tone: \(alertTone.label)")
        } catch {
            let userIndicator = UserIndicator(type: .toast,
                                              title: UntranslatedL10n.screenNotificationSettingsSoundSetSoundErrorTitle,
                                              iconName: "exclamationmark.triangle.fill")
            userIndicatorController.submitIndicator(userIndicator)
            MXLog.error("Error setting selected alert tone to designated location in filesystem: \(error)")
        }
    }

    /// Deletes the given tones from the library. If the active tone is deleted, the selection resets to the default.
    private func deleteAlertTones(_ tones: [NotificationTone]) {
        for tone in tones {
            do {
                try notificationToneManager.deleteCustomTone(tone)

                if tone == state.selectedAlertTone {
                    appSettings.selectedNotificationTone = nil
                }
            } catch {
                MXLog.error("Error deleting alert tone \(tone.label): \(error)")
                userIndicatorController.submitIndicator(.init(type: .toast,
                                                              title: UntranslatedL10n.screenNotificationSettingsSoundDeleteSoundErrorTitle,
                                                              iconName: "exclamationmark.triangle.fill"))
            }
        }
        state.availableCustomTones = notificationToneManager.customTones()
        MXLog.info("Successfully deleted custom tone(s): \(tones.map(\.label))")
    }
}

extension UNUserNotificationCenter {
    func authorizationStatus() async -> UNAuthorizationStatus {
        await notificationSettings().authorizationStatus
    }
}
