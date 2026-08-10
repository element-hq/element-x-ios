//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
    private let visibleRoomsPrioritizer: (([String]) async throws -> Void)?

    private let roomListPageSize: UInt32
    /// The `rooms` count when the last page growth was requested; suppresses repeated
    /// `addOnePage` calls while the previous growth is still being applied.
    private var lastGrowthRequestRoomCount = -1
    
    private let visibleItemRangePublisher = CurrentValueSubject<Range<Int>, Never>(0..<0)
    
    // periphery:ignore - retaining purpose
    private var roomList: RoomListProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var listUpdatesSubscriptionResult: RoomListEntriesWithDynamicAdaptersResult?
    private var stateUpdatesTaskHandle: TaskHandle?
    private var appliedFilter: RoomSummaryProviderFilter?
    
    private let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
    private let stateSubject = CurrentValueSubject<RoomSummaryProviderState, Never>(.notLoaded)
    
    /// Bridge from the SDK's synchronous callback into Swift Concurrency. Yielding is safe from any
    /// thread; a single long-lived `for await` consumer (set up in `init`) applies the diffs on the
    /// main actor in FIFO order, guaranteeing one in-flight update at a time.
    private let diffsContinuation: AsyncStream<[RoomListEntriesUpdate]>.Continuation
    
    /// Same bridging pattern as `diffsContinuation`, for the room list loading state.
    private let loadingStateContinuation: AsyncStream<RoomListLoadingState>.Continuation
    
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
    ///   - visibleRoomsPrioritizer: when set, visible-range changes are forwarded here (the
    ///   back-pagination queue preload) INSTEAD of subscribing to the rooms on Sliding Sync: a
    ///   /messages request per needy room beats waiting for the sync loop to restart its round.
    init(roomListService: RoomListServiceProtocol,
         eventStringBuilder: RoomEventStringBuilder,
         name: String,
         shouldUpdateVisibleRange: Bool = false,
         roomListPageSize: UInt32 = 100,
         notificationSettings: NotificationSettingsProxyProtocol,
         appSettings: AppSettings,
         visibleRoomsPrioritizer: (([String]) async throws -> Void)? = nil) {
        self.roomListService = roomListService
        self.eventStringBuilder = eventStringBuilder
        self.name = name
        self.shouldUpdateVisibleRange = shouldUpdateVisibleRange
        self.notificationSettings = notificationSettings
        self.appSettings = appSettings
        self.roomListPageSize = roomListPageSize
        self.visibleRoomsPrioritizer = visibleRoomsPrioritizer
        
        let (diffsStream, diffsContinuation) = AsyncStream<[RoomListEntriesUpdate]>.makeStream()
        self.diffsContinuation = diffsContinuation
        
        let (loadingStateStream, loadingStateContinuation) = AsyncStream<RoomListLoadingState>.makeStream()
        self.loadingStateContinuation = loadingStateContinuation
        
        Task { [weak self] in
            for await diffs in diffsStream {
                await self?.updateRoomsWithDiffs(diffs)
            }
        }
        
        Task { [weak self, name] in
            for await state in loadingStateStream {
                MXLog.info("\(name): Received state update: \(state)")
                self?.stateSubject.send(RoomSummaryProviderState(roomListState: state))
            }
        }
        
        setupVisibleRangeObservers()
        
        setupNotificationSettingsSubscription()
    }
    
    deinit {
        diffsContinuation.finish()
        loadingStateContinuation.finish()
    }
    
    func setRoomList(_ roomList: RoomList) {
        guard stateUpdatesTaskHandle == nil else {
            return
        }
        
        self.roomList = roomList
        
        do {
            listUpdatesSubscriptionResult = roomList.entriesWithDynamicAdapters(pageSize: UInt32(roomListPageSize),
                                                                                listener: SDKListener { [diffsContinuation] updates in
                                                                                    diffsContinuation.yield(updates)
                                                                                })
            
            // Forces the listener above to be called with the current state
            setFilter(.all(filters: []))
            
            let stateUpdatesSubscriptionResult = try roomList.loadingState(listener: SDKListener { [loadingStateContinuation] state in
                loadingStateContinuation.yield(state)
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
        // Re-applying the same filter would make the SDK re-emit a full reset
        // for an identical list, e.g. at startup where the home screen's initial
        // filter matches the one applied in `setRoomList`.
        guard filter != appliedFilter else {
            return
        }
        appliedFilter = filter

        let baseFilter: [RoomListEntriesDynamicFilterKind] = [.any(filters: [.all(filters: [.nonSpace, .nonLeft]),
                                                                             .all(filters: [.space, .invite])]),
                                                              .deduplicateVersions]

        switch filter {
        case .excludeAll:
            _ = listUpdatesSubscriptionResult?.controller().setFilter(kind: .none)
        case let .search(query):
            let filters = if appSettings.fuzzyRoomListSearchEnabled {
                [.fuzzyMatchRoomName(pattern: query)] + baseFilter
            } else {
                [.normalizedMatchRoomName(pattern: query)] + baseFilter
            }
            _ = listUpdatesSubscriptionResult?.controller().setFilter(kind: .all(filters: filters))
        case .rooms(let roomIDs, let filters):
            var rustFilters = filters.map(\.rustFilter) + baseFilter
            
            rustFilters.append(.identifiers(identifiers: Array(roomIDs)))
            
            if !filters.contains(.lowPriority), appSettings.lowPriorityFilterEnabled {
                rustFilters.append(.nonLowPriority)
            }
            
            _ = listUpdatesSubscriptionResult?.controller().setFilter(kind: .all(filters: rustFilters))
        case let .all(filters):
            var rustFilters = filters.map(\.rustFilter) + baseFilter
            
            if !filters.contains(.lowPriority), appSettings.lowPriorityFilterEnabled {
                rustFilters.append(.nonLowPriority)
            }
            
            _ = listUpdatesSubscriptionResult?.controller().setFilter(kind: .all(filters: rustFilters))
        }
    }
    
    // MARK: - Private
    
    private func setupVisibleRangeObservers() {
        // Unthrottled: grow the list half a page before the user reaches the bottom so
        // the next page is in by the time they get there, instead of bouncing off the
        // end while it loads. Ranges stream in on every scroll tick, so re-requests are
        // suppressed until the previous growth has actually landed in `rooms`.
        visibleItemRangePublisher
            .sink { [weak self] range in
                guard let self,
                      !range.isEmpty, // The publisher's initial 0..<0 would otherwise trigger a page add before the list even loads
                      range.upperBound >= rooms.count - Int(roomListPageSize) / 2,
                      rooms.count != lastGrowthRequestRoomCount else {
                    return
                }

                lastGrowthRequestRoomCount = rooms.count

                MXLog.info("\(self.name): Adding a page at \(rooms.count) rooms, visible range: \(range)")

                listUpdatesSubscriptionResult?.controller().addOnePage()
            }
            .store(in: &cancellables)

        visibleItemRangePublisher
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates()
            .sink { [weak self] range in
                guard let self else { return }

                MXLog.info("\(self.name): Updating visible range: \(range)")

                if range.lowerBound == 0, range.upperBound < rooms.count {
                    // The shrink lands `rooms` back on a count the growth guard may have
                    // already recorded, so re-arm it explicitly.
                    lastGrowthRequestRoomCount = -1
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

                Task { [weak self] in
                    do {
                        if let prioritizer = self?.visibleRoomsPrioritizer {
                            try await prioritizer(roomIDs)
                        } else {
                            try await self?.roomListService.subscribeToRooms(roomIds: roomIDs)
                        }
                    } catch {
                        MXLog.error("Failed subscribing to rooms with error: \(error)")
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    fileprivate func updateRoomsWithDiffs(_ diffs: [RoomListEntriesUpdate]) async {
        // Building the room summaries (SDK fetches + string building) and applying the
        // CollectionDifference can be expensive, so compute off the main actor and only
        // hop back to publish the result.
        let visibleBefore = Self.visibleSignature(of: rooms)
        let start = Date.now
        rooms = await Self.updatedRooms(from: diffs, on: rooms, eventStringBuilder: eventStringBuilder, name: name)
        let duration = Date.now.timeIntervalSince(start)
        if duration > 0.025 {
            MXLog.info("\(name): Built \(rooms.count) room summaries in \(Int(duration * 1000))ms")
        }
        // Launch instrumentation: track when the top of the home list stops changing.
        if shouldUpdateVisibleRange, Self.visibleSignature(of: rooms) != visibleBefore {
            LaunchMetrics.noteVisibleChurn()
        }
    }

    /// What a user actually sees at the top of the list: room identity, ordering and
    /// preview content (hashValue is process-stable, which is all change detection needs).
    private nonisolated static func visibleSignature(of rooms: [RoomSummary]) -> [String] {
        rooms.prefix(12).map { "\($0.id)|\($0.lastMessageDate?.timeIntervalSince1970 ?? 0)|\($0.lastMessage?.description.hashValue ?? 0)" }
    }
    
    @concurrent
    private static func updatedRooms(from diffs: [RoomListEntriesUpdate],
                                     on currentRooms: [RoomSummary],
                                     eventStringBuilder: RoomEventStringBuilder,
                                     name: String) async -> [RoomSummary] {
        // No tracing span here: the body awaits, so the deferred exit() can run on a
        // different thread than enter(), which sentry-tracing panics on under
        // debug-assertions builds (and leaks hub state otherwise).
        var updatedRooms = currentRooms
        for diff in diffs {
            updatedRooms = await processDiff(diff, on: updatedRooms, eventStringBuilder: eventStringBuilder, name: name)
        }
        return updatedRooms
    }
    
    private nonisolated static func processDiff(_ diff: RoomListEntriesUpdate, on currentItems: [RoomSummary], eventStringBuilder: RoomEventStringBuilder, name: String) async -> [RoomSummary] {
        guard let collectionDiff = await buildDiff(from: diff, on: currentItems, eventStringBuilder: eventStringBuilder) else {
            MXLog.error("\(name): Failed building CollectionDifference from \(diff)")
            return currentItems
        }
        
        guard let updatedItems = currentItems.applying(collectionDiff) else {
            MXLog.error("\(name): Failed applying diff: \(collectionDiff)")
            return currentItems
        }
        
        return updatedItems
    }
    
    /// Builds summaries for a batch of rooms, preserving order. Each summary costs
    /// several store reads through the FFI; building a whole account's reset batch
    /// one room at a time serialises all of them in front of the room list's first
    /// paint, so build a bounded number concurrently instead.
    private nonisolated static func buildRoomSummaries(from rooms: [Room], eventStringBuilder: RoomEventStringBuilder) async -> [RoomSummary] {
        await withTaskGroup(of: (Int, RoomSummary).self) { group in
            let maxConcurrency = 8
            var summaries = [RoomSummary?](repeating: nil, count: rooms.count)
            var submitted = 0

            func submitNext() {
                guard submitted < rooms.count else { return }
                let index = submitted
                let room = rooms[index]
                submitted += 1
                group.addTask {
                    await (index, buildRoomSummary(from: room, eventStringBuilder: eventStringBuilder))
                }
            }

            for _ in 0..<min(maxConcurrency, rooms.count) {
                submitNext()
            }
            while let (index, summary) = await group.next() {
                summaries[index] = summary
                submitNext()
            }

            return summaries.compactMap(\.self)
        }
    }

    private nonisolated static func buildRoomSummary(from room: Room, eventStringBuilder: RoomEventStringBuilder) async -> RoomSummary {
        let details: RoomSummaryDetails
        do {
            // A single slim FFI call with everything a room-list entry renders; unlike
            // `room.roomInfo()` it doesn't query the store for data the list never shows.
            details = try await room.roomSummaryDetails()
        } catch {
            // The room info can be momentarily unavailable while the client tears down (e.g. on logout),
            // where the SDK still delivers a diff but the room details throw. Return a placeholder to
            // keep the diff indices aligned with the SDK instead of crashing.
            MXLog.error("Missing room summary details for \(room.id()): \(error)")
            return .placeholder(room: room)
        }

        var attributedLastMessage: AttributedString?
        var lastMessageDate: Date?
        var lastMessageState: RoomSummary.LastMessageState?

        switch details.latestEvent {
        case .local(let timestamp, let senderID, let profile, let content, let state):
            let sender = TimelineItemSender(senderID: senderID, senderProfile: profile)
            attributedLastMessage = eventStringBuilder.buildAttributedString(for: content, sender: sender, isOutgoing: true)
            lastMessageDate = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))

            switch state {
            case .isSending:
                lastMessageState = .sending
            case .cannotBeSent:
                lastMessageState = .failed
            case .hasBeenSent:
                lastMessageState = nil
            }
        case .remote(let timestamp, let senderID, let isOwn, let profile, let content):
            let sender = TimelineItemSender(senderID: senderID, senderProfile: profile)
            attributedLastMessage = eventStringBuilder.buildAttributedString(for: content, sender: sender, isOutgoing: isOwn)
            lastMessageDate = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        case .remoteInvite(let timestamp, let senderID, let profile):
            // Stripped invites carry no origin_server_ts; the room still sorts correctly
            // via its recency stamp, the row just shows no date.
            lastMessageDate = timestamp.map { Date(timeIntervalSince1970: TimeInterval($0 / 1000)) }

            if let senderID {
                let sender = TimelineItemSender(senderID: senderID, senderProfile: profile)
                let senderDisplayName = sender.displayName ?? sender.id
                let invitedYouString = eventStringBuilder.stateEventStringBuilder.buildInvitedYouString(senderDisplayName)
                attributedLastMessage = AttributedString(invitedYouString)
            }
        case .none:
            break
        }

        var inviterProxy: RoomMemberProxyProtocol?
        if let inviter = details.inviter {
            inviterProxy = RoomMemberProxy(member: inviter)
        }

        let notificationMode = details.cachedUserDefinedNotificationMode.flatMap { RoomNotificationModeProxy.from(roomNotificationMode: $0) }

        let joinRequestType: RoomSummary.JoinRequestType? = switch details.membership {
        case .invited: .invite(inviter: inviterProxy)
        case .knocked: .knock
        default: nil
        }

        let activeCallIntent: RtcCallIntent? = switch details.activeRoomCallConsensusIntent {
        case .full(let intent):
            intent
        case .partial(intent: let intent, _, _):
            intent
        case .none:
            nil
        }

        return RoomSummary(room: room,
                           id: details.id,
                           joinRequestType: joinRequestType,
                           name: details.displayName ?? details.id,
                           isDirect: details.isDirect,
                           isSpace: details.isSpace,
                           avatarURL: details.avatarUrl.flatMap(URL.init(string:)),
                           heroes: details.heroes.map(UserProfile.init),
                           activeMembersCount: UInt(details.activeMembersCount),
                           lastMessage: attributedLastMessage,
                           lastMessageDate: lastMessageDate,
                           lastMessageState: lastMessageState,
                           unreadMessagesCount: UInt(details.numUnreadMessages),
                           unreadMentionsCount: UInt(details.numUnreadMentions),
                           unreadNotificationsCount: UInt(details.numUnreadNotifications),
                           notificationMode: notificationMode,
                           canonicalAlias: details.canonicalAlias,
                           alternativeAliases: .init(details.alternativeAliases),
                           hasOngoingCall: details.hasRoomCall,
                           activeCallIntent: activeCallIntent.map { .init(rustCallIntent: $0) },
                           isMarkedUnread: details.isMarkedUnread,
                           isFavourite: details.isFavourite,
                           isTombstoned: details.successorRoom != nil)
    }
    
    private nonisolated static func buildDiff(from diff: RoomListEntriesUpdate, on rooms: [RoomSummary], eventStringBuilder: RoomEventStringBuilder) async -> CollectionDifference<RoomSummary>? {
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .append(let values):
            for (index, summary) in await buildRoomSummaries(from: values, eventStringBuilder: eventStringBuilder).enumerated() {
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .clear:
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .insert(let index, let value):
            let summary = await buildRoomSummary(from: value, eventStringBuilder: eventStringBuilder)
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
            let summary = await buildRoomSummary(from: value, eventStringBuilder: eventStringBuilder)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .pushFront(let value):
            let summary = await buildRoomSummary(from: value, eventStringBuilder: eventStringBuilder)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
        case .remove(let index):
            let summary = rooms[Int(index)]
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .reset(let values):
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }

            for (index, summary) in await buildRoomSummaries(from: values, eventStringBuilder: eventStringBuilder).enumerated() {
                changes.append(.insert(offset: index, element: summary, associatedWith: nil))
            }
        case .set(let index, let value):
            let summary = await buildRoomSummary(from: value, eventStringBuilder: eventStringBuilder)
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
            .receive(on: DispatchQueue.main)
            .dropFirst() // drop the first one to avoid rebuilding the summaries during the first synchronization
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .settingsDidChange:
                    Task { await self.rebuildRoomSummaries() }
                }
            }
            .store(in: &cancellables)
    }
    
    private func rebuildRoomSummaries() async {
        MXLog.info("\(name): Rebuilding room summaries for \(rooms.count) rooms")
        
        rooms = await Self.rebuiltRoomSummaries(from: rooms, eventStringBuilder: eventStringBuilder, name: name)
        
        MXLog.info("\(name): Finished rebuilding room summaries (\(rooms.count) rooms)")
    }
    
    @concurrent
    private static func rebuiltRoomSummaries(from rooms: [RoomSummary], eventStringBuilder: RoomEventStringBuilder, name: String) async -> [RoomSummary] {
        // No tracing span - see updatedRooms(from:on:eventStringBuilder:name:).
        var rebuiltRooms = [RoomSummary]()
        rebuiltRooms.reserveCapacity(rooms.count)
        for room in rooms {
            await rebuiltRooms.append(buildRoomSummary(from: room.room, eventStringBuilder: eventStringBuilder))
        }
        return rebuiltRooms
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
