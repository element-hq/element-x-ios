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

class RoomSummaryProvider: RoomSummaryProviderProtocol {
    private let slidingSyncViewProxy: SlidingSyncViewProxy
    private let roomMessageFactory: RoomMessageFactoryProtocol
    private let serialDispatchQueue: DispatchQueue
    
    private var cancellables = Set<AnyCancellable>()
    
    let roomListPublisher = CurrentValueSubject<[RoomSummary], Never>([])
    let statePublisher = CurrentValueSubject<RoomSummaryProviderState, Never>(.cold)
    let countPublisher = CurrentValueSubject<UInt, Never>(0)
    
    private var rooms: [RoomSummary] = [] {
        didSet {
            roomListPublisher.send(rooms)
        }
    }
    
    init(slidingSyncViewProxy: SlidingSyncViewProxy, roomMessageFactory: RoomMessageFactoryProtocol) {
        self.slidingSyncViewProxy = slidingSyncViewProxy
        self.roomMessageFactory = roomMessageFactory
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomsummaryprovider")
        
        rooms = slidingSyncViewProxy.currentRoomsList().map { roomListEntry in
            buildSummaryForRoomListEntry(roomListEntry)
        }
        
        roomListPublisher.send(rooms) // didSet not called from initialisers
        
        slidingSyncViewProxy.statePublisher
            .map(RoomSummaryProviderState.init)
            .subscribe(statePublisher)
            .store(in: &cancellables)
        
        slidingSyncViewProxy.countPublisher
            .subscribe(countPublisher)
            .store(in: &cancellables)
        
        slidingSyncViewProxy.diffPublisher
            .collect(.byTime(serialDispatchQueue, 0.1))
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
    }
    
    func updateRoomsWithIdentifiers(_ identifiers: [String]) {
        serialDispatchQueue.async { [weak self] in
            guard let self else { return }
            self.updateRoomsForIdentifiers(identifiers)
        }
    }
    
    func updateVisibleRange(_ range: ClosedRange<Int>) {
        slidingSyncViewProxy.updateVisibleRange(range)
    }
    
    // MARK: - Private
    
    /// Invoked from `updateRoomsWithIdentifiers` on the same dispatch queue as `updateRoomsWithDiffs`
    private func updateRoomsForIdentifiers(_ identifiers: [String]) {
        guard !identifiers.isEmpty else {
            return
        }
        
        MXLog.verbose("Updating \(identifiers.count) rooms")
        
        guard statePublisher.value == .live else {
            MXLog.verbose("Sliding sync not live yet, ignoring.")
            return
        }
        
        var changes = [CollectionDifference<RoomSummary>.Change]()
        for identifier in identifiers {
            guard let index = rooms.firstIndex(where: { $0.id == identifier }),
                  let roomListEntry = slidingSyncViewProxy.currentRoomsList().first(where: { $0.id == identifier }) else {
                continue
            }
            
            let oldRoom = rooms[index]
            let newRoom = buildRoomSummaryForIdentifier(identifier, invalidated: roomListEntry.isInvalidated)

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
        
        MXLog.verbose("Finished updating \(identifiers.count) rooms")
    }
    
    fileprivate func updateRoomsWithDiffs(_ diffs: [SlidingSyncViewRoomsListDiff]) {
        MXLog.verbose("Received \(diffs.count) diffs")
        
        rooms = diffs
            .reduce(rooms) { currentItems, diff in
                guard let collectionDiff = buildDiff(from: diff, on: currentItems) else {
                    MXLog.error("Failed building CollectionDifference from \(diff)")
                    return currentItems
                }
                
                guard let updatedItems = currentItems.applying(collectionDiff) else {
                    MXLog.error("Failed applying diff: \(collectionDiff)")
                    return currentItems
                }
                
                MXLog.verbose("Applied diff, new count: \(updatedItems.count)")
                
                return updatedItems
            }
        
        MXLog.verbose("Finished applying \(diffs.count) diffs")
    }
        
    private func buildRoomSummaryForIdentifier(_ identifier: String, invalidated: Bool) -> RoomSummary {
        guard let room = try? slidingSyncViewProxy.roomForIdentifier(identifier) else {
            MXLog.error("Failed finding room with id: \(identifier)")
            return .empty
        }
        
        var attributedLastMessage: AttributedString?
        var lastMessageTimestamp: Date?
        if let latestRoomMessage = room.latestRoomMessage() {
            let lastMessage = roomMessageFactory.buildRoomMessageFrom(EventTimelineItemProxy(item: latestRoomMessage))
            
            #warning("Intentionally remove the sender mxid from the room list for now")
            // if let lastMessageSender = try? AttributedString(markdown: "**\(lastMessage.sender)**") {
            //     // Don't include the message body in the markdown otherwise it makes tappable links.
            //     attributedLastMessage = lastMessageSender + ": " + AttributedString(lastMessage.body)
            // }
            attributedLastMessage = AttributedString(lastMessage.body)
            lastMessageTimestamp = lastMessage.timestamp
        }
        
        let details = RoomSummaryDetails(id: room.roomId(),
                                         name: room.name() ?? room.roomId(),
                                         isDirect: room.isDm() ?? false,
                                         avatarURLString: room.fullRoom()?.avatarUrl(),
                                         lastMessage: attributedLastMessage,
                                         lastMessageTimestamp: lastMessageTimestamp,
                                         unreadNotificationCount: UInt(room.unreadNotifications().notificationCount()))
        
        return invalidated ? .invalidated(details: details) : .filled(details: details)
    }
    
    private func buildSummaryForRoomListEntry(_ entry: RoomListEntry) -> RoomSummary {
        switch entry {
        case .empty:
            return .empty
        case .filled(let roomId):
            return buildRoomSummaryForIdentifier(roomId, invalidated: false)
        case .invalidated(let roomId):
            return buildRoomSummaryForIdentifier(roomId, invalidated: true)
        }
    }
    
    private func buildDiff(from diff: SlidingSyncViewRoomsListDiff, on rooms: [RoomSummary]) -> CollectionDifference<RoomSummary>? {
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .push(value: let value):
            MXLog.verbose("Push")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(rooms.count), element: summary, associatedWith: nil))
        case .updateAt(let index, let value):
            MXLog.verbose("Update \(index), current total count: \(rooms.count)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .insertAt(let index, let value):
            MXLog.verbose("Insert at \(index), current total count: \(rooms.count)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .move(let oldIndex, let newIndex):
            MXLog.verbose("Move from: \(oldIndex) to: \(newIndex), current total count: \(rooms.count)")
            let summary = rooms[Int(oldIndex)]
            changes.append(.remove(offset: Int(oldIndex), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(newIndex), element: summary, associatedWith: nil))
        case .removeAt(let index):
            MXLog.verbose("Remove from: \(index), current total count: \(rooms.count)")
            let summary = rooms[Int(index)]
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .replace(let values):
            MXLog.verbose("Replace all items with new count: \(values.count), current total count: \(rooms.count)")
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                changes.append(.insert(offset: index, element: buildSummaryForRoomListEntry(value), associatedWith: nil))
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

extension MatrixRustSDK.RoomListEntry {
    var id: String? {
        switch self {
        case .empty:
            return nil
        case .invalidated(let roomId), .filled(let roomId):
            return roomId
        }
    }
    
    var isInvalidated: Bool {
        switch self {
        case .invalidated:
            return true
        default:
            return false
        }
    }
}
