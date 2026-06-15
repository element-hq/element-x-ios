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
    
    private var spaceServiceRoomHandle: TaskHandle?
    private let spaceServiceRoomSubject: CurrentValueSubject<SpaceServiceRoom, Never>
    var spaceServiceRoomPublisher: CurrentValuePublisher<SpaceServiceRoom, Never> {
        spaceServiceRoomSubject.asCurrentValuePublisher()
    }
    
    private var spaceRoomsHandle: TaskHandle?
    private let spaceRoomsSubject = CurrentValueSubject<[SpaceServiceRoom], Never>([])
    var spaceRoomsPublisher: CurrentValuePublisher<[SpaceServiceRoom], Never> {
        spaceRoomsSubject.asCurrentValuePublisher()
    }
    
    private let paginationStateHandle: TaskHandle
    private let paginationStateSubject: CurrentValueSubject<SpaceRoomListPaginationState, Never>
    var paginationStatePublisher: CurrentValuePublisher<SpaceRoomListPaginationState, Never> {
        paginationStateSubject.asCurrentValuePublisher()
    }
    
    // Bridges from the SDK's synchronous callbacks into Swift Concurrency. Yielding is safe from
    // any thread; single long-lived `for await` consumers (set up in `init`) apply the updates on
    // the main actor in FIFO order, guaranteeing one in-flight update at a time.
    private let paginationStateContinuation: AsyncStream<SpaceRoomListPaginationState>.Continuation
    private let roomUpdatesContinuation: AsyncStream<[SpaceListUpdate]>.Continuation
    private let spaceUpdatesContinuation: AsyncStream<SpaceRoom>.Continuation
    
    deinit {
        paginationStateContinuation.finish()
        roomUpdatesContinuation.finish()
        spaceUpdatesContinuation.finish()
    }
    
    init(_ spaceRoomList: SpaceRoomListProtocol) async throws {
        guard let spaceRoom = spaceRoomList.space() else { throw SpaceRoomListProxyError.missingSpace }
        
        self.spaceRoomList = spaceRoomList
        spaceServiceRoomSubject = .init(SpaceServiceRoom(spaceRoom: spaceRoom))
        paginationStateSubject = .init(spaceRoomList.paginationState())
        
        let (paginationStates, paginationStateContinuation) = AsyncStream<SpaceRoomListPaginationState>.makeStream()
        self.paginationStateContinuation = paginationStateContinuation
        
        let (roomUpdates, roomUpdatesContinuation) = AsyncStream<[SpaceListUpdate]>.makeStream()
        self.roomUpdatesContinuation = roomUpdatesContinuation
        
        let (spaceUpdates, spaceUpdatesContinuation) = AsyncStream<SpaceRoom>.makeStream()
        self.spaceUpdatesContinuation = spaceUpdatesContinuation
        
        paginationStateHandle = spaceRoomList.subscribeToPaginationStateUpdates(listener: SDKListener { paginationState in
            paginationStateContinuation.yield(paginationState)
        })
        
        spaceRoomsHandle = await spaceRoomList.subscribeToRoomUpdate(listener: SDKListener { updates in
            roomUpdatesContinuation.yield(updates)
        })
        
        spaceServiceRoomHandle = spaceRoomList.subscribeToSpaceUpdates(listener: SDKListener { spaceRoom in
            guard let spaceRoom else { return }
            spaceUpdatesContinuation.yield(spaceRoom)
        })
        
        Task { [weak self] in
            for await paginationState in paginationStates {
                self?.paginationStateSubject.send(paginationState)
            }
        }
        
        Task { [weak self] in
            for await updates in roomUpdates {
                self?.handleUpdates(updates)
            }
        }
        
        Task { [weak self] in
            for await spaceRoom in spaceUpdates {
                self?.spaceServiceRoomSubject.send(SpaceServiceRoom(spaceRoom: spaceRoom))
            }
        }
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
