//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

struct RoomPowerLevelsProxyMockConfiguration {
    var canUserSendMessage = true
    var canUserSendState = false
    var canUserInvite = true
    var canUserRedactOther = false
    var canUserRedactOwn = true
    var canUserKick = false
    var canUserBan = false
    var canUserTriggerRoomNotification = false
    var canUserPin = true
    var canUserJoinCall = true
}

extension RoomPowerLevelsProxyMock {
    convenience init(configuration: RoomPowerLevelsProxyMockConfiguration) {
        self.init()
        
        underlyingValues = RoomPowerLevelsValues.mock
        
        canUserUserIDSendMessageReturnValue = .success(configuration.canUserSendMessage)
        canUserUserIDSendStateEventReturnValue = .success(configuration.canUserSendState)
        canUserInviteUserIDReturnValue = .success(configuration.canUserInvite)
        canUserRedactOtherUserIDReturnValue = .success(configuration.canUserRedactOther)
        canUserRedactOwnUserIDReturnValue = .success(configuration.canUserRedactOwn)
        canUserKickUserIDReturnValue = .success(configuration.canUserKick)
        canUserBanUserIDReturnValue = .success(configuration.canUserBan)
        canUserTriggerRoomNotificationUserIDReturnValue = .success(configuration.canUserTriggerRoomNotification)
        canUserPinOrUnpinUserIDReturnValue = .success(configuration.canUserPin)
        canUserJoinCallUserIDReturnValue = .success(configuration.canUserJoinCall)
    }
}

extension RoomPowerLevelsValues {
    static var mock: RoomPowerLevelsValues {
        RoomPowerLevelsValues(ban: 50,
                              invite: 0,
                              kick: 50,
                              redact: 50,
                              eventsDefault: 0,
                              stateDefault: 50,
                              usersDefault: 0,
                              roomName: 50,
                              roomAvatar: 50,
                              roomTopic: 50)
    }
}
