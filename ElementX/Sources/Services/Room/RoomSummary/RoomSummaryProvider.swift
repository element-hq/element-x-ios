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
    private let shouldUpdateVisibleRange: Bool
    private let notificationSettings: NotificationSettingsProxyProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    
    private let roomListPageSize = 200
    
    private let serialDispatchQueue: DispatchQueue
    
    private var roomList: RoomListProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var listUpdatesSubscriptionResult: RoomListEntriesWithDynamicAdaptersResult?
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
    
    /// Build a new summary provider with the given parameters
    /// - Parameters:
    ///   - shouldUpdateVisibleRange: whether this summary provider should foward visible ranges
    ///   to the room list service through the `applyInput(input: .viewport(ranges` api. Only useful for
    ///   lists that need to update the visible range on Sliding Sync
    init(roomListService: RoomListServiceProtocol,
         eventStringBuilder: RoomEventStringBuilder,
         name: String,
         shouldUpdateVisibleRange: Bool = false,
         notificationSettings: NotificationSettingsProxyProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol) {
        self.roomListService = roomListService
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomsummaryprovider", qos: .default)
        self.eventStringBuilder = eventStringBuilder
        self.name = name
        self.shouldUpdateVisibleRange = shouldUpdateVisibleRange
        self.notificationSettings = notificationSettings
        self.backgroundTaskService = backgroundTaskService
        
        diffsPublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
        
        setupNotificationSettingsSubscription()
    }
    
    func setRoomList(_ roomList: RoomList) {
        guard listUpdatesTaskHandle == nil, stateUpdatesTaskHandle == nil else {
            return
        }
        
        self.roomList = roomList
        
        do {
            listUpdatesSubscriptionResult = roomList.entriesWithDynamicAdapters(pageSize: UInt32(roomListPageSize), listener: RoomListEntriesListenerProxy { [weak self] updates in
                guard let self else { return }
                MXLog.verbose("\(name): Received list update")
                diffsPublisher.send(updates)
            })
            
            // Forces the listener above to be called with the current state
            setFilter(.all)
            
            listUpdatesTaskHandle = listUpdatesSubscriptionResult?.entriesStream
            
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
        if range.upperBound >= rooms.count {
            listUpdatesSubscriptionResult?.controller.addOnePage()
        } else if range.lowerBound == 0 {
            listUpdatesSubscriptionResult?.controller.resetToOnePage()
        }
        
        guard shouldUpdateVisibleRange else {
            return
        }
        
        Task {
            do {
                // The scroll view content size based visible range calculations might create large ranges
                // This is just a safety check to not overload the backend
                var upperBound = range.upperBound
                if range.upperBound - range.lowerBound > SlidingSyncConstants.maximumVisibleRangeSize {
                    upperBound = range.lowerBound + SlidingSyncConstants.maximumVisibleRangeSize
                }
                
                MXLog.info("\(name): Setting visible range to \(range.lowerBound)...\(upperBound)")
                
                try await roomListService.applyInput(input: .viewport(ranges: [.init(start: UInt32(range.lowerBound), endInclusive: UInt32(upperBound))]))
            } catch {
                MXLog.error("Failed updating visible range with error: \(error)")
            }
        }
    }
    
    func setFilter(_ filter: RoomSummaryProviderFilter) {
        switch filter {
        case .none:
            _ = listUpdatesSubscriptionResult?.controller.setFilter(kind: .none)
        case .all:
            _ = listUpdatesSubscriptionResult?.controller.setFilter(kind: .allNonLeft)
        case .normalizedMatchRoomName(let query):
            _ = listUpdatesSubscriptionResult?.controller.setFilter(kind: .normalizedMatchRoomName(pattern: query.lowercased()))
        }
    }
    
    // MARK: - Private
        
    fileprivate func updateRoomsWithDiffs(_ diffs: [RoomListEntriesUpdate]) {
        let span = MXLog.createSpan("\(name).process_room_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        MXLog.info("Started processing room list diffs")
        
        MXLog.verbose("\(name): Received \(diffs.count) diffs, current room list \(rooms.compactMap { $0.id ?? "Empty" })")
        
        rooms = diffs.reduce(rooms) { currentItems, diff in
            processDiff(diff, on: currentItems)
        }
        
        MXLog.verbose("\(name): Finished applying \(diffs.count) diffs, new room list \(rooms.compactMap { $0.id ?? "Empty" })")
        
        MXLog.info("Finished processing room list diffs")
    }
    
    private func processDiff(_ diff: RoomListEntriesUpdate, on currentItems: [RoomSummary]) -> [RoomSummary] {
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
        
        let notificationMode = roomInfo.userDefinedNotificationMode.flatMap { RoomNotificationModeProxy.from(roomNotificationMode: $0) }
        
        let details = RoomSummaryDetails(id: roomInfo.id,
                                         name: roomInfo.name ?? roomInfo.id,
                                         isDirect: roomInfo.isDirect,
                                         avatarURL: roomInfo.avatarUrl.flatMap(URL.init(string:)),
                                         lastMessage: attributedLastMessage,
                                         lastMessageFormattedTimestamp: lastMessageFormattedTimestamp,
                                         unreadNotificationCount: UInt(roomInfo.notificationCount),
                                         notificationMode: notificationMode,
                                         canonicalAlias: roomInfo.canonicalAlias,
                                         inviter: inviterProxy,
                                         hasOngoingCall: roomInfo.hasRoomCall)
        
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
        case .append(let values):
            let debugIdentifiers = values.map(\.debugIdentifier)
            MXLog.verbose("\(name): Append \(debugIdentifiers)")
            for (index, value) in values.enumerated() {
                let summary = buildSummaryForRoomListEntry(value)
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .clear:
            MXLog.verbose("\(name): Clear all items")
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .insert(let index, let value):
            MXLog.verbose("\(name): Insert at \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .popBack:
            MXLog.verbose("\(name): Pop Back")
            guard let value = rooms.last else {
                fatalError()
            }
            
            changes.append(.remove(offset: rooms.count - 1, element: value, associatedWith: nil))
        case .popFront:
            MXLog.verbose("\(name): Pop Front")
            let summary = rooms[0]
            changes.append(.remove(offset: 0, element: summary, associatedWith: nil))
        case .pushBack(let value):
            MXLog.verbose("\(name): Push Back \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .pushFront(let value):
            MXLog.verbose("\(name): Push Front \(value.debugIdentifier)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
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
        case .set(let index, let value):
            MXLog.verbose("\(name): Update \(value.debugIdentifier) at \(index)")
            let summary = buildSummaryForRoomListEntry(value)
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .truncate(let length):
            for (index, value) in rooms.enumerated() {
                if index < length {
                    continue
                }
                
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        }
        
        return CollectionDifference(changes)
    }
    
    private func setupNotificationSettingsSubscription() {
        notificationSettings.callbacks
            .receive(on: serialDispatchQueue)
            .dropFirst() // drop the first one to avoid rebuilding the summaries during the first synchronization
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .settingsDidChange:
                    self.rebuildRoomSummaries()
                }
            }
            .store(in: &cancellables)
    }
    
    private func rebuildRoomSummaries() {
        let span = MXLog.createSpan("\(name).rebuild_room_summaries")
        span.enter()
        defer {
            span.exit()
        }
        
        MXLog.info("\(name): Rebuilding room summaries for \(rooms.count) rooms")
        
        rooms = rooms.map {
            switch $0 {
            case .empty:
                return $0
            case .filled(let details):
                return self.buildRoomSummaryForIdentifier(details.id, invalidated: false)
            case .invalidated(let details):
                return self.buildRoomSummaryForIdentifier(details.id, invalidated: true)
            }
        }
        
        MXLog.info("\(name): Finished rebuilding room summaries (\(rooms.count) rooms)")
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
