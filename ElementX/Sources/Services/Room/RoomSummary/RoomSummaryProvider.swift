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
    private let roomListService: RoomListServiceProtocol
    private let eventStringBuilder: RoomEventStringBuilder
    private let name: String
    private var appSettings: AppSettings
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    private let serialDispatchQueue: DispatchQueue
    
    private var roomList: RoomListProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var listUpdatesSubscriptionResult: RoomListEntriesWithDynamicFilterResult?
    private var listUpdatesTaskHandle: TaskHandle?
    private var stateUpdatesTaskHandle: TaskHandle?
    
    private let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
    private let stateSubject = CurrentValueSubject<RoomSummaryProviderState, Never>(.notLoaded)
    private let countSubject = CurrentValueSubject<UInt, Never>(0)
    
    private let diffsPublisher = PassthroughSubject<[RoomListEntriesUpdate], Never>()
    
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
    
    init(roomListService: RoomListServiceProtocol,
         eventStringBuilder: RoomEventStringBuilder,
         name: String,
         appSettings: AppSettings,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.roomListService = roomListService
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomsummaryprovider", qos: .utility)
        self.eventStringBuilder = eventStringBuilder
        self.name = name
        self.appSettings = appSettings
        self.backgroundTaskService = backgroundTaskService
        
        diffsPublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
    }
    
    func setRoomList(_ roomList: RoomList) {
        guard listUpdatesTaskHandle == nil, stateUpdatesTaskHandle == nil else {
            return
        }
        
        self.roomList = roomList

        do {
            listUpdatesSubscriptionResult = roomList.entriesWithDynamicFilter(listener: RoomListEntriesListenerProxy { [weak self] updates in
                guard let self else { return }
                MXLog.info("\(name): Received list update")
                diffsPublisher.send(updates)
            })
            
            listUpdatesTaskHandle = listUpdatesSubscriptionResult?.entriesStream
            
            // Forces the listener above to be called with the current state
            updateFilterPattern(nil)

            let stateUpdatesSubscriptionResult = try roomList.loadingState(listener: RoomListStateObserver { [weak self] state in
                guard let self else { return }
                MXLog.info("\(name): Received state update: \(state)")
                stateSubject.send(RoomSummaryProviderState(roomListState: state))
            })
            
            stateUpdatesTaskHandle = stateUpdatesSubscriptionResult.stateStream
            
            stateSubject.send(RoomSummaryProviderState(roomListState: stateUpdatesSubscriptionResult.state))
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
    
    func updateFilterPattern(_ pattern: String?) {
        guard let pattern, !pattern.isEmpty else {
            _ = listUpdatesSubscriptionResult?.dynamicFilter.set(kind: .all)
            return
        }
        
        guard appSettings.fuzzySearchEnabled else { return }
        
        _ = listUpdatesSubscriptionResult?.dynamicFilter.set(kind: .fuzzyMatchRoomName(pattern: pattern.lowercased()))
    }
    
    // MARK: - Private
        
    fileprivate func updateRoomsWithDiffs(_ diffs: [RoomListEntriesUpdate]) {
        let span = MXLog.createSpan("\(name).process_room_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        MXLog.info("\(name): Received \(diffs.count) diffs, current room list \(rooms.compactMap { $0.id ?? "Empty" })")
        
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
        
        MXLog.info("\(name): Finished applying \(diffs.count) diffs, new room list \(rooms.compactMap { $0.id ?? "Empty" })")
    }

    private func fetchRoomInfo(roomListItem: RoomListItemProtocol) -> RoomInfo? {
        class FetchResult {
            var roomInfo: RoomInfo?
        }

        let semaphore = DispatchSemaphore(value: 0)
        let result = FetchResult()

        Task {
            do {
                result.roomInfo = try await roomListItem.roomInfo()
            } catch {
                MXLog.error("Failed fetching room info with error: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
        return result.roomInfo
    }

    private func buildRoomSummaryForIdentifier(_ identifier: String, invalidated: Bool) -> RoomSummary {
        guard let roomListItem = try? roomListService.room(roomId: identifier) else {
            MXLog.error("\(name): Failed finding room with id: \(identifier)")
            return .empty
        }
        
        guard let roomInfo = fetchRoomInfo(roomListItem: roomListItem) else {
            return .empty
        }
        
        var attributedLastMessage: AttributedString?
        var lastMessageFormattedTimestamp: String?
        
        if let latestRoomMessage = roomInfo.latestEvent {
            let lastMessage = EventTimelineItemProxy(item: latestRoomMessage, id: 0)
            lastMessageFormattedTimestamp = lastMessage.timestamp.formattedMinimal()
            attributedLastMessage = eventStringBuilder.buildAttributedString(for: lastMessage)
        }
        
        var inviterProxy: RoomMemberProxyProtocol?
        if let inviter = roomInfo.inviter {
            inviterProxy = RoomMemberProxy(member: inviter, backgroundTaskService: backgroundTaskService)
        }
        
        let details = RoomSummaryDetails(id: roomInfo.id,
                                         name: roomInfo.name ?? roomInfo.id,
                                         isDirect: roomInfo.isDirect,
                                         avatarURL: roomInfo.avatarUrl.flatMap(URL.init(string:)),
                                         lastMessage: attributedLastMessage,
                                         lastMessageFormattedTimestamp: lastMessageFormattedTimestamp,
                                         unreadNotificationCount: UInt(roomInfo.notificationCount),
                                         canonicalAlias: roomInfo.canonicalAlias,
                                         inviter: inviterProxy)
        
        return invalidated ? .invalidated(details: details) : .filled(details: details)
    }
    
    private func buildSummaryForRoomListEntry(_ entry: RoomListEntry) -> RoomSummary {
        switch entry {
        case .empty:
            return .empty
        case .filled(let roomId):
            return buildRoomSummaryForIdentifier(roomId, invalidated: false)
        case .invalidated(let roomId):
            guard let cachedRoom = rooms.first(where: { $0.id == roomId }) else {
                return buildRoomSummaryForIdentifier(roomId, invalidated: true)
            }
            
            switch cachedRoom {
            case .empty:
                return .empty
            case .filled(let details):
                return .invalidated(details: details)
            case .invalidated:
                return cachedRoom
            }
        }
    }
    
    private func buildDiff(from diff: RoomListEntriesUpdate, on rooms: [RoomSummary]) -> CollectionDifference<RoomSummary>? {
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .pushFront(let value):
            MXLog.info("\(name): Push Front \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
        case .pushBack(let value):
            MXLog.info("\(name): Push Back \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .append(values: let values):
            let debugIdentifiers = values.map(\.debugIdentifier)
            MXLog.info("\(name): Append \(debugIdentifiers)")
            for (index, value) in values.enumerated() {
                let summary = buildSummaryForRoomListEntry(value)
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .set(let index, let value):
            MXLog.info("\(name): Update \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .insert(let index, let value):
            MXLog.info("\(name): Insert at \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .remove(let index):
            let summary = rooms[Int(index)]
            MXLog.info("\(name): Remove \(summary.id ?? "") from \(index)")
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .reset(let values):
            let debugIdentifiers = values.map(\.debugIdentifier)
            MXLog.info("\(name): Replace all items with \(debugIdentifiers)")
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                changes.append(.insert(offset: index, element: buildSummaryForRoomListEntry(value), associatedWith: nil))
            }
        case .clear:
            MXLog.info("\(name): Clear all items")
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .popFront:
            MXLog.info("\(name): Pop Front")
            let summary = rooms[0]
            changes.append(.remove(offset: 0, element: summary, associatedWith: nil))
        case .popBack:
            MXLog.info("\(name): Pop Back")
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
    init(roomListState: RoomListLoadingState) {
        switch roomListState {
        case .notLoaded:
            self = .notLoaded
        case .loaded(let maximumNumberOfRooms):
            self = .loaded(totalNumberOfRooms: UInt(maximumNumberOfRooms ?? 0))
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
    private let onUpdateClosure: ([RoomListEntriesUpdate]) -> Void
   
    init(_ onUpdateClosure: @escaping ([RoomListEntriesUpdate]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(roomEntriesUpdate: [RoomListEntriesUpdate]) {
        onUpdateClosure(roomEntriesUpdate)
    }
}

private class RoomListStateObserver: RoomListLoadingStateListener {
    private let onUpdateClosure: (RoomListLoadingState) -> Void
   
    init(_ onUpdateClosure: @escaping (RoomListLoadingState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(state: RoomListLoadingState) {
        onUpdateClosure(state)
    }
}
