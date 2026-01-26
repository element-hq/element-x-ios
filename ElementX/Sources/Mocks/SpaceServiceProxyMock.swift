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

enum SpaceServiceProxyMockError: Error {
    case generic
}

extension SpaceServiceProxyMock {
    struct Configuration {
        var topLevelSpaces: [SpaceServiceRoom] = []
        var spaceFilters: [SpaceServiceFilter] = []
        var joinedParentSpaces: [SpaceServiceRoom] = []
        var editableSpaces: [SpaceServiceRoom] = []
        var spaceRoomLists: [String: SpaceRoomListProxyMock] = [:]
        var leaveSpaceRooms: [LeaveSpaceRoom] = []
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        topLevelSpacesPublisher = .init(configuration.topLevelSpaces)
        spaceFilterPublisher = .init(configuration.spaceFilters)
        
        joinedParentsChildIDReturnValue = .success(configuration.joinedParentSpaces)
        editableSpacesReturnValue = configuration.editableSpaces
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
        addChildToReturnValue = .success(())
        removeChildFromReturnValue = .success(())
    }
}

extension SpaceServiceProxyMock.Configuration {
    static var populated: SpaceServiceProxyMock.Configuration {
        let spaceFilters = [SpaceServiceRoom].mockJoinedSpaces.reduce(into: [SpaceServiceFilter]()) { partialResult, spaceRoom in
            partialResult.append(SpaceServiceFilter(room: spaceRoom, level: 0, descendants: .init()))
            partialResult.append(SpaceServiceFilter(room: spaceRoom, level: 1, descendants: .init()))
        }
                
        let spaceRoomLists = [SpaceServiceRoom].mockJoinedSpaces.map {
            ($0.id, SpaceRoomListProxyMock(.init(spaceServiceRoom: $0, initialSpaceRooms: .mockSpaceList)))
        }
        
        let subSpaceRoomLists = [SpaceServiceRoom].mockSpaceList.map {
            ($0.id, SpaceRoomListProxyMock(.init(spaceServiceRoom: $0, initialSpaceRooms: .mockSingleRoom)))
        }
        
        return .init(topLevelSpaces: .mockJoinedSpaces,
                     spaceFilters: spaceFilters,
                     spaceRoomLists: .init(uniqueKeysWithValues: spaceRoomLists + subSpaceRoomLists))
    }
}
