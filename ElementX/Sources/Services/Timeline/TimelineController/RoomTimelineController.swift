//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK
import UIKit

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let liveTimelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let appSettings: AppSettings
    private let serialDispatchQueue: DispatchQueue
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private var activeTimeline: TimelineProxyProtocol
    private var activeTimelineProvider: RoomTimelineProviderProtocol {
        didSet {
            configureActiveTimelineProvider()
        }
    }
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()

    var roomID: String {
        roomProxy.id
    }
    
    var timelineKind: TimelineKind {
        liveTimelineProvider.kind
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         timelineProxy: TimelineProxyProtocol,
         initialFocussedEventID: String?,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        liveTimelineProvider = timelineProxy.timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.appSettings = appSettings
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider", qos: .utility)
        
        activeTimeline = timelineProxy
        activeTimelineProvider = liveTimelineProvider
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
        
        guard let initialFocussedEventID else {
            configureActiveTimelineProvider()
            return
        }
        
        Task {
            callbacks.send(.paginationState(PaginationState(backward: .paginating, forward: .paginating)))
            switch await focusOnEvent(initialFocussedEventID, timelineSize: 100) {
            case .success:
                break
            case .failure:
                // Setup the live timeline as a fallback.
                configureActiveTimelineProvider()
            }
        }
    }
    
    func focusOnEvent(_ eventID: String, timelineSize: UInt16) async -> Result<Void, RoomTimelineControllerError> {
        switch await roomProxy.timelineFocusedOnEvent(eventID: eventID, numberOfEvents: timelineSize) {
        case .success(let timeline):
            await timeline.subscribeForUpdates()
            activeTimeline = timeline
            activeTimelineProvider = timeline.timelineProvider
            return .success(())
        case .failure(let error):
            if case .eventNotFound = error {
                return .failure(.eventNotFound)
            } else {
                return .failure(.generic)
            }
        }
    }
    
    func focusLive() {
        activeTimeline = roomProxy.timeline
        activeTimelineProvider = liveTimelineProvider
    }
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, RoomTimelineControllerError> {
        MXLog.info("Started back pagination request")
        switch await activeTimeline.paginateBackwards(requestSize: requestSize) {
        case .success:
            MXLog.info("Finished back pagination request")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed back pagination request with error: \(error)")
            return .failure(.generic)
        }
    }
    
    func paginateForwards(requestSize: UInt16) async -> Result<Void, RoomTimelineControllerError> {
        MXLog.info("Started forward pagination request")
        switch await activeTimeline.paginateForwards(requestSize: requestSize) {
        case .success:
            MXLog.info("Finished forward pagination request")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed forward pagination request with error: \(error)")
            return .failure(.generic)
        }
    }
    
    func sendReadReceipt(for itemID: TimelineItemIdentifier) async {
        let receiptType: MatrixRustSDK.ReceiptType = appSettings.sharePresence ? .read : .readPrivate
        
        // Mark the whole room as read if it's the last timeline item
        if timelineItems.last?.id == itemID {
            _ = await roomProxy.markAsRead(receiptType: receiptType)
        } else {
            guard let eventID = itemID.eventID else {
                return
            }
            
            _ = await activeTimeline.sendReadReceipt(for: eventID, type: receiptType)
        }
    }
    
    func processItemAppearance(_ itemID: TimelineItemIdentifier) async {
        guard let timelineItem = timelineItems.firstUsingStableID(itemID) else {
            return
        }
        
        if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
            fetchEventDetails(for: messageTimelineItem, refetchOnError: true)
        }
    }
    
    func processItemDisappearance(_ itemID: TimelineItemIdentifier) { }
    
    func sendMessage(_ message: String,
                     html: String?,
                     inReplyTo itemID: TimelineItemIdentifier?,
                     intentionalMentions: IntentionalMentions) async {
        var inReplyTo: String?
        if itemID == nil {
            MXLog.info("Send message in \(roomID)")
        } else if let eventID = itemID?.eventID {
            inReplyTo = eventID
            MXLog.info("Send reply in \(roomID)")
        } else {
            MXLog.error("Send reply in \(roomID) failed: missing event ID")
            return
        }
        
        switch await activeTimeline.sendMessage(message,
                                                html: html,
                                                inReplyTo: inReplyTo,
                                                intentionalMentions: intentionalMentions) {
        case .success:
            MXLog.info("Finished sending message")
        case .failure(let error):
            MXLog.error("Failed sending message with error: \(error)")
        }
    }
    
    func toggleReaction(_ reaction: String, to itemID: TimelineItemIdentifier) async {
        MXLog.info("Toggle reaction in \(roomID)")
        
        switch await activeTimeline.toggleReaction(reaction, to: itemID) {
        case .success:
            MXLog.info("Finished toggling reaction")
        case .failure(let error):
            MXLog.error("Failed toggling reaction with error: \(error)")
        }
    }
    
    func edit(_ timelineItemID: TimelineItemIdentifier,
              message: String,
              html: String?,
              intentionalMentions: IntentionalMentions) async {
        MXLog.info("Edit message in \(roomID)")
        MXLog.info("Editing timeline item: \(timelineItemID)")
        
        let editMode: EditMode
        if !timelineItemID.timelineID.isEmpty,
           let timelineItem = liveTimelineProvider.itemProxies.firstEventTimelineItemUsingStableID(timelineItemID) {
            editMode = .byEvent(timelineItem)
        } else if let eventID = timelineItemID.eventID {
            editMode = .byID(eventID)
        } else {
            MXLog.error("Unknown timeline item: \(timelineItemID)")
            return
        }
        
        let messageContent = activeTimeline.buildMessageContentFor(message,
                                                                   html: html,
                                                                   intentionalMentions: intentionalMentions.toRustMentions())
        
        switch editMode {
        case let .byEvent(item):
            switch await activeTimeline.edit(item, newContent: messageContent) {
            case .success:
                MXLog.info("Finished editing message by event")
            case let .failure(error):
                MXLog.error("Failed editing message by event with error: \(error)")
            }
        case let .byID(eventID):
            switch await roomProxy.edit(eventID: eventID, newContent: messageContent) {
            case .success:
                MXLog.info("Finished editing message by event ID")
            case let .failure(error):
                MXLog.error("Failed editing message by event ID with error: \(error)")
            }
        }
    }
    
    func redact(_ timelineItemID: TimelineItemIdentifier) async {
        MXLog.info("Send redaction in \(roomID)")
        
        switch await activeTimeline.redact(timelineItemID, reason: nil) {
        case .success:
            MXLog.info("Finished redacting message")
        case .failure(let error):
            MXLog.error("Failed redacting message with error: \(error)")
        }
    }
    
    func pin(eventID: String) async {
        MXLog.info("Pinning event \(eventID) in \(roomID)")
        
        switch await activeTimeline.pin(eventID: eventID) {
        case .success(let value):
            if value {
                MXLog.info("Finished pinning event \(eventID)")
            } else {
                MXLog.error("Failed pinning event \(eventID) because is already pinned")
            }
        case .failure(let error):
            MXLog.error("Failed pinning event \(eventID) with error: \(error)")
        }
    }
    
    func unpin(eventID: String) async {
        MXLog.info("Unpinning event \(eventID) in \(roomID)")
        
        switch await activeTimeline.unpin(eventID: eventID) {
        case .success(let value):
            if value {
                MXLog.info("Finished unpinning event \(eventID)")
            } else {
                MXLog.error("Failed unpinning event \(eventID) because is not pinned")
            }
        case .failure(let error):
            MXLog.error("Failed unpinning event \(eventID) with error: \(error)")
        }
    }
    
    func messageEventContent(for timelineItemID: TimelineItemIdentifier) async -> RoomMessageEventContentWithoutRelation? {
        await activeTimeline.messageEventContent(for: timelineItemID)
    }
    
    // Handle this parallel to the timeline items so we're not forced
    // to bundle the Rust side objects within them
    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo {
        for timelineItemProxy in activeTimelineProvider.itemProxies {
            switch timelineItemProxy {
            case .event(let item):
                if item.id == itemID {
                    return item.debugInfo
                }
            default:
                continue
            }
        }
        
        return .init(model: "Unknown item", originalJSON: nil, latestEditJSON: nil)
    }
    
    func retryDecryption(for sessionID: String) async {
        await activeTimeline.retryDecryption(for: sessionID)
    }
    
    // MARK: - Private
    
    /// The cancellable used to update the timeline items.
    private var updateTimelineItemsCancellable: AnyCancellable?
    /// The controller is switching the `activeTimelineProvider`.
    private var isSwitchingTimelines = false
    
    /// Configures the controller to listen to `activeTimeline` for events.
    /// - Parameter clearExistingItems: Whether or not to clear any existing items before loading the timeline's contents.
    private func configureActiveTimelineProvider() {
        updateTimelineItemsCancellable = nil
        
        isSwitchingTimelines = true
        
        // Inform the world that the initial items are loading from the store
        callbacks.send(.paginationState(.init(backward: .paginating, forward: .paginating)))
        callbacks.send(.isLive(activeTimelineProvider.kind == .live))
        
        updateTimelineItemsCancellable = activeTimelineProvider
            .updatePublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] items, paginationState in
                self?.updateTimelineItems(itemProxies: items, paginationState: paginationState)
            }
    }
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        serialDispatchQueue.async { [activeTimelineProvider] in
            self.updateTimelineItems(itemProxies: activeTimelineProvider.itemProxies, paginationState: activeTimelineProvider.paginationState)
        }
    }
    
    private func updateTimelineItems(itemProxies: [TimelineItemProxy], paginationState: PaginationState) {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        
        let isNewTimeline = isSwitchingTimelines
        isSwitchingTimelines = false
        
        let collapsibleChunks = itemProxies.groupBy { isItemCollapsible($0) }
        
        for (index, collapsibleChunk) in collapsibleChunks.enumerated() {
            let isLastItem = index == collapsibleChunks.indices.last
            
            let items = collapsibleChunk.compactMap { itemProxy in
                
                let timelineItem = buildTimelineItem(for: itemProxy)
                
                return timelineItem
            }
            
            if items.isEmpty {
                continue
            }
            
            if items.count == 1, let timelineItem = items.first {
                // Don't show the read marker if it's the last item in the timeline
                // https://github.com/matrix-org/matrix-rust-sdk/issues/1546
                guard !(timelineItem is ReadMarkerRoomTimelineItem && isLastItem) else {
                    continue
                }
                
                newTimelineItems.append(timelineItem)
            } else {
                newTimelineItems.append(CollapsibleTimelineItem(items: items))
            }
        }
        
        // Check if we need to add anything to the top of the timeline.
        switch paginationState.backward {
        case .timelineEndReached:
            if timelineKind != .pinned, !roomProxy.isEncryptedOneToOneRoom {
                let timelineStart = TimelineStartRoomTimelineItem(name: roomProxy.name)
                newTimelineItems.insert(timelineStart, at: 0)
            }
        case .paginating:
            newTimelineItems.insert(PaginationIndicatorRoomTimelineItem(position: .start), at: 0)
        case .idle:
            break
        }
        
        switch paginationState.forward {
        case .paginating:
            newTimelineItems.insert(PaginationIndicatorRoomTimelineItem(position: .end), at: newTimelineItems.count)
        case .idle, .timelineEndReached:
            break
        }
        
        DispatchQueue.main.sync {
            timelineItems = newTimelineItems
        }
        
        callbacks.send(.updatedTimelineItems(timelineItems: newTimelineItems, isSwitchingTimelines: isNewTimeline))
        callbacks.send(.paginationState(paginationState))
    }
    
    private func buildTimelineItem(for itemProxy: TimelineItemProxy) -> RoomTimelineItemProtocol? {
        switch itemProxy {
        case .event(let eventTimelineItem):
            let timelineItem = timelineItemFactory.buildTimelineItem(for: eventTimelineItem, isDM: roomProxy.isEncryptedOneToOneRoom)
                        
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
                // Avoid fetching this over and over again as it changes states if it keeps failing to load
                // Errors will be handled again on appearance
                fetchEventDetails(for: messageTimelineItem, refetchOnError: false)
            }
            
            return timelineItem
        case .virtual(let virtualItem, let timelineID):
            switch virtualItem {
            case .dayDivider(let timestamp):
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
                let dateString = date.formatted(date: .complete, time: .omitted)
                
                return SeparatorRoomTimelineItem(id: .init(timelineID: dateString), text: dateString)
            case .readMarker:
                return ReadMarkerRoomTimelineItem(id: .init(timelineID: timelineID))
            }
        case .unknown:
            return nil
        }
    }
        
    private func isItemCollapsible(_ item: TimelineItemProxy) -> Bool {
        if case let .event(eventItem) = item {
            switch eventItem.content.kind() {
            case .profileChange, .roomMembership, .state:
                return true
            default:
                return false
            }
        }
        
        return false
    }
    
    private func fetchEventDetails(for timelineItem: EventBasedMessageTimelineItemProtocol, refetchOnError: Bool) {
        guard let eventID = timelineItem.id.eventID else {
            return
        }

        switch timelineItem.replyDetails {
        case .notLoaded:
            activeTimeline.fetchDetails(for: eventID)
        case .error:
            if refetchOnError {
                activeTimeline.fetchDetails(for: eventID)
            }
        default:
            break
        }
    }
    
    func eventTimestamp(for itemID: TimelineItemIdentifier) -> Date? {
        for itemProxy in activeTimelineProvider.itemProxies {
            switch itemProxy {
            case .event(let eventTimelineItemProxy):
                if eventTimelineItemProxy.id == itemID {
                    return eventTimelineItemProxy.timestamp
                }
            case .virtual:
                break
            case .unknown:
                break
            }
        }
        return nil
    }
}

private enum EditMode {
    case byEvent(EventTimelineItem)
    case byID(String)
}
