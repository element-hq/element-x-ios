//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

final class LeaveSpaceHandleProxy {
    let id: String
    var rooms: [LeaveSpaceRoomDetails]
    
    enum Mode: Equatable {
        case manyRooms
        case roomsNeedNewOwner
        case noRooms
        case spaceNeedsNewOwner(useTransferOwnershipFlow: Bool)
    }
    
    let mode: Mode
    
    private let leaveHandle: LeaveSpaceHandleProtocol
    
    var canLeave: Bool {
        switch mode {
        case .spaceNeedsNewOwner:
            false
        default:
            true
        }
    }

    var selectedCount: Int {
        rooms.count { $0.isSelected }
    }
    
    init(spaceID: String, leaveHandle: LeaveSpaceHandleProtocol) {
        id = spaceID
        self.leaveHandle = leaveHandle
        
        let rooms = leaveHandle.rooms()
        let space = rooms.first { $0.spaceRoom.roomId == spaceID }
        
        self.rooms = rooms
            .compactMap { room in
                guard room.spaceRoom.state == .joined, // The SDK is going to do this but not yet.
                      room.spaceRoom.isDirect != true,
                      room.spaceRoom.roomId != spaceID else {
                    return nil
                }
                return .init(spaceServiceRoom: SpaceServiceRoom(spaceRoom: room.spaceRoom),
                             isLastOwner: room.isLastOwner,
                             areCreatorsPrivileged: room.areCreatorsPrivileged,
                             isSelected: !room.isLastOwner)
            }
        
        mode = if let space, space.isLastOwner, space.spaceRoom.numJoinedMembers > 1 {
            .spaceNeedsNewOwner(useTransferOwnershipFlow: space.areCreatorsPrivileged)
        } else if self.rooms.isEmpty {
            .noRooms
        } else if self.rooms.count(where: { $0.canLeave }) == 0 {
            .roomsNeedNewOwner
        } else {
            .manyRooms
        }
    }
    
    func deselectAll() {
        for room in rooms {
            room.isSelected = false
        }
    }
    
    func selectAll() {
        for room in rooms where room.canLeave {
            room.isSelected = true
        }
    }
    
    func toggleRoom(roomID: String) {
        guard let room = rooms.first(where: { $0.spaceServiceRoom.id == roomID }) else {
            return
        }
        room.isSelected.toggle()
    }
    
    func leave() async -> Result<Void, SpaceServiceProxyError> {
        let selectedRoomIDs = rooms.filter(\.isSelected).map(\.spaceServiceRoom.id)
        
        do {
            return try await .success(leaveHandle.leave(roomIds: selectedRoomIDs + [id]))
        } catch {
            MXLog.error("Failed leaving space \(id): \(error)")
            rooms = rooms.filter { leaveRoom in
                leaveHandle.rooms().contains { $0.spaceRoom.roomId == leaveRoom.spaceServiceRoom.id }
            }
            return .failure(.sdkError(error))
        }
    }
}

@Observable class LeaveSpaceRoomDetails {
    let spaceServiceRoom: SpaceServiceRoom
    let canLeave: Bool
    let areCreatorsPrivileged: Bool
    var isSelected: Bool
    
    init(spaceServiceRoom: SpaceServiceRoom, isLastOwner: Bool, areCreatorsPrivileged: Bool, isSelected: Bool) {
        self.spaceServiceRoom = spaceServiceRoom
        canLeave = !isLastOwner || spaceServiceRoom.joinedMembersCount == 1
        self.isSelected = isSelected
        self.areCreatorsPrivileged = areCreatorsPrivileged
    }
}
