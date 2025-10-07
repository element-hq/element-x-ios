//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class LeaveSpaceHandleProxy: Identifiable {
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
                return .init(spaceRoomProxy: SpaceRoomProxy(spaceRoom: room.spaceRoom),
                             isLastAdmin: room.isLastAdmin,
                             isSelected: !room.isLastAdmin)
            }
        
        mode = if space?.isLastAdmin == true {
            .lastSpaceAdmin
        } else if rooms.isEmpty {
            .noRooms
        } else if rooms.count(where: { !$0.isLastAdmin }) == 0 {
            .onlyAdminRooms
        } else {
            .manyRooms
        }
    }
    
    func leave() async -> Result<Void, SpaceServiceProxyError> {
        let selectedRoomIDs = rooms.filter(\.isSelected).map(\.spaceRoomProxy.id)
        
        do {
            return try await .success(leaveHandle.leave(roomIds: selectedRoomIDs + [id]))
        } catch {
            MXLog.error("Failed leaving space \(id): \(error)")
            rooms = rooms.filter { leaveRoom in
                leaveHandle.rooms().contains { $0.spaceRoom.roomId == leaveRoom.spaceRoomProxy.id }
            }
            return .failure(.sdkError(error))
        }
    }
}

@Observable class LeaveSpaceRoomDetails {
    let spaceRoomProxy: SpaceRoomProxyProtocol
    let isLastAdmin: Bool
    var isSelected: Bool
    
    init(spaceRoomProxy: SpaceRoomProxyProtocol, isLastAdmin: Bool, isSelected: Bool) {
        self.spaceRoomProxy = spaceRoomProxy
        self.isLastAdmin = isLastAdmin
        self.isSelected = isSelected
    }
}
