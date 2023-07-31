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

typealias NotificationSettingsScreenViewModelType = StateStoreViewModel<NotificationSettingsScreenViewState, NotificationSettingsScreenViewAction>

class NotificationSettingsScreenViewModel: NotificationSettingsScreenViewModelType, NotificationSettingsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSettingsScreenViewModelAction, Never> = .init()
    private let appSettings: AppSettings
    private let userNotificationCenter: UserNotificationCenterProtocol
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    @CancellableTask private var fetchSettingsTask: Task<Void, Error>?
    
    var actions: AnyPublisher<NotificationSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appSettings: AppSettings, userNotificationCenter: UserNotificationCenterProtocol, notificationSettingsProxy: NotificationSettingsProxyProtocol) {
        self.appSettings = appSettings
        self.userNotificationCenter = userNotificationCenter
        self.notificationSettingsProxy = notificationSettingsProxy
        
        let bindings = NotificationSettingsScreenViewStateBindings(enableNotifications: appSettings.enableNotifications)
        super.init(initialViewState: NotificationSettingsScreenViewState(bindings: bindings))
                
        // Listen for changes to AppSettings.enableNotifications
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
        case .linkClicked(let url):
            MXLog.warning("Link clicked: \(url)")
        case .changedEnableNotifications:
            toggleNotifications()
        case .groupChatsTapped:
            break
        case .directChatsTapped:
            break
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
            // Group chats
            // A group chat is a chat having more than 2 active members
            let groupChatActiveMembers: UInt64 = 3
            var groupChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: false, activeMembersCount: groupChatActiveMembers)
            let encryptedGroupChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: true, activeMembersCount: groupChatActiveMembers)

            // Direct chats
            // A direct chat is a chat having exactly 2 active members
            let directChatActiveMembers: UInt64 = 2
            var directChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: false, activeMembersCount: directChatActiveMembers)
            let encryptedDirectChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: true, activeMembersCount: directChatActiveMembers)
                        
            // Old clients were having specific settings for encrypted and unencrypted rooms,
            // so it's possible for `group chats` and `direct chats` settings to be inconsistent (e.g. encrypted `direct chats` can have a different mode that unencrypted `direct chats`)
            var inconsistencyDetected = false
            if groupChatsMode != encryptedGroupChatsMode {
                groupChatsMode = .allMessages
                inconsistencyDetected = true
            }
            if directChatsMode != encryptedDirectChatsMode {
                directChatsMode = .allMessages
                inconsistencyDetected = true
            }
            
            // The following calls may fail if the associated push rule doesn't exist
            let roomMentionsEnabled = try? await notificationSettingsProxy.isRoomMentionEnabled()
            let callEnabled = try? await notificationSettingsProxy.isCallEnabled()
                        
            guard !Task.isCancelled else { return }

            let notificationSettings = NotificationSettingsScreenSettings(groupChatsMode: groupChatsMode,
                                                                          directChatsMode: directChatsMode,
                                                                          roomMentionsEnabled: roomMentionsEnabled,
                                                                          callsEnabled: callEnabled,
                                                                          inconsistentSettings: inconsistencyDetected)

            state.settings = notificationSettings
            state.bindings.roomMentionsEnabled = notificationSettings.roomMentionsEnabled ?? false
            state.bindings.callsEnabled = notificationSettings.callsEnabled ?? false
        }
    }
    
    private func enableRoomMention(_ enable: Bool) async {
        guard let notificationSettings = state.settings else { return }
        do {
            state.applyingChange = true
            MXLog.info("[NotificationSettingsScreenViewMode] setRoomMentionEnabled(\(enable))")
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
            MXLog.info("[NotificationSettingsScreenViewMode] setCallEnabled(\(enable))")
            try await notificationSettingsProxy.setCallEnabled(enabled: enable)
        } catch {
            state.bindings.alertInfo = AlertInfo(id: .alert)
            state.bindings.callsEnabled = notificationSettings.callsEnabled ?? false
        }
        state.applyingChange = false
    }
}
