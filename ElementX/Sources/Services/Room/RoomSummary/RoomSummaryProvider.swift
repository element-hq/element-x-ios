//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import MatrixRustSDK

private class WeakRoomSummaryProviderWrapper: SlidingSyncViewRoomListObserver, SlidingSyncViewStateObserver, SlidingSyncViewRoomsCountObserver {
    /// Publishes room list diffs as they come in through sliding sync
    let roomListDiffPublisher = PassthroughSubject<SlidingSyncViewRoomsListDiff, Never>()
    
    /// Publishes the current state of sliding sync, such as whether its catching up or live.
    let stateUpdatePublisher = CurrentValueSubject<SlidingSyncState, Never>(.cold)
    
    /// Publishes the number of available rooms
    let countUpdatePublisher = CurrentValueSubject<UInt, Never>(0)
        
    // MARK: - SlidingSyncViewRoomListObserver
    
    func didReceiveUpdate(diff: SlidingSyncViewRoomsListDiff) {
        roomListDiffPublisher.send(diff)
    }
    
    // MARK: - SlidingSyncViewStateObserver
    
    func didReceiveUpdate(newState: SlidingSyncState) {
        stateUpdatePublisher.send(newState)
    }
    
    // MARK: - SlidingSyncViewRoomsCountObserver
    
    func didReceiveUpdate(count: UInt32) {
        countUpdatePublisher.send(UInt(count))
    }
}

class RoomSummaryProvider: RoomSummaryProviderProtocol {
    private let slidingSyncController: SlidingSyncProtocol
    private let slidingSyncView: SlidingSyncViewProtocol
    private let roomMessageFactory: RoomMessageFactoryProtocol
    
    private var listUpdateObserverToken: StoppableSpawn?
    private var stateUpdateObserverToken: StoppableSpawn?
    private var countUpdateObserverToken: StoppableSpawn?
    
    private var cancellables = Set<AnyCancellable>()
    
    let roomListPublisher = CurrentValueSubject<[RoomSummary], Never>([])
    let statePublisher = CurrentValueSubject<RoomSummaryProviderState, Never>(.cold)
    let countPublisher = CurrentValueSubject<UInt, Never>(0)
    
    private var rooms: [RoomSummary] = [] {
        didSet {
            roomListPublisher.send(rooms)
        }
    }
    
    deinit {
        listUpdateObserverToken?.cancel()
        stateUpdateObserverToken?.cancel()
        countUpdateObserverToken?.cancel()
    }
    
    init(slidingSyncController: SlidingSyncProtocol, slidingSyncView: SlidingSyncViewProtocol, roomMessageFactory: RoomMessageFactoryProtocol) {
        self.slidingSyncView = slidingSyncView
        self.slidingSyncController = slidingSyncController
        self.roomMessageFactory = roomMessageFactory
        
        let weakProvider = WeakRoomSummaryProviderWrapper()
        
        weakProvider.stateUpdatePublisher
            .map(RoomSummaryProviderState.init)
            .subscribe(statePublisher)
            .store(in: &cancellables)
        
        weakProvider.countUpdatePublisher
            .subscribe(countPublisher)
            .store(in: &cancellables)
        
        weakProvider.roomListDiffPublisher
            .collect(.byTime(DispatchQueue.global(), 0.5))
            .sink { self.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
        
        listUpdateObserverToken = slidingSyncView.observeRoomList(observer: weakProvider)
        stateUpdateObserverToken = slidingSyncView.observeState(observer: weakProvider)
        countUpdateObserverToken = slidingSyncView.observeRoomsCount(observer: weakProvider)
    }
    
    func updateRoomsWithIdentifiers(_ identifiers: [String]) {
        guard statePublisher.value == .live else {
            return
        }

        var changes = [CollectionDifference<RoomSummary>.Change]()
        for identifier in identifiers {
            guard let index = rooms.firstIndex(where: { $0.id == identifier }) else {
                continue
            }

            let oldRoom = rooms[index]
            let newRoom = buildRoomSummaryForIdentifier(identifier)

            changes.append(.remove(offset: index, element: oldRoom, associatedWith: nil))
            changes.append(.insert(offset: index, element: newRoom, associatedWith: nil))
        }

        guard let diff = CollectionDifference(changes) else {
            MXLog.error("Failed creating diff from changes: \(changes)")
            return
        }

        guard let newSummaries = rooms.applying(diff) else {
            MXLog.error("Failed applying diff: \(diff)")
            return
        }

        rooms = newSummaries
    }
    
    // MARK: - Private
    
    fileprivate func updateRoomsWithDiffs(_ diffs: [SlidingSyncViewRoomsListDiff]) {
        rooms = diffs
            .compactMap(buildDiff)
            .reduce(rooms) { $0.applying($1) ?? $0 }
    }
    
    private func buildEmptyRoomSummary(forIdentifier identifier: String = UUID().uuidString) -> RoomSummary {
        .empty(id: identifier)
    }
    
    private func buildRoomSummaryForIdentifier(_ identifier: String) -> RoomSummary {
        guard let room = try? slidingSyncController.getRoom(roomId: identifier) else {
            MXLog.error("Failed finding room with id: \(identifier)")
            return buildEmptyRoomSummary(forIdentifier: identifier)
        }
        
        var attributedLastMessage: AttributedString?
        var lastMessageTimestamp: Date?
        if let latestRoomMessage = room.latestRoomMessage() {
            let lastMessage = roomMessageFactory.buildRoomMessageFrom(EventTimelineItemProxy(item: latestRoomMessage))
            if let lastMessageSender = try? AttributedString(markdown: "**\(lastMessage.sender)**") {
                // Don't include the message body in the markdown otherwise it makes tappable links.
                attributedLastMessage = lastMessageSender + ": " + AttributedString(lastMessage.body)
            }
            lastMessageTimestamp = lastMessage.originServerTs
        }
        
        return .filled(details: RoomSummaryDetails(id: room.roomId(),
                                                   name: room.name() ?? room.roomId(),
                                                   isDirect: room.isDm() ?? false,
                                                   avatarURLString: room.fullRoom()?.avatarUrl(),
                                                   lastMessage: attributedLastMessage,
                                                   lastMessageTimestamp: lastMessageTimestamp,
                                                   unreadNotificationCount: UInt(room.unreadNotifications().notificationCount())))
    }
    
    private func buildSummaryForRoomListEntry(_ entry: RoomListEntry) -> RoomSummary {
        switch entry {
        case .empty:
            return buildEmptyRoomSummary()
        case .filled(let roomId):
            return buildRoomSummaryForIdentifier(roomId)
        case .invalidated(let roomId):
            return buildRoomSummaryForIdentifier(roomId)
        }
    }
    
    private func buildDiff(from diff: SlidingSyncViewRoomsListDiff) -> CollectionDifference<RoomSummary>? {
        // Invalidations are a no-op for the moment
        if diff.isInvalidation {
            return nil
        }
        
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .push(value: let value):
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(rooms.count), element: summary, associatedWith: nil))
        case .updateAt(let index, let value):
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .insertAt(let index, let value):
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .move(let oldIndex, let newIndex):
            let summary = rooms[Int(oldIndex)]
            changes.append(.remove(offset: Int(oldIndex), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(newIndex), element: summary, associatedWith: nil))
        case .removeAt(let index):
            let summary = rooms[Int(index)]
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .replace(let values):
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            values
                .reversed()
                .map { buildSummaryForRoomListEntry($0) }
                .forEach { summary in
                    changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
                }
        }
        
        return CollectionDifference(changes)
    }
}

extension SlidingSyncViewRoomsListDiff {
    var isInvalidation: Bool {
        switch self {
        case .push(let value), .updateAt(_, let value), .insertAt(_, let value):
            switch value {
            case .invalidated:
                return true
            default:
                return false
            }
        default:
            return false
        }
    }
}

extension RoomSummaryProviderState {
    init(slidingSyncState: SlidingSyncState) {
        switch slidingSyncState {
        case .cold:
            self = .cold
        case .preload:
            self = .preload
        case .catchingUp:
            self = .catchingUp
        case .live:
            self = .live
        }
    }
}
