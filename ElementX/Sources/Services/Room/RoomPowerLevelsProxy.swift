//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

nonisolated struct RoomPowerLevelsProxy: RoomPowerLevelsProxyProtocol {
    private let powerLevels: RoomPowerLevels
    
    init?(_ powerLevels: RoomPowerLevels?) {
        guard let powerLevels else {
            return nil
        }
        
        self.powerLevels = powerLevels
    }
    
    var values: RoomPowerLevelsValues {
        powerLevels.values()
    }
    
    var userPowerLevels: [String: Int64] {
        powerLevels.userPowerLevels()
    }
    
    func canOwnUser(sendMessage messageType: MessageLikeEventType) -> Bool {
        powerLevels.canOwnUserSendMessage(message: messageType)
    }
    
    func canOwnUser(sendStateEvent stateEventType: StateEventType) -> Bool {
        powerLevels.canOwnUserSendState(stateEvent: stateEventType)
    }
    
    func canOwnUserInvite() -> Bool {
        powerLevels.canOwnUserInvite()
    }
    
    func canOwnUserRedactOther() -> Bool {
        powerLevels.canOwnUserRedactOther()
    }
    
    func canOwnUserRedactOwn() -> Bool {
        powerLevels.canOwnUserRedactOwn()
    }
    
    func canOwnUserKick() -> Bool {
        powerLevels.canOwnUserKick()
    }
    
    func canOwnUserBan() -> Bool {
        powerLevels.canOwnUserBan()
    }
    
    func canOwnUserTriggerRoomNotification() -> Bool {
        powerLevels.canOwnUserTriggerRoomNotification()
    }
    
    func canOwnUserPinOrUnpin() -> Bool {
        powerLevels.canOwnUserPinUnpin()
    }
    
    func canOwnUserJoinCall() -> Bool {
        powerLevels.canOwnUserSendState(stateEvent: .callMember)
    }
    
    func canOwnUserEditRolesAndPermissions() -> Bool {
        powerLevels.canOwnUserSendState(stateEvent: .roomPowerLevels)
    }
}
