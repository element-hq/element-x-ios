//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

extension SpaceServiceProxyMock {
    struct Configuration {
        var topLevelSpaces: [SpaceServiceRoomProtocol] = []
        var joinedParentSpaces: [SpaceServiceRoomProtocol] = []
        var spaceRoomLists: [String: SpaceRoomListProxyMock] = [:]
        var leaveSpaceRooms: [LeaveSpaceRoom] = []
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        topLevelSpacesPublisher = .init(configuration.topLevelSpaces)
        joinedParentsChildIDReturnValue = .success(configuration.joinedParentSpaces)
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
        spaceForIdentifierSpaceIDClosure = { spaceID in
            .success(configuration.topLevelSpaces.first { $0.id == spaceID })
        }
    }
}

extension SpaceServiceProxyMock.Configuration {
    static var populated: SpaceServiceProxyMock.Configuration {
        let spaceRoomLists = [SpaceServiceRoomProtocol].mockJoinedSpaces.map {
            ($0.id, SpaceRoomListProxyMock(.init(spaceServiceRoom: $0, initialSpaceRooms: .mockSpaceList)))
        }
        let subSpaceRoomLists = [SpaceServiceRoomProtocol].mockSpaceList.map {
            ($0.id, SpaceRoomListProxyMock(.init(spaceServiceRoom: $0, initialSpaceRooms: .mockSingleRoom)))
        }
        
        return .init(topLevelSpaces: .mockJoinedSpaces, spaceRoomLists: .init(uniqueKeysWithValues: spaceRoomLists + subSpaceRoomLists))
    }
}
