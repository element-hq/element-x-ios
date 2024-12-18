//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import IntentsUI
import MatrixRustSDK
import UIKit

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let liveTimelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let mediaProvider: MediaProviderProtocol
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
    
    private(set) var paginationState: PaginationState = .initial {
        didSet {
            callbacks.send(.paginationState(paginationState))
        }
    }

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
         mediaProvider: MediaProviderProtocol,
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        liveTimelineProvider = timelineProxy.timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
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
            paginationState = PaginationState(backward: .paginating, forward: .paginating)
            
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
                     inReplyToEventID: String?,
                     intentionalMentions: IntentionalMentions) async {
        MXLog.info("Send message in \(roomID)")
        
        switch await activeTimeline.sendMessage(message,
                                                html: html,
                                                inReplyToEventID: inReplyToEventID,
                                                intentionalMentions: intentionalMentions) {
        case .success:
            MXLog.info("Finished sending message")
            await donateSendMessageIntent()
        case .failure(let error):
            MXLog.error("Failed sending message with error: \(error)")
        }
    }
    
    private func donateSendMessageIntent() async {
        guard let displayName = roomProxy.details.name ?? roomProxy.details.canonicalAlias, !displayName.isEmpty else {
            MXLog.error("Failed donating send message intent, room missing name or alias.")
            return
        }
        
        let groupName = INSpeakableString(spokenPhrase: displayName)
        
        let sendMessageIntent = INSendMessageIntent(recipients: nil,
                                                    outgoingMessageType: .outgoingMessageText,
                                                    content: nil,
                                                    speakableGroupName: groupName,
                                                    conversationIdentifier: roomProxy.id,
                                                    serviceName: nil,
                                                    sender: nil,
                                                    attachments: nil)
        
        let avatarURL = switch roomProxy.details.avatar {
        case .room(_, _, let avatarURL):
            avatarURL
        case .heroes(let userProfiles):
            userProfiles.first?.avatarURL
        }
        
        func addPlacehoder() {
            if let imageData = Avatars.generatePlaceholderAvatarImageData(name: displayName, id: roomProxy.id, size: .init(width: 100, height: 100)) {
                sendMessageIntent.setImage(INImage(imageData: imageData), forParameterNamed: \.speakableGroupName)
            }
        }
        
        if let avatarURL, let mediaSource = try? MediaSourceProxy(url: avatarURL, mimeType: nil) {
            if case let .success(avatarData) = await mediaProvider.loadThumbnailForSource(source: mediaSource, size: .init(width: 100, height: 100)) {
                sendMessageIntent.setImage(INImage(imageData: avatarData), forParameterNamed: \.speakableGroupName)
            } else {
                addPlacehoder()
            }
        } else {
            addPlacehoder()
        }
        
        let interaction = INInteraction(intent: sendMessageIntent, response: nil)
        
        do {
            try await interaction.donate()
        } catch {
            MXLog.error("Failed donating send message intent with error: \(error)")
        }
    }
    
    func toggleReaction(_ reaction: String, to eventOrTransactionID: EventOrTransactionId) async {
        MXLog.info("Toggle reaction \(reaction) to \(eventOrTransactionID)")
        
        switch await activeTimeline.toggleReaction(reaction, to: eventOrTransactionID) {
        case .success:
            MXLog.info("Finished toggling reaction")
        case .failure(let error):
            MXLog.error("Failed toggling reaction with error: \(error)")
        }
    }
    
    func edit(_ eventOrTransactionID: EventOrTransactionId,
              message: String,
              html: String?,
              intentionalMentions: IntentionalMentions) async {
        MXLog.info("Edit message in \(roomID)")
        MXLog.info("Editing timeline item: \(eventOrTransactionID)")
        
        let messageContent = activeTimeline.buildMessageContentFor(message,
                                                                   html: html,
                                                                   intentionalMentions: intentionalMentions.toRustMentions())
        
        switch await activeTimeline.edit(eventOrTransactionID, newContent: .roomMessage(content: messageContent)) {
        case .success:
            MXLog.info("Finished editing message by event")
        case let .failure(error):
            MXLog.error("Failed editing message by event with error: \(error)")
        }
    }
    
    func editCaption(_ eventOrTransactionID: EventOrTransactionId,
                     message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async {
        // We're waiting on an API for including mentions: https://github.com/matrix-org/matrix-rust-sdk/issues/4302
        MXLog.info("Editing timeline item caption: \(eventOrTransactionID) in \(roomID)")
        
        // When formattedCaption is nil, caption will be parsed as markdown and generate the HTML for us.
        let newContent = createCaptionEdit(caption: message, formattedCaption: html.map { .init(format: .html, body: $0) })
        switch await activeTimeline.edit(eventOrTransactionID, newContent: newContent) {
        case .success:
            MXLog.info("Finished editing caption")
        case let .failure(error):
            MXLog.error("Failed editing caption with error: \(error)")
        }
    }
    
    func removeCaption(_ eventOrTransactionID: EventOrTransactionId) async {
        // Set a `nil` caption to remove it from the event.
        let newContent = createCaptionEdit(caption: nil, formattedCaption: nil)
        switch await activeTimeline.edit(eventOrTransactionID, newContent: newContent) {
        case .success:
            MXLog.info("Finished removing caption.")
        case let .failure(error):
            MXLog.error("Failed removing caption with error: \(error)")
        }
    }
    
    func redact(_ eventOrTransactionID: EventOrTransactionId) async {
        MXLog.info("Send redaction in \(roomID)")
        
        switch await activeTimeline.redact(eventOrTransactionID, reason: nil) {
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
    
    func sendHandle(for itemID: TimelineItemIdentifier) -> SendHandleProxy? {
        for timelineItemProxy in activeTimelineProvider.itemProxies {
            switch timelineItemProxy {
            case .event(let item):
                if item.id == itemID {
                    return item.sendHandle.map { .init(itemID: itemID, underlyingHandle: $0) }
                }
            default:
                continue
            }
        }
        
        return nil
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
        paginationState = PaginationState(backward: .paginating, forward: .paginating)
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
            if timelineKind != .pinned, !roomProxy.isDirectOneToOneRoom {
                let timelineStart = TimelineStartRoomTimelineItem(name: roomProxy.infoPublisher.value.displayName)
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
        self.paginationState = paginationState
    }
    
    private func buildTimelineItem(for itemProxy: TimelineItemProxy) -> RoomTimelineItemProtocol? {
        switch itemProxy {
        case .event(let eventTimelineItem):
            let timelineItem = timelineItemFactory.buildTimelineItem(for: eventTimelineItem, isDM: roomProxy.isDirectOneToOneRoom)
                        
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
                // Avoid fetching this over and over again as it changes states if it keeps failing to load
                // Errors will be handled again on appearance
                fetchEventDetails(for: messageTimelineItem, refetchOnError: false)
            }
            
            return timelineItem
        case .virtual(let virtualItem, let uniqueID):
            switch virtualItem {
            case .dateDivider(let timestamp):
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
                return SeparatorRoomTimelineItem(id: .virtual(uniqueID: uniqueID), timestamp: date)
            case .readMarker:
                return ReadMarkerRoomTimelineItem(id: .virtual(uniqueID: uniqueID))
            }
        case .unknown:
            return nil
        }
    }
        
    private func isItemCollapsible(_ item: TimelineItemProxy) -> Bool {
        if case let .event(eventItem) = item {
            switch eventItem.content {
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
