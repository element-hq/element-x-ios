//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

extension SpaceServiceProxyMock {
    struct Configuration {
        var joinedSpaces: [SpaceRoomProxyProtocol] = []
        var spaceRoomLists: [String: SpaceRoomListProxyMock] = [:]
        var leaveSpaceRooms: [LeaveSpaceRoom] = []
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        joinedSpacesPublisher = .init(configuration.joinedSpaces)
        spaceRoomListSpaceIDClosure = { spaceID in
            if let spaceRoomList = configuration.spaceRoomLists[spaceID] {
                .success(spaceRoomList)
            } else {
                .failure(.sdkError(ClientProxyMockError.generic))
            }
        }
        leaveSpaceSpaceIDClosure = { spaceID in
            .success(LeaveSpaceHandleProxy(spaceID: spaceID,
                                           leaveHandle: LeaveSpaceHandleSDKMock(.init(rooms: configuration.leaveSpaceRooms))))
        }
    }
}

extension SpaceServiceProxyMock.Configuration {
    static var populated: SpaceServiceProxyMock.Configuration {
        let spaceRoomLists = [SpaceRoomProxyProtocol].mockJoinedSpaces.map {
            ($0.id, SpaceRoomListProxyMock(.init(spaceRoomProxy: $0, initialSpaceRooms: .mockSpaceList)))
        }
        let subSpaceRoomLists = [SpaceRoomProxyProtocol].mockSpaceList.map {
            ($0.id, SpaceRoomListProxyMock(.init(spaceRoomProxy: $0, initialSpaceRooms: .mockSingleRoom)))
        }
        
        return .init(joinedSpaces: .mockJoinedSpaces, spaceRoomLists: .init(uniqueKeysWithValues: spaceRoomLists + subSpaceRoomLists))
    }
}
