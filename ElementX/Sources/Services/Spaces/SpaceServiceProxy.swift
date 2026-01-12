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

class SpaceServiceProxy: SpaceServiceProxyProtocol {
    private let spaceService: SpaceServiceProtocol
    
    private var topLevelSpacesHandle: TaskHandle?
    private let spacesSubject = CurrentValueSubject<[SpaceServiceRoomProtocol], Never>([])
    var topLevelSpacesPublisher: CurrentValuePublisher<[SpaceServiceRoomProtocol], Never> {
        spacesSubject.asCurrentValuePublisher()
    }
    
    init(spaceService: SpaceServiceProtocol) {
        self.spaceService = spaceService
        
        Task { await setupSubscriptions() }
    }
    
    private func setupSubscriptions() async {
        topLevelSpacesHandle = await spaceService.subscribeToTopLevelJoinedSpaces(listener: SDKListener { [weak self] updates in
            self?.handleUpdates(updates)
        })
    }
    
    func spaceRoomList(spaceID: String) async -> Result<SpaceRoomListProxyProtocol, SpaceServiceProxyError> {
        do {
            return try await .success(SpaceRoomListProxy(spaceService.spaceRoomList(spaceId: spaceID)))
        } catch {
            MXLog.error("Failed creating space room list for \(spaceID): \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func spaceForIdentifier(spaceID: String) async -> Result<SpaceServiceRoomProtocol?, SpaceServiceProxyError> {
        do {
            return try await .success(spaceService.getSpaceRoom(roomId: spaceID).map(SpaceServiceRoom.init))
        } catch {
            MXLog.error("Failed getting space room for \(spaceID): \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func leaveSpace(spaceID: String) async -> Result<LeaveSpaceHandleProxy, SpaceServiceProxyError> {
        do {
            return try await .success(.init(spaceID: spaceID, leaveHandle: spaceService.leaveSpace(spaceId: spaceID)))
        } catch {
            MXLog.error("Failed to get leave handle for \(spaceID): \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func joinedParents(childID: String) async -> Result<[SpaceServiceRoomProtocol], SpaceServiceProxyError> {
        do {
            return try await .success(spaceService.joinedParentsOfChild(childId: childID).map(SpaceServiceRoom.init))
        } catch {
            MXLog.error("Failed to get joined parents for \(childID): \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Private
    
    private func handleUpdates(_ updates: [SpaceListUpdate]) {
        var spaces = spacesSubject.value
        
        for update in updates {
            switch update {
            case .append(let spaceRooms):
                spaces.append(contentsOf: spaceRooms.map(SpaceServiceRoom.init))
            case .clear:
                spaces.removeAll()
            case .pushFront(let spaceRoom):
                spaces.insert(SpaceServiceRoom(spaceRoom: spaceRoom), at: 0)
            case .pushBack(let spaceRoom):
                spaces.append(SpaceServiceRoom(spaceRoom: spaceRoom))
            case .popFront:
                spaces.removeFirst()
            case .popBack:
                spaces.removeLast()
            case .insert(let index, let spaceRoom):
                spaces.insert(SpaceServiceRoom(spaceRoom: spaceRoom), at: Int(index))
            case .set(let index, let spaceRoom):
                spaces[Int(index)] = SpaceServiceRoom(spaceRoom: spaceRoom)
            case .remove(let index):
                spaces.remove(at: Int(index))
            case .truncate(let length):
                spaces.removeSubrange(Int(length)..<spaces.count)
            case .reset(let spaceRooms):
                spaces = spaceRooms.map(SpaceServiceRoom.init)
            }
        }
        
        spacesSubject.send(spaces)
    }
}
