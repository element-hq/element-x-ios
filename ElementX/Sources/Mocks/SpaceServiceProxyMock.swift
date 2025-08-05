//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

extension SpaceServiceProxyMock {
    struct Configuration {
        var joinedSpaces: [SpaceRoomProxyProtocol] = []
        var spaceRoomLists: [String: SpaceRoomListProxyMock] = [:]
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        joinedSpacesReturnValue = configuration.joinedSpaces
        spaceRoomListForClosure = { spaceID in
            if let spaceRoomList = configuration.spaceRoomLists[spaceID] {
                .success(spaceRoomList)
            } else {
                .failure(.sdkError(ClientProxyMockError.generic))
            }
        }
    }
}
