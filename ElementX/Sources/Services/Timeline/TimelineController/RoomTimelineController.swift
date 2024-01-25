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
import UIKit

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let roomProxy: RoomProxyProtocol
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let appSettings: AppSettings
    private let secureBackupController: SecureBackupControllerProtocol
    private let serialDispatchQueue: DispatchQueue
    
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()

    var roomID: String {
        roomProxy.id
    }
    
    init(roomProxy: RoomProxyProtocol,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         appSettings: AppSettings,
         secureBackupController: SecureBackupControllerProtocol) {
        self.roomProxy = roomProxy
        timelineProvider = roomProxy.timeline.timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.appSettings = appSettings
        self.secureBackupController = secureBackupController
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider", qos: .utility)
        
        timelineProvider
            .updatePublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.updateTimelineItems()
            }
            .store(in: &cancellables)
        
        serialDispatchQueue.async {
            self.updateTimelineItems()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func paginateBackwards(requestSize: UInt) async -> Result<Void, RoomTimelineControllerError> {
        MXLog.info("Started back pagination request")
        switch await roomProxy.timeline.paginateBackwards(requestSize: requestSize) {
        case .success:
            MXLog.info("Finished back pagination request")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed back pagination request with error: \(error)")
            return .failure(.generic)
        }
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineControllerError> {
        MXLog.info("Started back pagination request")
        switch await roomProxy.timeline.paginateBackwards(requestSize: requestSize, untilNumberOfItems: untilNumberOfItems) {
        case .success:
            MXLog.info("Finished back pagination request")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed back pagination request with error: \(error)")
            return .failure(.generic)
        }
    }
    
    func sendReadReceipt(for itemID: TimelineItemIdentifier) async -> Result<Void, RoomTimelineControllerError> {
        guard roomProxy.hasUnreadNotifications,
              let eventID = itemID.eventID
        else { return .success(()) }
        
        switch await roomProxy.timeline.sendReadReceipt(for: eventID,
                                                        type: appSettings.sendReadReceiptsEnabled ? .read : .readPrivate) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.generic)
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
        
        switch await roomProxy.timeline.sendMessage(message,
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
        guard let eventID = itemID.eventID else {
            MXLog.error("Failed toggling reaction: missing eventID")
            return
        }

        switch await roomProxy.timeline.toggleReaction(reaction, to: eventID) {
        case .success:
            MXLog.info("Finished toggling reaction")
        case .failure(let error):
            MXLog.error("Failed toggling reaction with error: \(error)")
        }
    }
    
    func editMessage(_ newMessage: String,
                     html: String?,
                     original itemID: TimelineItemIdentifier,
                     intentionalMentions: IntentionalMentions) async {
        MXLog.info("Edit message in \(roomID)")
        if let timelineItem = timelineItems.firstUsingStableID(itemID),
           let item = timelineItem as? EventBasedTimelineItemProtocol,
           item.hasFailedToSend {
            MXLog.info("Editing a failed echo, will cancel and resend it as a new message")
            await cancelSending(itemID: itemID)
            await sendMessage(newMessage, html: html, intentionalMentions: intentionalMentions)
        } else if let eventID = itemID.eventID {
            switch await roomProxy.timeline.editMessage(newMessage,
                                                        html: html,
                                                        original: eventID,
                                                        intentionalMentions: intentionalMentions) {
            case .success:
                MXLog.info("Finished editing message")
            case .failure(let error):
                MXLog.error("Failed editing message with error: \(error)")
            }
        } else {
            MXLog.error("Editing failed: missing identifiers")
        }
    }
    
    func redact(_ itemID: TimelineItemIdentifier) async {
        MXLog.info("Send redaction in \(roomID)")
        guard let eventID = itemID.eventID else {
            return
        }
        switch await roomProxy.redact(eventID) {
        case .success:
            MXLog.info("Finished redacting message")
        case .failure(let error):
            MXLog.error("Failed redacting message with error: \(error)")
        }
    }
    
    // Handle this parallel to the timeline items so we're not forced
    // to bundle the Rust side objects within them
    func debugInfo(for itemID: TimelineItemIdentifier) -> TimelineItemDebugInfo {
        for timelineItemProxy in timelineProvider.itemProxies {
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
        await roomProxy.timeline.retryDecryption(for: sessionID)
    }
    
    func retrySending(itemID: TimelineItemIdentifier) async {
        guard let transactionID = itemID.transactionID else {
            MXLog.error("Failed Retry Send: missing transaction ID")
            return
        }
        
        MXLog.info("Retry sending in \(roomID)")
        await roomProxy.timeline.retrySend(transactionID: transactionID)
    }
    
    func cancelSending(itemID: TimelineItemIdentifier) async {
        guard let transactionID = itemID.transactionID else {
            MXLog.error("Failed Cancel Send: missing transaction ID")
            return
        }
        
        MXLog.info("Cancelling send in \(roomID)")
        await roomProxy.timeline.cancelSend(transactionID: transactionID)
    }
    
    // MARK: - Private
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        serialDispatchQueue.async {
            self.updateTimelineItems()
        }
    }
    
    private func updateTimelineItems() {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        var canBackPaginate = !roomProxy.timeline.timelineStartReached
        var isBackPaginating = false
        var lastEncryptedHistoryItemIndex: Int?
        
        let collapsibleChunks = timelineProvider.itemProxies.groupBy { isItemCollapsible($0) }
        
        for (index, collapsibleChunk) in collapsibleChunks.enumerated() {
            let isLastItem = index == collapsibleChunks.indices.last
            
            let items = collapsibleChunk.compactMap { itemProxy in
                
                let timelineItem = buildTimelineItem(for: itemProxy)
                
                if timelineItem is EncryptedHistoryRoomTimelineItem {
                    canBackPaginate = false
                }
                
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
                
                if timelineItem is EncryptedHistoryRoomTimelineItem {
                    lastEncryptedHistoryItemIndex = newTimelineItems.endIndex
                }

                newTimelineItems.append(timelineItem)
            } else {
                newTimelineItems.append(CollapsibleTimelineItem(items: items))
            }
        }
        
        if let lastEncryptedHistoryItemIndex {
            // Remove everything up to the last encrypted history item.
            // It only contains encrypted messages, state changes and date separators.
            newTimelineItems.removeFirst(lastEncryptedHistoryItemIndex)
        } else {
            // Otherwise check if we need to add anything to the top of the timeline.
            switch timelineProvider.backPaginationState {
            case .timelineStartReached:
                if !roomProxy.isEncryptedOneToOneRoom {
                    let timelineStart = TimelineStartRoomTimelineItem(name: roomProxy.displayName ?? roomProxy.name)
                    newTimelineItems.insert(timelineStart, at: 0)
                }
                canBackPaginate = false
            case .paginating:
                newTimelineItems.insert(PaginationIndicatorRoomTimelineItem(), at: 0)
                isBackPaginating = true
            case .idle:
                break
            }
        }
        
        DispatchQueue.main.sync {
            timelineItems = newTimelineItems
        }
        
        callbacks.send(.updatedTimelineItems)
        callbacks.send(.canBackPaginate(canBackPaginate))
        callbacks.send(.isBackPaginating(isBackPaginating))
    }
    
    private func buildTimelineItem(for itemProxy: TimelineItemProxy) -> RoomTimelineItemProtocol? {
        switch itemProxy {
        case .event(let eventTimelineItem):
            let timelineItem = timelineItemFactory.buildTimelineItem(for: eventTimelineItem, isDM: roomProxy.isEncryptedOneToOneRoom)
            
            // When backup is enabled just show the timeline items, they will most likely
            // resolve eventually. If we don't know the backup state then we assume the session is not verified yet,
            // otherwise we just treat it as fully disabled.
            if secureBackupController.keyBackupState.value != .enabled {
                if timelineItem is EncryptedRoomTimelineItem, isItemInEncryptionHistory(eventTimelineItem) {
                    return EncryptedHistoryRoomTimelineItem(id: eventTimelineItem.id,
                                                            isSessionVerified: secureBackupController.keyBackupState.value != .unknown)
                }
            }
            
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
                
                return SeparatorRoomTimelineItem(id: .init(timelineID: timelineID), text: dateString)
            case .readMarker:
                return ReadMarkerRoomTimelineItem(id: .init(timelineID: timelineID))
            }
        case .unknown:
            return nil
        }
    }
    
    /// Whether or not a specific item is part of the room's history that can't be decrypted due
    /// to the lack of key-backup. This is handled differently so we only show a single item.
    private func isItemInEncryptionHistory(_ itemProxy: EventTimelineItemProxy) -> Bool {
        guard roomProxy.isEncrypted, let lastLoginDate = appSettings.lastLoginDate else { return false }
        return itemProxy.timestamp < lastLoginDate
    }
    
    private func isItemCollapsible(_ item: TimelineItemProxy) -> Bool {
        if !appSettings.shouldCollapseRoomStateEvents {
            return false
        }
        
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
            roomProxy.timeline.fetchDetails(for: eventID)
        case .error:
            if refetchOnError {
                roomProxy.timeline.fetchDetails(for: eventID)
            }
        default:
            break
        }
    }
    
    func eventTimestamp(for itemID: TimelineItemIdentifier) -> Date? {
        for itemProxy in roomProxy.timeline.timelineProvider.itemProxies {
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
