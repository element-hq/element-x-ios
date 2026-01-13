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
    
    enum Mode { case manyRooms, onlyAdminRooms, noRooms, lastSpaceAdmin }
    let mode: Mode
    
    private let leaveHandle: LeaveSpaceHandleProtocol
    
    var canLeave: Bool { mode != .lastSpaceAdmin }
    var selectedCount: Int { rooms.count { $0.isSelected } }
    
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
                             isLastAdmin: room.isLastAdmin,
                             isSelected: !room.isLastAdmin)
            }
        
        mode = if space?.isLastAdmin == true {
            .lastSpaceAdmin
        } else if self.rooms.isEmpty {
            .noRooms
        } else if self.rooms.count(where: { !$0.isLastAdmin }) == 0 {
            .onlyAdminRooms
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
        for room in rooms where !room.isLastAdmin {
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
    let spaceServiceRoom: SpaceServiceRoomProtocol
    let isLastAdmin: Bool
    var isSelected: Bool
    
    init(spaceServiceRoom: SpaceServiceRoomProtocol, isLastAdmin: Bool, isSelected: Bool) {
        self.spaceServiceRoom = spaceServiceRoom
        self.isLastAdmin = isLastAdmin
        self.isSelected = isSelected
    }
}
