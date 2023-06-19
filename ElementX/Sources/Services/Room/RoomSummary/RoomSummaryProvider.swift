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
    private let roomListService: RoomListProtocol
    private let eventStringBuilder: RoomEventStringBuilder
    private let name: String
    
    private let serialDispatchQueue: DispatchQueue
    
    private var cancellables = Set<AnyCancellable>()
    private var listUpdatesTaskHandle: TaskHandle?
    private var stateUpdatesTaskHandle: TaskHandle?
    
    private let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
    private let stateSubject = CurrentValueSubject<RoomSummaryProviderState, Never>(.notLoaded)
    private let countSubject = CurrentValueSubject<UInt, Never>(0)
    
    private let diffPublisher = PassthroughSubject<RoomListEntriesUpdate, Never>()
    
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> {
        roomListSubject.asCurrentValuePublisher()
    }

    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> {
        stateSubject.asCurrentValuePublisher()
    }
    
    private var rooms: [RoomSummary] = [] {
        didSet {
            roomListSubject.send(rooms)
        }
    }
    
    init(roomListService: RoomListProtocol,
         eventStringBuilder: RoomEventStringBuilder,
         name: String) {
        self.roomListService = roomListService
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomsummaryprovider", qos: .utility)
        self.eventStringBuilder = eventStringBuilder
        self.name = name
        
        diffPublisher
            .collect(.byTime(serialDispatchQueue, 0.025))
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
    }
    
    func subscribeIfNecessary(entriesFunction: EntriesFunction,
                              entriesLoadingStateFunction: LoadingStateFunction?) async {
        guard listUpdatesTaskHandle == nil, stateUpdatesTaskHandle == nil else {
            return
        }
        
        do {
            let listUpdatesSubscriptionResult = try await entriesFunction(RoomListEntriesListenerProxy { [weak self] update in
                guard let self else { return }
                MXLog.verbose("\(name): Received list update")
                diffPublisher.send(update)
            })
            
            listUpdatesTaskHandle = listUpdatesSubscriptionResult.entriesStream
            
            rooms = listUpdatesSubscriptionResult.entries.map { roomListEntry in
                buildSummaryForRoomListEntry(roomListEntry)
            }
            
            if let entriesLoadingStateFunction {
                let stateUpdatesSubscriptionResult = try await entriesLoadingStateFunction(RoomListStateObserver { [weak self] state in
                    guard let self else { return }
                    MXLog.info("\(name): Received state update: \(state)")
                    stateSubject.send(RoomSummaryProviderState(slidingSyncState: state))
                })
                
                stateSubject.send(RoomSummaryProviderState(slidingSyncState: stateUpdatesSubscriptionResult.entriesLoadingState))
                
                stateUpdatesTaskHandle = stateUpdatesSubscriptionResult.entriesLoadingStateStream
            }
            
        } catch {
            MXLog.error("Failed setting up room list entry listener with error: \(error)")
        }
    }
    
    func updateVisibleRange(_ range: Range<Int>) {
        Task {
            do {
                MXLog.info("\(name): Setting visible range to \(range)")
                try await roomListService.applyInput(input: .viewport(ranges: [.init(start: UInt32(range.lowerBound), endInclusive: UInt32(range.upperBound))]))
            } catch {
                MXLog.error("Failed updating visible range with error: \(error)")
            }
        }
    }
    
    // MARK: - Private
        
    fileprivate func updateRoomsWithDiffs(_ diffs: [RoomListEntriesUpdate]) {
        let span = MXLog.createSpan("\(name).process_room_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        MXLog.verbose("\(name): Received \(diffs.count) diffs, current room list \(rooms.compactMap { $0.id ?? "Empty" })")
        
        rooms = diffs
            .reduce(rooms) { currentItems, diff in
                guard let collectionDiff = buildDiff(from: diff, on: currentItems) else {
                    MXLog.error("\(name): Failed building CollectionDifference from \(diff)")
                    return currentItems
                }
                
                guard let updatedItems = currentItems.applying(collectionDiff) else {
                    MXLog.error("\(name): Failed applying diff: \(collectionDiff)")
                    return currentItems
                }
                
                return updatedItems
            }
        
        detectDuplicatesInRoomList(rooms)
        
        MXLog.verbose("\(name): Finished applying \(diffs.count) diffs, new room list \(rooms.compactMap { $0.id ?? "Empty" })")
    }
        
    private func buildRoomSummaryForIdentifier(_ identifier: String) -> RoomSummary {
        guard let roomListItem = try? roomListService.room(roomId: identifier) else {
            MXLog.error("\(name): Failed finding room with id: \(identifier)")
            return .empty
        }
        
        var attributedLastMessage: AttributedString?
        var lastMessageFormattedTimestamp: String?
        
        if let latestRoomMessage = roomListItem.latestEvent() {
            let lastMessage = EventTimelineItemProxy(item: latestRoomMessage)
            lastMessageFormattedTimestamp = lastMessage.timestamp.formattedMinimal()
            attributedLastMessage = eventStringBuilder.buildAttributedString(for: lastMessage)
        }
        
        let room = roomListItem.fullRoom()

        let details = RoomSummaryDetails(id: roomListItem.id(),
                                         name: roomListItem.name() ?? room.id(),
                                         isDirect: room.isDirect(),
                                         avatarURL: room.avatarUrl().flatMap(URL.init(string:)),
                                         lastMessage: attributedLastMessage,
                                         lastMessageFormattedTimestamp: lastMessageFormattedTimestamp,
                                         unreadNotificationCount: UInt(roomListItem.unreadNotifications().notificationCount()),
                                         canonicalAlias: room.canonicalAlias())

        return .filled(details: details)
    }
    
    private func buildSummaryForRoomListEntry(_ entry: RoomListEntry) -> RoomSummary {
        switch entry {
        case .empty:
            return .empty
        case .filled(let roomId):
            return buildRoomSummaryForIdentifier(roomId)
        case .invalidated(let roomId):
            return buildRoomSummaryForIdentifier(roomId)
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func buildDiff(from diff: RoomListEntriesUpdate, on rooms: [RoomSummary]) -> CollectionDifference<RoomSummary>? {
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .pushFront(let value):
            MXLog.verbose("\(name): Push Front \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
        case .pushBack(let value):
            MXLog.verbose("\(name): Push Back \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .append(values: let values):
            let debugIdentifiers = values.map(\.debugIdentifier)
            MXLog.verbose("\(name): Append \(debugIdentifiers)")
            for (index, value) in values.enumerated() {
                let summary = buildSummaryForRoomListEntry(value)
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .set(let index, let value):
            MXLog.verbose("\(name): Update \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .insert(let index, let value):
            MXLog.verbose("\(name): Insert at \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .remove(let index):
            let summary = rooms[Int(index)]
            MXLog.verbose("\(name): Remove \(summary.id ?? "") from \(index)")
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .reset(let values):
            let debugIdentifiers = values.map(\.debugIdentifier)
            MXLog.verbose("\(name): Replace all items with \(debugIdentifiers)")
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                changes.append(.insert(offset: index, element: buildSummaryForRoomListEntry(value), associatedWith: nil))
            }
        case .clear:
            MXLog.verbose("\(name): Clear all items")
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .popFront:
            MXLog.verbose("\(name): Pop Front")
            let summary = rooms[0]
            changes.append(.remove(offset: 0, element: summary, associatedWith: nil))
        case .popBack:
            MXLog.verbose("\(name): Pop Back")
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
            MXLog.error("\(name): Found duplicated room room list items: \(duplicates)")
        }
    }
}

extension RoomSummaryProviderState {
    init(slidingSyncState: SlidingSyncListLoadingState) {
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

private class RoomListEntriesListenerProxy: RoomListEntriesListener {
    private let onUpdateClosure: (RoomListEntriesUpdate) -> Void
   
    init(_ onUpdateClosure: @escaping (RoomListEntriesUpdate) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(roomEntriesUpdate: RoomListEntriesUpdate) {
        onUpdateClosure(roomEntriesUpdate)
    }
}

private class RoomListStateObserver: SlidingSyncListStateObserver {
    private let onUpdateClosure: (SlidingSyncListLoadingState) -> Void
   
    init(_ onUpdateClosure: @escaping (SlidingSyncListLoadingState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func didReceiveUpdate(newState: SlidingSyncListLoadingState) {
        onUpdateClosure(newState)
    }
}
