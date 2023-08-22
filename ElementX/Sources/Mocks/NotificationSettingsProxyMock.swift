//
// Copyright 2023 New Vector Ltd
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
import Foundation
import MatrixRustSDK

struct NotificationSettingsProxyMockConfiguration {
    var callback = PassthroughSubject<NotificationSettingsProxyCallback, Never>()
    var defaultRoomMode: RoomNotificationModeProxy
    var roomMode: RoomNotificationSettingsProxyMock
    
    init(defaultRoomMode: RoomNotificationModeProxy = .allMessages, roomMode: RoomNotificationModeProxy = .allMessages) {
        self.defaultRoomMode = defaultRoomMode
        self.roomMode = RoomNotificationSettingsProxyMock(with: RoomNotificationSettingsProxyMockConfiguration(mode: roomMode, isDefault: defaultRoomMode == roomMode))
    }
}

extension NotificationSettingsProxyMock {
    convenience init(with configuration: NotificationSettingsProxyMockConfiguration) {
        self.init()
        
        callbacks = configuration.callback
        getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = configuration.roomMode
        getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = configuration.defaultRoomMode
        getUserDefinedRoomNotificationModeRoomIdReturnValue = configuration.roomMode.isDefault ? nil : configuration.roomMode.mode
        getRoomsWithUserDefinedRulesReturnValue = []
        isRoomMentionEnabledReturnValue = true
        isCallEnabledReturnValue = true
        
        setNotificationModeRoomIdModeClosure = { [weak self] _, mode in
            guard let self else { return }
            self.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: mode, isDefault: false))
            Task {
                self.callbacks.send(.settingsDidChange)
            }
        }
        
        setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeClosure = { [weak self] _, _, mode in
            guard let self else { return }
            self.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = mode
            Task {
                self.callbacks.send(.settingsDidChange)
            }
        }

        restoreDefaultNotificationModeRoomIdClosure = { [weak self] _ in
            guard let self else { return }
            self.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: configuration.defaultRoomMode, isDefault: true))
            Task {
                self.callbacks.send(.settingsDidChange)
            }
        }
        
        setRoomMentionEnabledEnabledClosure = { [weak self] enabled in
            guard let self else { return }
            self.isRoomMentionEnabledReturnValue = enabled
            Task {
                self.callbacks.send(.settingsDidChange)
            }
        }
        
        setCallEnabledEnabledClosure = { [weak self] enabled in
            guard let self else { return }
            self.isCallEnabledReturnValue = enabled
            Task {
                self.callbacks.send(.settingsDidChange)
            }
        }
    }
}
