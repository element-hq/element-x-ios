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
    var id: String { spaceRoomProxyPublisher.value.id }
    
    private let spaceRoomList: SpaceRoomListProtocol
    
    private var spaceRoomProxyHandle: TaskHandle?
    private let spaceRoomProxySubject: CurrentValueSubject<SpaceRoomProxyProtocol, Never>
    var spaceRoomProxyPublisher: CurrentValuePublisher<SpaceRoomProxyProtocol, Never> {
        spaceRoomProxySubject.asCurrentValuePublisher()
    }
    
    private var spaceRoomsHandle: TaskHandle?
    private let spaceRoomsSubject = CurrentValueSubject<[SpaceRoomProxyProtocol], Never>([])
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceRoomProxyProtocol], Never> {
        spaceRoomsSubject.asCurrentValuePublisher()
    }
    
    private let paginationStateHandle: TaskHandle
    let paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never>
    
    init(_ spaceRoomList: SpaceRoomListProtocol) throws {
        guard let spaceRoom = spaceRoomList.space() else { throw SpaceRoomListProxyError.missingSpace }
        
        self.spaceRoomList = spaceRoomList
        spaceRoomProxySubject = .init(SpaceRoomProxy(spaceRoom: spaceRoom))
        
        let paginationStateSubject = CurrentValueSubject<SpaceRoomListPaginationState, Never>(spaceRoomList.paginationState())
        paginationStatePublisher = paginationStateSubject.asCurrentValuePublisher()
        
        paginationStateHandle = spaceRoomList.subscribeToPaginationStateUpdates(listener: SDKListener { paginationState in
            paginationStateSubject.send(paginationState)
        })
        
        spaceRoomsHandle = spaceRoomList.subscribeToRoomUpdate(listener: SDKListener { [weak self] updates in
            self?.handleUpdates(updates)
        })
        
        spaceRoomProxyHandle = spaceRoomList.subscribeToSpaceUpdates(listener: SDKListener { [weak self] spaceRoom in
            guard let spaceRoom else { return }
            self?.spaceRoomProxySubject.send(SpaceRoomProxy(spaceRoom: spaceRoom))
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
                rooms.append(contentsOf: spaceRooms.map(SpaceRoomProxy.init))
            case .clear:
                rooms.removeAll()
            case .pushFront(let spaceRoom):
                rooms.insert(SpaceRoomProxy(spaceRoom: spaceRoom), at: 0)
            case .pushBack(let spaceRoom):
                rooms.append(SpaceRoomProxy(spaceRoom: spaceRoom))
            case .popFront:
                rooms.removeFirst()
            case .popBack:
                rooms.removeLast()
            case .insert(let index, let spaceRoom):
                rooms.insert(SpaceRoomProxy(spaceRoom: spaceRoom), at: Int(index))
            case .set(let index, let spaceRoom):
                rooms[Int(index)] = SpaceRoomProxy(spaceRoom: spaceRoom)
            case .remove(let index):
                rooms.remove(at: Int(index))
            case .truncate(let length):
                rooms.removeSubrange(Int(length)..<rooms.count)
            case .reset(let spaceRooms):
                rooms = spaceRooms.map(SpaceRoomProxy.init)
            }
        }
        
        spaceRoomsSubject.send(rooms)
    }
}
