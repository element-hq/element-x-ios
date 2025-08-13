//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension SpaceRoomListProxyMock {
    struct Configuration {
        var spaceRoomProxy: SpaceRoomProxyProtocol
        var spaceRooms: [SpaceRoomProxyProtocol] = []
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        spaceRoom = configuration.spaceRoomProxy
        spaceRoomsPublisher = .init(configuration.spaceRooms)
    }
}
