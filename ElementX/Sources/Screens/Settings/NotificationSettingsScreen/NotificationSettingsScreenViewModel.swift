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
    
    func start() {
        fetchSettings()
    }
        
    // MARK: - Public
    
    override func process(viewAction: NotificationSettingsScreenViewAction) {
        switch viewAction {
        case .linkClicked(let url):
            MXLog.warning("Link clicked: \(url)")
        case .changedEnableNotifications:
            toggleNotifications()
        case .processTapGroupChats:
            break
        case .processTapDirectChats:
            break
        case .processToggleRoomMention:
            toggleRoomMention()
        case .processToggleCalls:
            toggleCalls()
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
    
    private struct Settings {
        var groupChatsMode: RoomNotificationModeProxy = .allMessages
        var encryptedGroupChatsMode: RoomNotificationModeProxy = .allMessages
        var directChatsMode: RoomNotificationModeProxy = .allMessages
        var encryptedDirectChatsMode: RoomNotificationModeProxy = .allMessages
        var roomMentionState: Result<Bool, Error> = .success(false)
        var callState: Result<Bool, Error> = .success(false)
    }

    private func fetchSettings() {
        fetchSettingsTask = Task {
            var settings = Settings()
            
            // Group chats
            settings.groupChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: false, activeMembersCount: 3)
            settings.encryptedGroupChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: true, activeMembersCount: 3)

            // Direct chats
            settings.directChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: false, activeMembersCount: 2)
            settings.encryptedDirectChatsMode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: true, activeMembersCount: 2)

            // Room mentions
            do {
                settings.roomMentionState = try await .success(notificationSettingsProxy.isRoomMentionEnabled())
            } catch {
                settings.roomMentionState = .failure(error)
            }
            
            // Calls
            do {
                settings.callState = try await .success(notificationSettingsProxy.isCallEnabled())
            } catch {
                settings.callState = .failure(error)
            }
            
            guard !Task.isCancelled else { return }
            
            applySettings(settings)
        }
    }
    
    private func applySettings(_ settings: Settings) {
        if settings.groupChatsMode == settings.encryptedGroupChatsMode {
            state.groupChatNotificationSettingsState = .loaded(mode: settings.groupChatsMode)
            state.inconsistentGroupChatsSettings = false
        } else {
            state.groupChatNotificationSettingsState = .loaded(mode: .allMessages)
            state.inconsistentGroupChatsSettings = true
        }
        
        if settings.directChatsMode == settings.encryptedDirectChatsMode {
            state.directChatNotificationSettingsState = .loaded(mode: settings.directChatsMode)
            state.inconsistentDirectChatsSettings = false
        } else {
            state.directChatNotificationSettingsState = .loaded(mode: .allMessages)
            state.inconsistentDirectChatsSettings = true
        }
        
        if case .success(let enabled) = settings.roomMentionState {
            state.bindings.enableRoomMention = enabled
        } else {
            state.bindings.enableRoomMention = false
        }
        
        if case .success(let enabled) = settings.callState {
            state.bindings.enableCalls = enabled
        } else {
            state.bindings.enableCalls = false
        }
    }
    
    private func toggleRoomMention() {
        Task {
            do {
                let currentValue = try await notificationSettingsProxy.isRoomMentionEnabled()
                let newValue = state.bindings.enableRoomMention
                guard currentValue != newValue else { return }
                state.applyingChange = true
                try await notificationSettingsProxy.setRoomMentionEnabled(enabled: newValue)
            } catch {
                state.bindings.alertInfo = AlertInfo(id: .alert)
            }
            state.applyingChange = false
        }
    }
        
    func toggleCalls() {
        Task {
            do {
                let currentValue = try await notificationSettingsProxy.isCallEnabled()
                let newValue = state.bindings.enableCalls
                guard currentValue != newValue else { return }
                state.applyingChange = true
                try await notificationSettingsProxy.setCallEnabled(enabled: newValue)
            } catch {
                state.bindings.alertInfo = AlertInfo(id: .alert)
            }
            state.applyingChange = false
        }
    }
}
