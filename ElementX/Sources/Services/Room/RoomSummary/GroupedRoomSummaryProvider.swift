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

class GroupedRoomSummaryProvider: RoomSummaryProviderProtocol {
    private let groupedRoomListService: GroupedRoomListServiceProtocol
    private let eventStringBuilder: RoomEventStringBuilder
    private let name: String
    private let shouldUpdateVisibleRange: Bool
    private let notificationSettings: NotificationSettingsProxyProtocol
    private let appSettings: AppSettings

    private let roomListPageSize: UInt32
    
    private let serialDispatchQueue: DispatchQueue
    
    private var cancellables = Set<AnyCancellable>()
    
    private var stateUpdatesTaskHandle: TaskHandle?
    
    private var groupedRoomListEntriesTaskHandle: TaskHandle?
    
    private let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
    private let stateSubject = CurrentValueSubject<RoomSummaryProviderState, Never>(.notLoaded)
    
    private let diffsPublisher = PassthroughSubject<[GroupedRoomListUpdate], Never>()
    
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
    init(groupedRoomListService: GroupedRoomListServiceProtocol,
         eventStringBuilder: RoomEventStringBuilder,
         name: String,
         shouldUpdateVisibleRange: Bool = false,
         roomListPageSize: UInt32 = 200,
         notificationSettings: NotificationSettingsProxyProtocol,
         appSettings: AppSettings) {
        self.groupedRoomListService = groupedRoomListService
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.grouped_room_summary_provider", qos: .default)
        self.eventStringBuilder = eventStringBuilder
        self.name = name
        self.shouldUpdateVisibleRange = shouldUpdateVisibleRange
        self.notificationSettings = notificationSettings
        self.appSettings = appSettings
        self.roomListPageSize = roomListPageSize
        
        diffsPublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] in self?.updateRoomsWithDiffs($0) }
            .store(in: &cancellables)
        
        Task {
            await groupedRoomListService.setup()
            
            groupedRoomListEntriesTaskHandle = await groupedRoomListService.subscribeToEntries(listener: SDKListener { [weak self] updates in
                guard let self else { return }
                diffsPublisher.send(updates)
            })
            
            // TODO: figure this out
            stateSubject.send(RoomSummaryProviderState.loaded(totalNumberOfRooms: 100))
        }
        
        // setupNotificationSettingsSubscription()
    }
    
    func setRoomList(_ roomList: RoomList) {
        // TODO: Just do it™
//        guard stateUpdatesTaskHandle == nil else {
//            return
//        }
//
//        do {
//            let stateUpdatesSubscriptionResult = try roomList.loadingState(listener: SDKListener { [weak self] state in
//                guard let self else { return }
//                MXLog.info("\(name): Received state update: \(state)")
//                stateSubject.send(RoomSummaryProviderState(roomListState: state))
//            })
//
//            stateUpdatesTaskHandle = stateUpdatesSubscriptionResult.stateStream
//
//            stateSubject.send(RoomSummaryProviderState(roomListState: stateUpdatesSubscriptionResult.state))
//        } catch {
//            MXLog.error("Failed setting up room list entry listener with error: \(error)")
//        }
    }
    
    func updateVisibleRange(_ range: Range<Int>) {
        // TODO: Just do it™
    }
    
    func setFilter(_ filter: RoomSummaryProviderFilter) {
        Task {
            let baseFilter: [RoomListEntriesDynamicFilterKind] = [.any(filters: [.all(filters: [.nonSpace, .nonLeft]),
                                                                                 .all(filters: [.space, .invite])]),
                                                                  .deduplicateVersions]
            
            switch filter {
            case .excludeAll:
                await self.groupedRoomListService.setFilter(filter: .standard(filter: .none))
            case let .search(query):
                let filters = if appSettings.fuzzyRoomListSearchEnabled {
                    [.fuzzyMatchRoomName(pattern: query)] + baseFilter
                } else {
                    [.normalizedMatchRoomName(pattern: query)] + baseFilter
                }
                
                await self.groupedRoomListService.setFilter(filter: .standard(filter: .all(filters: filters)))
            case let .all(filters):
                var rustFilters = filters.map(\.rustFilter) + baseFilter
                
                if !filters.contains(.lowPriority), appSettings.lowPriorityFilterEnabled {
                    rustFilters.append(.nonLowPriority)
                }
                
                await self.groupedRoomListService.setFilter(filter: .standard(filter: .all(filters: rustFilters)))
            case .groupedSpaces:
                await self.groupedRoomListService.setFilter(filter: .groupedSpaces)
            }
        }
    }
    
    // MARK: - Private
    
    fileprivate func updateRoomsWithDiffs(_ diffs: [GroupedRoomListUpdate]) {
        let span = MXLog.createSpan("\(name).process_room_list_diffs")
        span.enter()
        defer {
            span.exit()
        }
        
        rooms = diffs.reduce(rooms) { currentItems, diff in
            processDiff(diff, on: currentItems)
        }
    }
    
    private func processDiff(_ diff: GroupedRoomListUpdate, on currentItems: [RoomSummary]) -> [RoomSummary] {
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

    // swiftlint:disable:next large_tuple
    private func fetchRoomDetails(mainRoom: Room, previewRoom: Room?) -> (mainRoomInfo: RoomInfo, previewRoomInfo: RoomInfo?, latestEvent: LatestEventValue?) {
        class FetchResult {
            var mainRoomInfo: RoomInfo?
            var previewRoomInfo: RoomInfo?
            var latestEvent: LatestEventValue?
        }
        
        let semaphore = DispatchSemaphore(value: 0)
        let result = FetchResult()
        
        Task {
            do {
                result.mainRoomInfo = try await mainRoom.roomInfo()
                
                if let previewRoom {
                    result.previewRoomInfo = try await previewRoom.roomInfo()
                    result.latestEvent = await previewRoom.newLatestEvent()
                }
                
            } catch {
                MXLog.error("Failed fetching room info with error: \(error)")
            }
            semaphore.signal()
        }
        semaphore.wait()
        
        guard let mainRoomInfo = result.mainRoomInfo else {
            fatalError("Missing room info for \(mainRoom.id())")
        }
        
        return (mainRoomInfo, result.previewRoomInfo, result.latestEvent)
    }
    
    private func buildRoomSummary(roomListItem: GroupedRoomListItem) -> RoomSummary {
        let (mainRoom, previewRoom): (Room, Room?) = switch roomListItem {
        case .room(let room):
            (room, room)
        case .space(let spaceRoom, let room):
            (spaceRoom, room)
        }
        
        let roomDetails = fetchRoomDetails(mainRoom: mainRoom, previewRoom: previewRoom)
                
        var attributedLastMessage: AttributedString?
        var lastMessageDate: Date?
        var lastMessageState: RoomSummary.LastMessageState?
        
        if let latestRoomMessage = roomDetails.latestEvent {
            switch latestRoomMessage {
            case .local(let timestamp, let senderID, let profile, let content, let isSending):
                let sender = TimelineItemSender(senderID: senderID, senderProfile: profile)
                attributedLastMessage = eventStringBuilder.buildAttributedString(for: content, sender: sender, isOutgoing: true)
                lastMessageDate = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
                lastMessageState = isSending ? .sending : .failed // No need to worry about sent for .local: https://github.com/matrix-org/matrix-rust-sdk/issues/3941
            case .remote(let timestamp, let senderID, let isOwn, let profile, let content):
                let sender = TimelineItemSender(senderID: senderID, senderProfile: profile)
                attributedLastMessage = eventStringBuilder.buildAttributedString(for: content, sender: sender, isOutgoing: isOwn)
                lastMessageDate = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
            case .none:
                break
            }
            
            if attributedLastMessage != nil {
                if roomDetails.mainRoomInfo.isSpace, let previewRoomInfo = roomDetails.previewRoomInfo {
                    attributedLastMessage = try? AttributedString(markdown: "**\(previewRoomInfo.displayName ?? previewRoomInfo.id):**&nbsp;") + (attributedLastMessage ?? "")
                }
            }
        }
        
        var inviterProxy: RoomMemberProxyProtocol?
        if let inviter = roomDetails.mainRoomInfo.inviter {
            inviterProxy = RoomMemberProxy(member: inviter)
        }
        
        let notificationMode = roomDetails.previewRoomInfo?.cachedUserDefinedNotificationMode.flatMap { RoomNotificationModeProxy.from(roomNotificationMode: $0) }
        
        let joinRequestType: RoomSummary.JoinRequestType? = switch roomDetails.mainRoomInfo.membership {
        case .invited: .invite(inviter: inviterProxy)
        case .knocked: .knock
        default: nil
        }
        
        let previewRoomInfo = roomDetails.previewRoomInfo ?? roomDetails.mainRoomInfo
        return RoomSummary(room: mainRoom, // FIXME: This is horrible and should go away somehow. See notifications settings reloading
                           id: roomDetails.mainRoomInfo.id,
                           joinRequestType: joinRequestType,
                           name: roomDetails.mainRoomInfo.displayName ?? roomDetails.mainRoomInfo.id,
                           isDirect: previewRoomInfo.isDirect,
                           isSpace: roomDetails.mainRoomInfo.isSpace,
                           avatarURL: roomDetails.mainRoomInfo.avatarUrl.flatMap(URL.init(string:)),
                           heroes: previewRoomInfo.heroes.map(UserProfileProxy.init),
                           activeMembersCount: UInt(previewRoomInfo.activeMembersCount),
                           lastMessageRoomId: mainRoom.isSpace() ? previewRoom?.id() : nil,
                           lastMessage: attributedLastMessage,
                           lastMessageDate: lastMessageDate,
                           lastMessageState: lastMessageState,
                           lastMessageRoomAvatarURL: previewRoomInfo.avatarUrl.flatMap(URL.init(string:)),
                           unreadMessagesCount: UInt(previewRoomInfo.numUnreadMessages),
                           unreadMentionsCount: UInt(previewRoomInfo.numUnreadMentions),
                           unreadNotificationsCount: UInt(previewRoomInfo.numUnreadNotifications),
                           notificationMode: notificationMode,
                           canonicalAlias: roomDetails.mainRoomInfo.canonicalAlias,
                           alternativeAliases: .init(roomDetails.mainRoomInfo.alternativeAliases),
                           hasOngoingCall: previewRoomInfo.hasRoomCall,
                           isMarkedUnread: roomDetails.mainRoomInfo.isMarkedUnread,
                           isFavourite: roomDetails.mainRoomInfo.isFavourite,
                           isTombstoned: roomDetails.mainRoomInfo.successorRoom != nil)
    }
    
    private func buildDiff(from diff: GroupedRoomListUpdate, on rooms: [RoomSummary]) -> CollectionDifference<RoomSummary>? {
        var changes = [CollectionDifference<RoomSummary>.Change]()
        
        switch diff {
        case .append(let values):
            for (index, value) in values.enumerated() {
                let summary = buildRoomSummary(roomListItem: value)
                changes.append(.insert(offset: rooms.count + index, element: summary, associatedWith: nil))
            }
        case .clear:
            for (index, value) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: value, associatedWith: nil))
            }
        case .insert(let index, let value):
            let summary = buildRoomSummary(roomListItem: value)
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
            let summary = buildRoomSummary(roomListItem: value)
            changes.append(.insert(offset: rooms.count, element: summary, associatedWith: nil))
        case .pushFront(let value):
            let summary = buildRoomSummary(roomListItem: value)
            changes.append(.insert(offset: 0, element: summary, associatedWith: nil))
        case .remove(let index):
            let summary = rooms[Int(index)]
            changes.append(.remove(offset: Int(index), element: summary, associatedWith: nil))
        case .reset(let values):
            for (index, summary) in rooms.enumerated() {
                changes.append(.remove(offset: index, element: summary, associatedWith: nil))
            }
            
            for (index, value) in values.enumerated() {
                let summary = buildRoomSummary(roomListItem: value)
                changes.append(.insert(offset: index, element: summary, associatedWith: nil))
            }
        case .set(let index, let value):
            let summary = buildRoomSummary(roomListItem: value)
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
    
    // FIXME: Figure out how to make these reload, maybe rust side
    
//    private func setupNotificationSettingsSubscription() {
//        notificationSettings.callbacks
//            .receive(on: serialDispatchQueue)
//            .dropFirst() // drop the first one to avoid rebuilding the summaries during the first synchronization
//            .sink { [weak self] callback in
//                guard let self else { return }
//                switch callback {
//                case .settingsDidChange:
//                    self.rebuildRoomSummaries()
//                }
//            }
//            .store(in: &cancellables)
//    }
//
//    private func rebuildRoomSummaries() {
//        let span = MXLog.createSpan("\(name).rebuild_room_summaries")
//        span.enter()
//        defer {
//            span.exit()
//        }
//
//        MXLog.info("\(name): Rebuilding room summaries for \(rooms.count) rooms")
//
//        rooms = rooms.map {
//            self.buildRoomSummary(from: $0.room)
//        }
//
//        MXLog.info("\(name): Finished rebuilding room summaries (\(rooms.count) rooms)")
//    }
}
