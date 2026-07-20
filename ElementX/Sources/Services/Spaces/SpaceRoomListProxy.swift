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
    var id: String {
        spaceServiceRoomPublisher.value.id
    }
    
    private let spaceRoomList: SpaceRoomListProtocol
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var spaceServiceRoomHandle: TaskHandle?
    private let spaceServiceRoomSubject: CurrentValueSubject<SpaceServiceRoom, Never>
    var spaceServiceRoomPublisher: CurrentValuePublisher<SpaceServiceRoom, Never> {
        spaceServiceRoomSubject.asCurrentValuePublisher()
    }
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var spaceRoomsHandle: TaskHandle?
    private let spaceRoomsSubject = CurrentValueSubject<[SpaceServiceRoom], Never>([])
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never> {
        spaceRoomsSubject.asCurrentValuePublisher()
    }
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var paginationStateHandle: TaskHandle?
    private let paginationStateSubject: CurrentValueSubject<SpaceRoomListPaginationState, Never>
    var paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never> {
        paginationStateSubject.asCurrentValuePublisher()
    }
    
    init(_ spaceRoomList: SpaceRoomListProtocol) async throws {
        guard let spaceRoom = spaceRoomList.space() else { throw SpaceRoomListProxyError.missingSpace }
        
        self.spaceRoomList = spaceRoomList
        spaceServiceRoomSubject = .init(SpaceServiceRoom(spaceRoom: spaceRoom))
        paginationStateSubject = .init(spaceRoomList.paginationState())
        
        // The SDK calls listeners from arbitrary threads; onMainActor applies the updates on the
        // main actor in FIFO order. The subscriptions (and so the listeners) live as long as their
        // handles, which are released when this proxy is deallocated.
        paginationStateHandle = spaceRoomList.subscribeToPaginationStateUpdates(listener: SDKListener.onMainActor { [weak self] paginationState in
            self?.paginationStateSubject.send(paginationState)
        })
        
        spaceRoomsHandle = await spaceRoomList.subscribeToRoomUpdate(listener: SDKListener.onMainActor { [weak self] updates in
            self?.handleUpdates(updates)
        })
        
        spaceServiceRoomHandle = spaceRoomList.subscribeToSpaceUpdates(listener: SDKListener.onMainActor { [weak self] spaceRoom in
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
    
    func reset() async {
        await spaceRoomList.reset()
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
