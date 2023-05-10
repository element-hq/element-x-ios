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
    private let slidingSyncListProxy: SlidingSyncListProxy
    private let serialDispatchQueue: DispatchQueue
    private let eventStringBuilder: RoomEventStringBuilder
    
    private var cancellables = Set<AnyCancellable>()
    
    private let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
    private let stateSubject = CurrentValueSubject<RoomSummaryProviderState, Never>(.notLoaded)
    private let countSubject = CurrentValueSubject<UInt, Never>(0)
    
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> {
        roomListSubject.asCurrentValuePublisher()
    }

    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> {
        stateSubject.asCurrentValuePublisher()
    }

    var countPublisher: CurrentValuePublisher<UInt, Never> {
        countSubject.asCurrentValuePublisher()
    }
    
    private var rooms: [RoomSummary] = [] {
        didSet {
            roomListSubject.send(rooms)
        }
    }
    
    init(slidingSyncListProxy: SlidingSyncListProxy, eventStringBuilder: RoomEventStringBuilder) {
        self.slidingSyncListProxy = slidingSyncListProxy
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomsummaryprovider", qos: .utility)
        self.eventStringBuilder = eventStringBuilder
        
        rooms = slidingSyncListProxy.currentRoomsList().map { roomListEntry in
            buildSummaryForRoomListEntry(roomListEntry)
        }
        
        roomListSubject.send(rooms) // didSet not called from initialisers
        
        slidingSyncListProxy.statePublisher
            .map(RoomSummaryProviderState.init)
            .subscribe(stateSubject)
            .store(in: &cancellables)
        
        slidingSyncListProxy.countPublisher
            .subscribe(countSubject)
            .store(in: &cancellables)
        
        slidingSyncListProxy.diffPublisher
            .collect(.byTime(serialDispatchQueue, 0.025))
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
    }
    
    func updateVisibleRange(_ range: Range<Int>, timelineLimit: UInt) {
        slidingSyncListProxy.updateVisibleRange(range, timelineLimit: timelineLimit)
    }
    
    // MARK: - Private
        
    fileprivate func updateRoomsWithDiffs(_ diffs: [SlidingSyncListRoomsListDiff]) {
        let span = MXLog.createSpan("process_room_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        MXLog.info("Received \(diffs.count) diffs, current room list \(rooms.compactMap { $0.id ?? "Empty" })")
        
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
                
                return updatedItems
            }
        
        detectDuplicatesInRoomList(rooms)
        
        MXLog.info("Finished applying \(diffs.count) diffs, new room list \(rooms.compactMap { $0.id ?? "Empty" })")
    }
        
    private func buildRoomSummaryForIdentifier(_ identifier: String, invalidated: Bool) -> RoomSummary {
        guard let room = try? slidingSyncListProxy.roomForIdentifier(identifier) else {
            MXLog.error("Failed finding room with id: \(identifier)")
            return .empty
        }
        
        var attributedLastMessage: AttributedString?
        var lastMessageFormattedTimestamp: String?
        
        // Dispatch onto another queue otherwise the rust method latestRoomMessage crashes.
        // This will be fixed when we get async uniffi support.
        DispatchQueue.global(qos: .userInitiated).sync {
            if let latestRoomMessage = room.latestRoomMessage() {
                let lastMessage = EventTimelineItemProxy(item: latestRoomMessage)
                lastMessageFormattedTimestamp = lastMessage.timestamp.formattedMinimal()
                attributedLastMessage = eventStringBuilder.buildAttributedString(for: lastMessage)
            }
        }
        
        let fullRoom = room.fullRoom()
        let avatarURL = fullRoom?.avatarUrl().flatMap(URL.init(string:))
        let canonicalAlias = fullRoom?.canonicalAlias()
        
        let details = RoomSummaryDetails(id: room.roomId(),
                                         name: room.name() ?? room.roomId(),
                                         isDirect: fullRoom?.isDirect() ?? room.isDm() ?? false,
                                         avatarURL: avatarURL,
                                         lastMessage: attributedLastMessage,
                                         lastMessageFormattedTimestamp: lastMessageFormattedTimestamp,
                                         unreadNotificationCount: UInt(room.unreadNotifications().notificationCount()),
                                         canonicalAlias: canonicalAlias)
        
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
            MXLog.info("Push Front \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
        case .pushBack(let value):
            MXLog.info("Push Back \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .append(values: let values):
            let debugIdentifiers = values.map(\.debugIdentifier)
            MXLog.info("Append \(debugIdentifiers)")
            for (index, value) in values.enumerated() {
                let summary = buildSummaryForRoomListEntry(value)
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .set(let index, let value):
            MXLog.info("Update \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .insert(let index, let value):
            MXLog.info("Insert at \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .remove(let index):
            let summary = rooms[Int(index)]
            MXLog.info("Remove \(summary.id ?? "") from \(index)")
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .reset(let values):
            let debugIdentifiers = values.map(\.debugIdentifier)
            MXLog.info("Replace all items with \(debugIdentifiers)")
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                changes.append(.insert(offset: index, element: buildSummaryForRoomListEntry(value), associatedWith: nil))
            }
        case .clear:
            MXLog.info("Clear all items")
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .popFront:
            MXLog.info("Pop Front")
            let summary = rooms[0]
            changes.append(.remove(offset: 0, element: summary, associatedWith: nil))
        case .popBack:
            MXLog.info("Pop Back")
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
            self = .notLoaded
        case .preloaded:
            self = .preloaded
        case .partiallyLoaded:
            self = .partiallyLoaded
        case .fullyLoaded:
            self = .fullyLoaded
        }
    }
}

extension MatrixRustSDK.RoomListEntry {
    var debugIdentifier: String {
        switch self {
        case .empty:
            return "Empty"
        case .invalidated(let roomId):
            return "Invalidated(\(roomId))"
        case .filled(let roomId):
            return "Filled(\(roomId))"
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
