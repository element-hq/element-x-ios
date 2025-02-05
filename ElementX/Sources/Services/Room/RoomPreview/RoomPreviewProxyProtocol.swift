//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol RoomPreviewProxyProtocol {
    var info: RoomPreviewInfoProxy { get }
    var ownMembershipDetails: RoomMembershipDetailsProxyProtocol? { get async }
    
    /// Use this function to forget the room, should only be used if the current user membership is `banned`
    func forgetRoom() async -> Result<Void, RoomProxyError>
}
