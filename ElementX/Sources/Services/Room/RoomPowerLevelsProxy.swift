//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

struct RoomPowerLevelsProxy: RoomPowerLevelsProxyProtocol {
    private let powerLevels: RoomPowerLevels
    
    init(_ powerLevels: RoomPowerLevels) {
        self.powerLevels = powerLevels
    }
    
    var values: RoomPowerLevelsValues {
        powerLevels.values()
    }
    
    func canUser(userID: String, sendMessage messageType: MessageLikeEventType) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserSendMessage(userId: userID, message: messageType))
        } catch {
            MXLog.error("Failed checking if the user can send message with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUser(userID: String, sendStateEvent event: StateEventType) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserSendState(userId: userID, stateEvent: event))
        } catch {
            MXLog.error("Failed checking if the user can send \(event) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserInvite(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserInvite(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can invite with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserRedactOther(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserRedactOther(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can redact others with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserRedactOwn(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserRedactOwn(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can redact self with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserKick(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserKick(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can kick with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserBan(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserBan(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can ban with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserTriggerRoomNotification(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserTriggerRoomNotification(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can trigger room notification with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserPinOrUnpin(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserPinUnpin(userId: userID))
        } catch {
            MXLog.error("Failed checking if the user can pin or unnpin: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func canUserJoinCall(userID: String) -> Result<Bool, RoomProxyError> {
        do {
            return try .success(powerLevels.canUserSendState(userId: userID, stateEvent: .callMember))
        } catch {
            MXLog.error("Failed checking if the user can trigger room notification with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
