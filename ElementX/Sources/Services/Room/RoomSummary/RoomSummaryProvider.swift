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
    private let serialDispatchQueue: DispatchQueue
    private let eventStringBuilder: RoomEventStringBuilder
    
    private var cancellables = Set<AnyCancellable>()
    
    let roomListPublisher = CurrentValueSubject<[RoomSummary], Never>([])
    let statePublisher = CurrentValueSubject<RoomSummaryProviderState, Never>(.cold)
    let countPublisher = CurrentValueSubject<UInt, Never>(0)
    
    private var rooms: [RoomSummary] = [] {
        didSet {
            roomListPublisher.send(rooms)
        }
    }
    
    init(slidingSyncViewProxy: SlidingSyncViewProxy, eventStringBuilder: RoomEventStringBuilder) {
        self.slidingSyncViewProxy = slidingSyncViewProxy
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomsummaryprovider", qos: .utility)
        self.eventStringBuilder = eventStringBuilder
        
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
            .collect(.byTime(serialDispatchQueue, 0.025))
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
    }
    
    func updateVisibleRange(_ range: Range<Int>, timelineLimit: UInt) {
        slidingSyncViewProxy.updateVisibleRange(range, timelineLimit: timelineLimit)
    }
    
    // MARK: - Private
        
    fileprivate func updateRoomsWithDiffs(_ diffs: [SlidingSyncListRoomsListDiff]) {
        MXLog.info("Received \(diffs.count) diffs")
        
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
        
        detectDuplicatesInRoomList(rooms)
        
        MXLog.info("Finished applying \(diffs.count) diffs")
    }
        
    private func buildRoomSummaryForIdentifier(_ identifier: String, invalidated: Bool) -> RoomSummary {
        guard let room = try? slidingSyncViewProxy.roomForIdentifier(identifier) else {
            MXLog.error("Failed finding room with id: \(identifier)")
            return .empty
        }
        
        var attributedLastMessage: AttributedString?
        var lastMessageFormattedTimestamp: String?
        
        // Dispatch onto another queue otherwise the rust method latestRoomMessage crashes.
        // This will be fixed when we get async uniffi support.
        DispatchQueue.global(qos: .default).sync {
            if let latestRoomMessage = room.latestRoomMessage() {
                let lastMessage = EventTimelineItemProxy(item: latestRoomMessage)
                lastMessageFormattedTimestamp = lastMessage.timestamp.formattedMinimal()
                attributedLastMessage = eventStringBuilder.buildAttributedString(for: lastMessage)
            }
        }
        
        let avatarURL = room.fullRoom()?.avatarUrl().flatMap(URL.init(string:))
        
        let details = RoomSummaryDetails(id: room.roomId(),
                                         name: room.name() ?? room.roomId(),
                                         isDirect: room.isDm() ?? false,
                                         avatarURL: avatarURL,
                                         lastMessage: attributedLastMessage,
                                         lastMessageFormattedTimestamp: lastMessageFormattedTimestamp,
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
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func buildDiff(from diff: SlidingSyncListRoomsListDiff, on rooms: [RoomSummary]) -> CollectionDifference<RoomSummary>? {
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .pushFront(let value):
            MXLog.verbose("Push Front")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
        case .pushBack(let value):
            MXLog.verbose("Push Back")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .append(values: let values):
            MXLog.verbose("Append \(values.count) rooms, current total count: \(rooms.count)")
            for (index, value) in values.enumerated() {
                let summary = buildSummaryForRoomListEntry(value)
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .set(let index, let value):
            MXLog.verbose("Update \(index), current total count: \(rooms.count)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .insert(let index, let value):
            MXLog.verbose("Insert at \(index), current total count: \(rooms.count)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .remove(let index):
            MXLog.verbose("Remove from: \(index), current total count: \(rooms.count)")
            let summary = rooms[Int(index)]
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .reset(let values):
            MXLog.verbose("Replace all items with new count: \(values.count), current total count: \(rooms.count)")
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                changes.append(.insert(offset: index, element: buildSummaryForRoomListEntry(value), associatedWith: nil))
            }
        case .clear:
            MXLog.verbose("Clear all items, current total count: \(rooms.count)")
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .popFront:
            MXLog.verbose("Pop Front, current total count: \(rooms.count)")
            let summary = rooms[0]
            changes.append(.remove(offset: 0, element: summary, associatedWith: nil))
        case .popBack:
            MXLog.verbose("Pop Back, current total count: \(rooms.count)")
            guard let value = rooms.last else {
                fatalError()
            }
            
            changes.append(.remove(offset: rooms.count - 1, element: value, associatedWith: nil))
        }
        
        return CollectionDifference(changes)
    }
    
    private func detectDuplicatesInRoomList(_ rooms: [RoomSummary]) {
        let filteredRooms = rooms.filter {
            switch $0 {
            case .empty:
                return false
            default:
                return true
            }
        }
        
        let groupedRooms = Dictionary(grouping: filteredRooms, by: \.id)
        
        let duplicates = groupedRooms.filter { $1.count > 1 }
        
        if duplicates.count > 0 {
            MXLog.error("Found duplicated room room list items: \(duplicates)")
        }
    }
}

extension RoomSummaryProviderState {
    init(slidingSyncState: SlidingSyncState) {
        switch slidingSyncState {
        case .notLoaded:
            self = .cold
        case .preloaded:
            self = .preload
        case .partiallyLoaded:
            self = .catchingUp
        case .fullyLoaded:
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
