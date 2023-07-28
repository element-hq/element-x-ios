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

typealias NotificationSettingsEditScreenViewModelType = StateStoreViewModel<NotificationSettingsEditScreenViewState, NotificationSettingsEditScreenViewAction>

class NotificationSettingsEditScreenViewModel: NotificationSettingsEditScreenViewModelType, NotificationSettingsEditScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSettingsEditScreenViewModelAction, Never> = .init()
    private let isDirect: Bool
    private let notificationSettingsProxy: NotificationSettingsProxyProtocol
    @CancellableTask private var fetchSettingsTask: Task<Void, Error>?
    
    var actions: AnyPublisher<NotificationSettingsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(isDirect: Bool, notificationSettingsProxy: NotificationSettingsProxyProtocol) {
        let bindings = NotificationSettingsEditScreenViewStateBindings()
        self.isDirect = isDirect
        self.notificationSettingsProxy = notificationSettingsProxy
        super.init(initialViewState: NotificationSettingsEditScreenViewState(bindings: bindings,
                                                                             strings: NotificationSettingsEditScreenStrings(isDirect: isDirect),
                                                                             isDirect: isDirect))
        
        setupNotificationSettingsSubscription()
    }
    
    func fetchInitialContent() {
        fetchSettings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: NotificationSettingsEditScreenViewAction) {
        switch viewAction {
        case .setMode(let mode):
            setMode(mode)
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
                    self.fetchSettings()
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchSettings() {
        fetchSettingsTask = Task {
            let mode: RoomNotificationModeProxy
            if isDirect {
                let encrypted_mode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: true, activeMembersCount: 2)
                let unencrypted_mode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: false, activeMembersCount: 2)
                mode = encrypted_mode != unencrypted_mode ? .allMessages : encrypted_mode
            } else {
                let encrypted_mode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: true, activeMembersCount: 3)
                let unencrypted_mode = await notificationSettingsProxy.getDefaultNotificationRoomMode(isEncrypted: false, activeMembersCount: 3)
                mode = encrypted_mode != unencrypted_mode ? .allMessages : encrypted_mode
            }
            
            guard !Task.isCancelled else { return }
            
            switch mode {
            case .allMessages:
                state.defaultMode = .allMessages
            case .mentionsAndKeywordsOnly:
                state.defaultMode = .mentionsAndKeywordsOnly
            default:
                state.defaultMode = nil
            }
        }
    }
    
    private func setMode(_ mode: NotificationSettingsEditScreenDefaultMode) {
        guard state.pendingMode == nil else { return }
        let roomNotificationModeProxy: RoomNotificationModeProxy
        switch mode {
        case .allMessages:
            roomNotificationModeProxy = .allMessages
        case .mentionsAndKeywordsOnly:
            roomNotificationModeProxy = .mentionsAndKeywordsOnly
        }
        state.pendingMode = mode
        Task {
            do {
                try await notificationSettingsProxy.setDefaultRoomNotificationMode(isEncrypted: true, isOneToOne: isDirect, mode: roomNotificationModeProxy)
                try await notificationSettingsProxy.setDefaultRoomNotificationMode(isEncrypted: false, isOneToOne: isDirect, mode: roomNotificationModeProxy)
            } catch {
                state.bindings.alertInfo = AlertInfo(id: .setModeFailed)
            }
            state.pendingMode = nil
        }
    }
}
