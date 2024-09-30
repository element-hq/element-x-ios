//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    private let appSettings: AppSettings

    private let roomListPageSize = 200
    
    private let serialDispatchQueue: DispatchQueue
    
    private let visibleItemRangePublisher = CurrentValueSubject<Range<Int>, Never>(0..<0)
    
    // periphery:ignore - retaining purpose
    private var roomList: RoomListProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var roomListServiceStateCancellable: AnyCancellable?
    private var listUpdatesSubscriptionResult: RoomListEntriesWithDynamicAdaptersResult?
    private var stateUpdatesTaskHandle: TaskHandle?
    
    private let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
    private let stateSubject = CurrentValueSubject<RoomSummaryProviderState, Never>(.notLoaded)
    
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
    ///   - shouldUpdateVisibleRange: whether this summary provider should forward visible ranges
    ///   to the room list service through the `applyInput(input: .viewport(ranges` api. Only useful for
    ///   lists that need to update the visible range on Sliding Sync
    init(roomListService: RoomListServiceProtocol,
         eventStringBuilder: RoomEventStringBuilder,
         name: String,
         shouldUpdateVisibleRange: Bool = false,
         notificationSettings: NotificationSettingsProxyProtocol,
         appSettings: AppSettings) {
        self.roomListService = roomListService
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomsummaryprovider", qos: .default)
        self.eventStringBuilder = eventStringBuilder
        self.name = name
        self.shouldUpdateVisibleRange = shouldUpdateVisibleRange
        self.notificationSettings = notificationSettings
        self.appSettings = appSettings
        
        diffsPublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
        
        setupVisibleRangeObservers()
        
        setupNotificationSettingsSubscription()
    }
    
    func setRoomList(_ roomList: RoomList) {
        guard stateUpdatesTaskHandle == nil else {
            return
        }
        
        self.roomList = roomList
        
        do {
            listUpdatesSubscriptionResult = roomList.entriesWithDynamicAdapters(pageSize: UInt32(roomListPageSize), listener: RoomListEntriesListenerProxy { [weak self] updates in
                guard let self else { return }
                diffsPublisher.send(updates)
            })
            
            // Forces the listener above to be called with the current state
            setFilter(.all(filters: []))
            
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
        visibleItemRangePublisher.send(range)
    }
    
    func setFilter(_ filter: RoomSummaryProviderFilter) {
        switch filter {
        case .excludeAll:
            _ = listUpdatesSubscriptionResult?.controller().setFilter(kind: .none)
        case let .search(query):
            let filters: [RoomListEntriesDynamicFilterKind] = if appSettings.fuzzyRoomListSearchEnabled {
                [.fuzzyMatchRoomName(pattern: query), .nonLeft]
            } else {
                [.normalizedMatchRoomName(pattern: query), .nonLeft]
            }
            _ = listUpdatesSubscriptionResult?.controller().setFilter(kind: .all(filters: filters))
        case let .all(filters):
            var filters = filters.map(\.rustFilter)
            filters.append(.nonLeft)
            _ = listUpdatesSubscriptionResult?.controller().setFilter(kind: .all(filters: filters))
        }
    }
    
    // MARK: - Private
    
    private func setupVisibleRangeObservers() {
        visibleItemRangePublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .sink { [weak self] range in
                guard let self else { return }
                
                MXLog.info("\(self.name): Updating visible range: \(range)")
                
                if range.upperBound >= rooms.count {
                    listUpdatesSubscriptionResult?.controller().addOnePage()
                } else if range.lowerBound == 0 {
                    listUpdatesSubscriptionResult?.controller().resetToOnePage()
                }
            }
            .store(in: &cancellables)
        
        visibleItemRangePublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .filter { [weak self] range in
                guard let self else { return false }
                return !range.isEmpty && shouldUpdateVisibleRange
            }
            .compactMap { [weak self] (range: Range) -> [String]? in
                guard let self else { return nil }
                
                // The scroll view content size based visible range calculations might create large ranges
                // This is just a safety check to not overload the backend
                var range = range
                if range.upperBound - range.lowerBound > SlidingSyncConstants.maximumVisibleRangeSize {
                    let upperBound = range.lowerBound + SlidingSyncConstants.maximumVisibleRangeSize
                    range = range.lowerBound..<upperBound
                }
                
                return range
                    .filter { $0 < self.rooms.count }
                    .map { self.rooms[$0].id }
            }
            .removeDuplicates()
            .sink { [weak self] roomIDs in
                guard let self else { return }
                
                do {
                    try roomListService.subscribeToRooms(roomIds: roomIDs,
                                                         settings: .init(requiredState: SlidingSyncConstants.defaultRequiredState,
                                                                         timelineLimit: SlidingSyncConstants.defaultTimelineLimit,
                                                                         includeHeroes: false))
                } catch {
                    MXLog.error("Failed subscribing to rooms with error: \(error)")
                }
            }
            .store(in: &cancellables)
    }
    
    fileprivate func updateRoomsWithDiffs(_ diffs: [RoomListEntriesUpdate]) {
        let span = MXLog.createSpan("\(name).process_room_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        rooms = diffs.reduce(rooms) { currentItems, diff in
            processDiff(diff, on: currentItems)
        }
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

    private func fetchRoomDetails(from roomListItem: RoomListItem) -> (roomInfo: RoomInfo?, latestEvent: EventTimelineItem?) {
        class FetchResult {
            var roomInfo: RoomInfo?
            var latestEvent: EventTimelineItem?
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let result = FetchResult()
        
        Task {
            do {
                result.latestEvent = await roomListItem.latestEvent()
                result.roomInfo = try await roomListItem.roomInfo()
            } catch {
                MXLog.error("Failed fetching room info with error: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
        return (result.roomInfo, result.latestEvent)
    }
    
    private func buildRoomSummary(from roomListItem: RoomListItem) -> RoomSummary {
        let roomDetails = fetchRoomDetails(from: roomListItem)
        
        guard let roomInfo = roomDetails.roomInfo else {
            fatalError("Missing room info for \(roomListItem.id())")
        }
        
        var attributedLastMessage: AttributedString?
        var lastMessageFormattedTimestamp: String?
        
        if let latestRoomMessage = roomDetails.latestEvent {
            let lastMessage = EventTimelineItemProxy(item: latestRoomMessage, id: "0")
            lastMessageFormattedTimestamp = lastMessage.timestamp.formattedMinimal()
            attributedLastMessage = eventStringBuilder.buildAttributedString(for: lastMessage)
        }
        
        var inviterProxy: RoomMemberProxyProtocol?
        if let inviter = roomInfo.inviter {
            inviterProxy = RoomMemberProxy(member: inviter)
        }
        
        let notificationMode = roomInfo.cachedUserDefinedNotificationMode.flatMap { RoomNotificationModeProxy.from(roomNotificationMode: $0) }
        
        return RoomSummary(roomListItem: roomListItem,
                           id: roomInfo.id,
                           isInvite: roomInfo.membership == .invited,
                           inviter: inviterProxy,
                           name: roomInfo.displayName ?? roomInfo.id,
                           isDirect: roomInfo.isDirect,
                           avatarURL: roomInfo.avatarUrl.flatMap(URL.init(string:)),
                           heroes: roomInfo.heroes.map(UserProfileProxy.init),
                           lastMessage: attributedLastMessage,
                           lastMessageFormattedTimestamp: lastMessageFormattedTimestamp,
                           unreadMessagesCount: UInt(roomInfo.numUnreadMessages),
                           unreadMentionsCount: UInt(roomInfo.numUnreadMentions),
                           unreadNotificationsCount: UInt(roomInfo.numUnreadNotifications),
                           notificationMode: notificationMode,
                           canonicalAlias: roomInfo.canonicalAlias,
                           hasOngoingCall: roomInfo.hasRoomCall,
                           isMarkedUnread: roomInfo.isMarkedUnread,
                           isFavourite: roomInfo.isFavourite)
    }
    
    private func buildDiff(from diff: RoomListEntriesUpdate, on rooms: [RoomSummary]) -> CollectionDifference<RoomSummary>? {
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .append(let values):
            for (index, value) in values.enumerated() {
                let summary = buildRoomSummary(from: value)
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .clear:
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .insert(let index, let value):
            let summary = buildRoomSummary(from: value)
            changes.append(.insert(offset: Int(index), element: summary, associatedWith: nil))
        case .popBack:
            guard let value = rooms.last else {
                fatalError()
            }
            
            changes.append(.remove(offset: rooms.count - 1, element: value, associatedWith: nil))
        case .popFront:
            let summary = rooms[0]
            changes.append(.remove(offset: 0, element: summary, associatedWith: nil))
        case .pushBack(let value):
            let summary = buildRoomSummary(from: value)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .pushFront(let value):
            let summary = buildRoomSummary(from: value)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
        case .remove(let index):
            let summary = rooms[Int(index)]
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .reset(let values):
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                changes.append(.insert(offset: index, element: buildRoomSummary(from: value), associatedWith: nil))
            }
        case .set(let index, let value):
            let summary = buildRoomSummary(from: value)
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
            self.buildRoomSummary(from: $0.roomListItem)
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
