//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

extension RoomPowerLevelsProxyMock {
    struct Configuration { }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        underlyingValues = RoomPowerLevelsValues.mock
        
        canUserUserIDSendMessageReturnValue = .success(true)
        canUserUserIDSendStateEventReturnValue = .success(true)
        canUserInviteUserIDReturnValue = .success(true)
        canUserRedactOtherUserIDReturnValue = .success(true)
        canUserRedactOwnUserIDReturnValue = .success(true)
        canUserKickUserIDReturnValue = .success(true)
        canUserBanUserIDReturnValue = .success(true)
        canUserTriggerRoomNotificationUserIDReturnValue = .success(true)
        canUserPinOrUnpinUserIDReturnValue = .success(true)
        canUserJoinCallUserIDReturnValue = .success(true)
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
