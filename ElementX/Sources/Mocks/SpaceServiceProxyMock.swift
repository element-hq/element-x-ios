//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension SpaceServiceProxyMock {
    struct Configuration {
        var joinedSpaces: [SpaceRoomProxyProtocol] = []
        var spaceRoomLists: [String: SpaceRoomListProxyMock] = [:]
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        joinedSpacesPublisher = .init(configuration.joinedSpaces)
        spaceRoomListForClosure = { spaceRoom in
            if let spaceRoomList = configuration.spaceRoomLists[spaceRoom.id] {
                .success(spaceRoomList)
            } else {
                .failure(.sdkError(ClientProxyMockError.generic))
            }
        }
    }
}
