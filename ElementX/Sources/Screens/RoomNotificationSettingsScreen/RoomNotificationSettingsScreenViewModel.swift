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
import MatrixRustSDK
import SwiftUI

typealias RoomNotificationSettingsScreenViewModelType = StateStoreViewModel<RoomNotificationSettingsScreenViewState, RoomNotificationSettingsScreenViewAction>

class RoomNotificationSettingsScreenViewModel: RoomNotificationSettingsScreenViewModelType, RoomNotificationSettingsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<RoomNotificationSettingsScreenViewModelAction, Never> = .init()
    private var notificationSettingsProxy: NotificationSettingsProxyProtocol!
    private var roomProxy: RoomProxyProtocol!
    
    var actions: AnyPublisher<RoomNotificationSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(notificationSettingsProxy: NotificationSettingsProxyProtocol, roomProxy: RoomProxyProtocol) {
        let bindings = RoomNotificationSettingsScreenViewStateBindings()
        super.init(initialViewState: RoomNotificationSettingsScreenViewState(bindings: bindings))
        self.notificationSettingsProxy = notificationSettingsProxy
        self.roomProxy = roomProxy
        
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
        Task {
            await fetchRoomNotificationSettings()
        }
    }
    
    private func fetchRoomNotificationSettings() async {
        do {
            let settings = try await notificationSettingsProxy.getNotificationSettings(roomId: roomProxy.id,
                                                                                       isEncrypted: roomProxy.isEncrypted,
                                                                                       activeMembersCount: UInt64(roomProxy.activeMembersCount))
            state.notificationSettingsState = .loaded(settings: settings)
            state.bindings.allowCustomSetting = !settings.isDefault
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
        state.isRestoringDefautSetting = true
        Task {
            do {
                try await notificationSettingsProxy.restoreDefaultNotificationMode(roomId: roomProxy.id)
            } catch {
                displayError(.restoreDefaultFailed)
            }
            state.isRestoringDefautSetting = false
        }
    }
    
    private func setCustomMode(_ mode: RoomNotificationMode) {
        state.applyingCustomMode = mode
        Task {
            do {
                try await notificationSettingsProxy.setNotificationMode(roomId: roomProxy.id, mode: mode)
            } catch {
                displayError(.setModeFailed)
            }
            state.applyingCustomMode = nil
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
}
