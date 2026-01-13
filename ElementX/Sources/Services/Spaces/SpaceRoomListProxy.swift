//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK

class SpaceRoomListProxy: SpaceRoomListProxyProtocol {
    var id: String { spaceServiceRoomPublisher.value.id }
    
    private let spaceRoomList: SpaceRoomListProtocol
    
    private var spaceServiceRoomHandle: TaskHandle?
    private let spaceServiceRoomSubject: CurrentValueSubject<SpaceServiceRoomProtocol, Never>
    var spaceServiceRoomPublisher: CurrentValuePublisher<SpaceServiceRoomProtocol, Never> {
        spaceServiceRoomSubject.asCurrentValuePublisher()
    }
    
    private var spaceRoomsHandle: TaskHandle?
    private let spaceRoomsSubject = CurrentValueSubject<[SpaceServiceRoomProtocol], Never>([])
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceServiceRoomProtocol], Never> {
        spaceRoomsSubject.asCurrentValuePublisher()
    }
    
    private let paginationStateHandle: TaskHandle
    let paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never>
    
    init(_ spaceRoomList: SpaceRoomListProtocol) throws {
        guard let spaceRoom = spaceRoomList.space() else { throw SpaceRoomListProxyError.missingSpace }
        
        self.spaceRoomList = spaceRoomList
        spaceServiceRoomSubject = .init(SpaceServiceRoom(spaceRoom: spaceRoom))
        
        let paginationStateSubject = CurrentValueSubject<SpaceRoomListPaginationState, Never>(spaceRoomList.paginationState())
        paginationStatePublisher = paginationStateSubject.asCurrentValuePublisher()
        
        paginationStateHandle = spaceRoomList.subscribeToPaginationStateUpdates(listener: SDKListener { paginationState in
            paginationStateSubject.send(paginationState)
        })
        
        spaceRoomsHandle = spaceRoomList.subscribeToRoomUpdate(listener: SDKListener { [weak self] updates in
            self?.handleUpdates(updates)
        })
        
        spaceServiceRoomHandle = spaceRoomList.subscribeToSpaceUpdates(listener: SDKListener { [weak self] spaceRoom in
            guard let spaceRoom else { return }
            self?.spaceServiceRoomSubject.send(SpaceServiceRoom(spaceRoom: spaceRoom))
        })
    }
    
    func paginate() async {
        do {
            try await spaceRoomList.paginate()
        } catch {
            MXLog.error("Pagination failure: \(error)")
        }
    }
    
    // MARK: - Private
    
    private func handleUpdates(_ updates: [SpaceListUpdate]) {
        var rooms = spaceRoomsSubject.value
        
        for update in updates {
            switch update {
            case .append(let spaceRooms):
                rooms.append(contentsOf: spaceRooms.map(SpaceServiceRoom.init))
            case .clear:
                rooms.removeAll()
            case .pushFront(let spaceRoom):
                rooms.insert(SpaceServiceRoom(spaceRoom: spaceRoom), at: 0)
            case .pushBack(let spaceRoom):
                rooms.append(SpaceServiceRoom(spaceRoom: spaceRoom))
            case .popFront:
                rooms.removeFirst()
            case .popBack:
                rooms.removeLast()
            case .insert(let index, let spaceRoom):
                rooms.insert(SpaceServiceRoom(spaceRoom: spaceRoom), at: Int(index))
            case .set(let index, let spaceRoom):
                rooms[Int(index)] = SpaceServiceRoom(spaceRoom: spaceRoom)
            case .remove(let index):
                rooms.remove(at: Int(index))
            case .truncate(let length):
                rooms.removeSubrange(Int(length)..<rooms.count)
            case .reset(let spaceRooms):
                rooms = spaceRooms.map(SpaceServiceRoom.init)
            }
        }
        
        spaceRoomsSubject.send(rooms)
    }
}
