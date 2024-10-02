//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

struct NotificationSettingsProxyMockConfiguration {
    var callback = PassthroughSubject<NotificationSettingsProxyCallback, Never>()
    var defaultRoomMode: RoomNotificationModeProxy
    var roomMode: RoomNotificationSettingsProxyMock
    var canPushEncryptedEvents = false
    
    init(defaultRoomMode: RoomNotificationModeProxy = .allMessages, roomMode: RoomNotificationModeProxy = .allMessages, canPushEncryptedEvents: Bool = false) {
        self.defaultRoomMode = defaultRoomMode
        self.roomMode = RoomNotificationSettingsProxyMock(with: RoomNotificationSettingsProxyMockConfiguration(mode: roomMode, isDefault: defaultRoomMode == roomMode))
        self.canPushEncryptedEvents = canPushEncryptedEvents
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
        isInviteForMeEnabledReturnValue = true
        
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
        
        setInviteForMeEnabledEnabledClosure = { [weak self] enabled in
            guard let self else { return }
            self.isInviteForMeEnabledReturnValue = enabled
            Task {
                self.callbacks.send(.settingsDidChange)
            }
        }
        
        canPushEncryptedEventsToDeviceClosure = {
            configuration.canPushEncryptedEvents
        }
    }
}
