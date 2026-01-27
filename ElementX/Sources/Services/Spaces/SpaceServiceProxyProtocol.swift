//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum SpaceServiceProxyError: Error {
    case sdkError(Error)
    case missingSpace
}

struct SpaceServiceFilter: Identifiable, Equatable {
    let room: SpaceServiceRoom
    let level: UInt
    let descendants: Set<String>
    
    init(room: SpaceServiceRoom, level: UInt, descendants: Set<String>) {
        self.room = room
        self.level = level
        self.descendants = descendants
    }
    
    init(filter: SpaceFilter) {
        room = SpaceServiceRoom(spaceRoom: filter.spaceRoom)
        level = UInt(max(filter.level, 0))
        descendants = Set(filter.descendants)
    }
    
    /// Same rooms might appear on multiple levels
    var id: String {
        room.id + "\(level)"
    }
    
    static func == (lhs: SpaceServiceFilter, rhs: SpaceServiceFilter) -> Bool {
        lhs.room.id == rhs.room.id
    }
}

// sourcery: AutoMockable
protocol SpaceServiceProxyProtocol {
    var topLevelSpacesPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never> { get }
    var spaceFilterPublisher: CurrentValuePublisher<[SpaceServiceFilter], Never> { get }
    
    func spaceRoomList(spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError>
    /// Returns a joined space given its identifier
    func spaceForIdentifier(spaceID: String) async -> Result<SpaceServiceRoom?, SpaceServiceProxyError>
    func leaveSpace(spaceID: String) async -> Result<LeaveSpaceHandleProxy, SpaceServiceProxyError>
    /// Returns all the parent spaces of a child that user has joined.
    func joinedParents(childID: String) async -> Result<[SpaceServiceRoom], SpaceServiceProxyError>
    /// Returns all the joined spaces that can be edited by the user
    func editableSpaces() async -> [SpaceServiceRoom]
    
    /// Adds a room (or space) as a child of another space.
    func addChild(_ childID: String, to spaceID: String) async -> Result<Void, SpaceServiceProxyError>
    func removeChild(_ childID: String, from spaceID: String) async -> Result<Void, SpaceServiceProxyError>
}
