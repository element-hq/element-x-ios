//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import IntentsUI
import MatrixRustSDK
import UIKit

class TimelineController: TimelineControllerProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let liveTimelineItemProvider: TimelineItemProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let mediaProvider: MediaProviderProtocol
    private let appSettings: AppSettings
    
    let callbacks = PassthroughSubject<TimelineControllerCallback, Never>()
    
    private var activeTimeline: TimelineProxyProtocol
    private var activeTimelineItemProvider: TimelineItemProviderProtocol {
        didSet {
            configureActiveTimelineItemProvider()
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
        activeTimelineItemProvider.kind
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         timelineProxy: TimelineProxyProtocol,
         initialFocussedEventID: String?,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         mediaProvider: MediaProviderProtocol,
         appSettings: AppSettings) {
        self.roomProxy = roomProxy
        liveTimelineItemProvider = timelineProxy.timelineItemProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
        self.appSettings = appSettings
        
        activeTimeline = timelineProxy
        activeTimelineItemProvider = liveTimelineItemProvider
        
        guard let initialFocussedEventID else {
            configureActiveTimelineItemProvider()
            return
        }
        
        Task {
            paginationState = PaginationState(backward: .paginating, forward: .paginating)
            
            switch await focusOnEvent(initialFocussedEventID, timelineSize: 100) {
            case .success:
                break
            case .failure:
                // Setup the live timeline as a fallback.
                configureActiveTimelineItemProvider()
            }
        }
    }
    
    func focusOnEvent(_ eventID: String, timelineSize: UInt16) async -> Result<Void, TimelineControllerError> {
        switch await roomProxy.timelineFocusedOnEvent(eventID: eventID, numberOfEvents: timelineSize) {
        case .success(let timeline):
            await timeline.subscribeForUpdates()
            activeTimeline = timeline
            activeTimelineItemProvider = timeline.timelineItemProvider
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
        activeTimelineItemProvider = liveTimelineItemProvider
    }
    
    func paginateBackwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
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
    
    func paginateForwards(requestSize: UInt16) async -> Result<Void, TimelineControllerError> {
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
            fetchEventDetails(for: messageTimelineItem,
                              refetchOnError: true,
                              activeTimeline: activeTimeline)
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
                                                threadRootEventID: timelineKind.threadRootEventID,
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
        
        let avatarURL: URL? = switch roomProxy.details.avatar {
        case .room(_, _, let avatarURL):
            avatarURL
        case .heroes(let userProfiles):
            userProfiles.first?.avatarURL
        case .tombstoned:
            nil
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
    
    func toggleReaction(_ reaction: String, to eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
        MXLog.info("Toggle reaction \(reaction) to \(eventOrTransactionID)")
        
        switch await activeTimeline.toggleReaction(reaction, to: eventOrTransactionID) {
        case .success:
            MXLog.info("Finished toggling reaction")
        case .failure(let error):
            MXLog.error("Failed toggling reaction with error: \(error)")
        }
    }
    
    func edit(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
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
    
    func editCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID,
                     message: String,
                     html: String?,
                     intentionalMentions: IntentionalMentions) async {
        MXLog.info("Editing timeline item caption: \(eventOrTransactionID) in \(roomID)")
        
        // When formattedCaption is nil, caption will be parsed as markdown and generate the HTML for us.
        let newContent = createCaptionEdit(caption: message,
                                           formattedCaption: html.map { .init(format: .html, body: $0) },
                                           mentions: intentionalMentions.toRustMentions())
        switch await activeTimeline.edit(eventOrTransactionID, newContent: newContent) {
        case .success:
            MXLog.info("Finished editing caption")
        case let .failure(error):
            MXLog.error("Failed editing caption with error: \(error)")
        }
    }
    
    func removeCaption(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
        // Set a `nil` caption to remove it from the event.
        let newContent = createCaptionEdit(caption: nil, formattedCaption: nil, mentions: nil)
        switch await activeTimeline.edit(eventOrTransactionID, newContent: newContent) {
        case .success:
            MXLog.info("Finished removing caption.")
        case let .failure(error):
            MXLog.error("Failed removing caption with error: \(error)")
        }
    }
    
    func redact(_ eventOrTransactionID: TimelineItemIdentifier.EventOrTransactionID) async {
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
        for timelineItemProxy in activeTimelineItemProvider.itemProxies {
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
        for timelineItemProxy in activeTimelineItemProvider.itemProxies {
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
    /// The controller is switching the `activeTimelineItemProvider`.
    private var isSwitchingTimelines = false
    
    /// Configures the controller to listen to `activeTimeline` for events.
    /// - Parameter clearExistingItems: Whether or not to clear any existing items before loading the timeline's contents.
    private func configureActiveTimelineItemProvider() {
        updateTimelineItemsCancellable = nil
        
        isSwitchingTimelines = true
        
        // Inform the world that the initial items are loading from the store
        paginationState = PaginationState(backward: .paginating, forward: .paginating)
        callbacks.send(.isLive(activeTimelineItemProvider.kind == .live))
        
        updateTimelineItemsCancellable = Task { [weak self, activeTimelineItemProvider] in
            let contentSizeChangePublisher = NotificationCenter.default.publisher(for: UIContentSizeCategory.didChangeNotification)
            let timelineUpdates = activeTimelineItemProvider.updatePublisher.merge(with: contentSizeChangePublisher.map { _ in
                (activeTimelineItemProvider.itemProxies, activeTimelineItemProvider.paginationState)
            })
            
            for await (items, paginationState) in timelineUpdates.values {
                await self?.updateTimelineItems(itemProxies: items, paginationState: paginationState)
            }
        }.asCancellable()
    }
    
    private func updateTimelineItems(itemProxies: [TimelineItemProxy], paginationState: PaginationState) async {
        let isNewTimeline = isSwitchingTimelines
        isSwitchingTimelines = false
        
        let isDM = roomProxy.isDirectOneToOneRoom
        let displayName = roomProxy.infoPublisher.value.displayName
        let hasPredecessor = roomProxy.predecessorRoom != nil
        
        var newTimelineItems = await Task.detached { [timelineItemFactory, activeTimeline] in
            var newTimelineItems = [RoomTimelineItemProtocol]()
            
            let collapsibleChunks = itemProxies.groupBy { $0.isItemCollapsible }
            
            for (index, collapsibleChunk) in collapsibleChunks.enumerated() {
                let isLastItem = index == collapsibleChunks.indices.last
                
                let items = collapsibleChunk.compactMap { itemProxy in
                    let timelineItem = self.buildTimelineItem(for: itemProxy,
                                                              isDM: isDM,
                                                              hasPredecessor: hasPredecessor,
                                                              roomDisplayName: displayName,
                                                              timelineItemFactory: timelineItemFactory,
                                                              activeTimeline: activeTimeline)
                    
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
            
            return newTimelineItems
        }.value
        
        // Check if we need to add anything to the top of the timeline.
        switch paginationState.backward {
        case .paginating:
            newTimelineItems.insert(PaginationIndicatorRoomTimelineItem(position: .start), at: 0)
        case .idle, .timelineEndReached:
            break
        }
        
        switch paginationState.forward {
        case .paginating:
            newTimelineItems.insert(PaginationIndicatorRoomTimelineItem(position: .end), at: newTimelineItems.count)
        case .idle, .timelineEndReached:
            break
        }
        
        timelineItems = newTimelineItems
        
        callbacks.send(.updatedTimelineItems(timelineItems: newTimelineItems, isSwitchingTimelines: isNewTimeline))
        self.paginationState = paginationState
    }
    
    private nonisolated func buildTimelineItem(for itemProxy: TimelineItemProxy,
                                               isDM: Bool,
                                               hasPredecessor: Bool,
                                               roomDisplayName: String?,
                                               timelineItemFactory: RoomTimelineItemFactoryProtocol,
                                               activeTimeline: TimelineProxyProtocol) -> RoomTimelineItemProtocol? {
        switch itemProxy {
        case .event(let eventTimelineItem):
            let timelineItem = timelineItemFactory.buildTimelineItem(for: eventTimelineItem, isDM: isDM)
            
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
                // Avoid fetching this over and over again as it changes states if it keeps failing to load
                // Errors will be handled again on appearance
                fetchEventDetails(for: messageTimelineItem,
                                  refetchOnError: false,
                                  activeTimeline: activeTimeline)
            }
            
            return timelineItem
        case .virtual(let virtualItem, let uniqueID):
            switch virtualItem {
            case .dateDivider(let timestamp):
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
                return SeparatorRoomTimelineItem(id: .virtual(uniqueID: uniqueID), timestamp: date)
            case .readMarker:
                return ReadMarkerRoomTimelineItem(id: .virtual(uniqueID: uniqueID))
            case .timelineStart:
                // We always display the timeline start item, if there is a predecessor room.
                guard !hasPredecessor else {
                    return TimelineStartRoomTimelineItem(name: roomDisplayName)
                }
                // If not we only display the timeline start item if this is not a DM.
                return isDM ? nil : TimelineStartRoomTimelineItem(name: roomDisplayName)
            }
        case .unknown:
            return nil
        }
    }
    
    private nonisolated func fetchEventDetails(for timelineItem: EventBasedMessageTimelineItemProtocol,
                                               refetchOnError: Bool,
                                               activeTimeline: TimelineProxyProtocol) {
        guard let eventID = timelineItem.id.eventID else {
            return
        }

        switch timelineItem.properties.replyDetails {
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
        for itemProxy in activeTimelineItemProvider.itemProxies {
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

private extension TimelineItemProxy {
    var isItemCollapsible: Bool {
        if case let .event(eventItem) = self {
            switch eventItem.content {
            case .profileChange, .roomMembership, .state:
                return true
            default:
                return false
            }
        }
        
        return false
    }
}
