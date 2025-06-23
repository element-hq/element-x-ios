//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

// sourcery: AutoMockable
protocol RoomPowerLevelsProxyProtocol {
    var values: RoomPowerLevelsValues { get }
    
    func canUser(userID: String, sendMessage messageType: MessageLikeEventType) -> Result<Bool, RoomProxyError>
    func canUser(userID: String, sendStateEvent event: StateEventType) -> Result<Bool, RoomProxyError>
    func canUserInvite(userID: String) -> Result<Bool, RoomProxyError>
    func canUserRedactOther(userID: String) -> Result<Bool, RoomProxyError>
    func canUserRedactOwn(userID: String) -> Result<Bool, RoomProxyError>
    func canUserKick(userID: String) -> Result<Bool, RoomProxyError>
    func canUserBan(userID: String) -> Result<Bool, RoomProxyError>
    func canUserTriggerRoomNotification(userID: String) -> Result<Bool, RoomProxyError>
    func canUserPinOrUnpin(userID: String) -> Result<Bool, RoomProxyError>
    func canUserJoinCall(userID: String) -> Result<Bool, RoomProxyError>
}
