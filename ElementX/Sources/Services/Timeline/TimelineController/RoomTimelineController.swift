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
    private let userId: String
    private let roomProxy: RoomProxyProtocol
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let mediaProvider: MediaProviderProtocol
    private let appSettings: AppSettings
    private let serialDispatchQueue: DispatchQueue
    
    private var cancellables = Set<AnyCancellable>()
    private var timelineItemsUpdateTask: Task<Void, Never>? {
        willSet {
            timelineItemsUpdateTask?.cancel()
        }
    }
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()
    
    var roomID: String {
        roomProxy.id
    }
    
    init(userId: String,
         roomProxy: RoomProxyProtocol,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         mediaProvider: MediaProviderProtocol,
         appSettings: AppSettings) {
        self.userId = userId
        self.roomProxy = roomProxy
        timelineProvider = roomProxy.timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
        self.appSettings = appSettings
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider", qos: .utility)
        
        timelineProvider
            .itemsPublisher
            .receive(on: serialDispatchQueue)
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.updateTimelineItems()
            }
            .store(in: &cancellables)
        
        updateTimelineItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineControllerError> {
        MXLog.info("Started back pagination request")
        switch await roomProxy.paginateBackwards(requestSize: requestSize, untilNumberOfItems: untilNumberOfItems) {
        case .success:
            MXLog.info("Finished back pagination request")
            return .success(())
        case .failure(.noMoreMessagesToBackPaginate):
            MXLog.warning("Back pagination requested when all messages have been loaded.")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed back pagination request with error: \(error)")
            return .failure(.generic)
        }
    }
    
    func markRoomAsRead() async -> Result<Void, RoomTimelineControllerError> {
        guard roomProxy.hasUnreadNotifications,
              let eventID = timelineItems.last?.id
        else { return .success(()) }
        
        switch await roomProxy.sendReadReceipt(for: eventID) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.generic)
        }
    }
    
    func processItemAppearance(_ itemID: String) async {
        guard let timelineItem = timelineItems.first(where: { $0.id == itemID }) else {
            return
        }
        
        if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
            fetchEventDetails(for: messageTimelineItem, refetchOnError: true)
        }
    }
    
    func processItemDisappearance(_ itemID: String) { }

    func processItemTap(_ itemID: String) async -> RoomTimelineControllerAction {
        guard let timelineItem = timelineItems.first(where: { $0.id == itemID }) else {
            return .none
        }
        
        var source: MediaSourceProxy?
        var body: String
        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            source = item.content.source
            body = item.content.body
        case let item as VideoRoomTimelineItem:
            source = item.content.source
            body = item.content.body
        case let item as FileRoomTimelineItem:
            source = item.content.source
            body = item.content.body
        case let item as AudioRoomTimelineItem:
            // For now we are just displaying audio messages with the File preview until we create a timeline player for them.
            source = item.content.source
            body = item.content.body
        default:
            return .none
        }
        
        guard let source else { return .none }
        switch await mediaProvider.loadFileFromSource(source, body: body) {
        case .success(let file):
            return .displayMediaFile(file: file, title: body)
        case .failure:
            return .none
        }
    }
    
    func sendMessage(_ message: String, inReplyTo itemID: String?) async {
        if itemID == nil {
            MXLog.info("Send message in \(roomID)")
        } else {
            MXLog.info("Send reply in \(roomID)")
        }
        
        switch await roomProxy.sendMessage(message, inReplyTo: itemID) {
        case .success:
            MXLog.info("Finished sending message")
        case .failure(let error):
            MXLog.error("Failed sending message with error: \(error)")
        }
    }
    
    func toggleReaction(_ reaction: String, to itemID: String) async {
        MXLog.info("Toggle reaction in \(roomID)")
        switch await roomProxy.toggleReaction(reaction, to: itemID) {
        case .success:
            MXLog.info("Finished toggling reaction")
        case .failure(let error):
            MXLog.error("Failed toggling reaction with error: \(error)")
        }
    }
    
    func editMessage(_ newMessage: String, original itemID: String) async {
        MXLog.info("Edit message in \(roomID)")
        switch await roomProxy.editMessage(newMessage, original: itemID) {
        case .success:
            MXLog.info("Finished editing message")
        case .failure(let error):
            MXLog.error("Failed editing message with error: \(error)")
        }
    }
    
    func redact(_ itemID: String) async {
        MXLog.info("Send redaction in \(roomID)")
        switch await roomProxy.redact(itemID) {
        case .success:
            MXLog.info("Finished redacting message")
        case .failure(let error):
            MXLog.error("Failed redacting message with error: \(error)")
        }
    }

    func cancelSend(_ transactionID: String) async {
        MXLog.info("Cancelling send in \(roomID)")
        await roomProxy.cancelSend(transactionID: transactionID)
    }
    
    // Handle this parallel to the timeline items so we're not forced
    // to bundle the Rust side objects within them
    func debugInfo(for itemID: String) -> TimelineItemDebugInfo {
        for timelineItemProxy in timelineProvider.itemsPublisher.value {
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
        await roomProxy.retryDecryption(for: sessionID)
    }

    // MARK: - Private
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        updateTimelineItems()
    }
    
    private func updateTimelineItems() {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        var canBackPaginate = true
        var isBackPaginating = false
        
        let collapsibleChunks = timelineProvider.itemsPublisher.value.groupBy { isItemCollapsible($0) }
        
        for (index, collapsibleChunk) in collapsibleChunks.enumerated() {
            let isLastItem = index == collapsibleChunks.indices.last
            
            // Try building a stable identifier for items that don't have one
            // We need to avoid duplicates otherwise the diffable datasource will crash
            let reversedIndex = collapsibleChunks.count - index
            
            let items = collapsibleChunk.compactMap { itemProxy in
                
                let timelineItem = buildTimelineItem(for: itemProxy, chunkIndex: reversedIndex)
                
                if timelineItem is PaginationIndicatorRoomTimelineItem {
                    isBackPaginating = true
                } else if timelineItem is TimelineStartRoomTimelineItem {
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
                
                newTimelineItems.append(timelineItem)
            } else {
                newTimelineItems.append(CollapsibleTimelineItem(items: items))
            }
        }

        timelineItems = newTimelineItems
        
        callbacks.send(.updatedTimelineItems)
        callbacks.send(.canBackPaginate(canBackPaginate))
        callbacks.send(.isBackPaginating(isBackPaginating))
    }
    
    private func buildTimelineItem(for itemProxy: TimelineItemProxy, chunkIndex: Int) -> RoomTimelineItemProtocol? {
        switch itemProxy {
        case .event(let eventTimelineItem):
            let timelineItem = timelineItemFactory.buildTimelineItem(for: eventTimelineItem)
            
            if let messageTimelineItem = timelineItem as? EventBasedMessageTimelineItemProtocol {
                // Avoid fetching this over and over again as it changes states if it keeps failing to load
                // Errors will be handled again on appearance
                fetchEventDetails(for: messageTimelineItem, refetchOnError: false)
            }
            
            return timelineItem
        case .virtual(let virtualItem):
            switch virtualItem {
            case .dayDivider(let timestamp):
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
                let dateString = date.formatted(date: .complete, time: .omitted)
                
                // Separators without stable identifiers cause UI glitches
                let identifier = "\(chunkIndex)-\(dateString)"
                return SeparatorRoomTimelineItem(id: identifier, text: dateString)
            case .readMarker:
                return ReadMarkerRoomTimelineItem()
            case .loadingIndicator:
                return PaginationIndicatorRoomTimelineItem()
            case .timelineStart:
                return TimelineStartRoomTimelineItem(name: roomProxy.displayName ?? roomProxy.name)
            }
        case .unknown:
            return nil
        }
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
        switch timelineItem.replyDetails {
        case .notLoaded:
            roomProxy.fetchDetails(for: timelineItem.id)
        case .error:
            if refetchOnError {
                roomProxy.fetchDetails(for: timelineItem.id)
            }
        default:
            break
        }
    }
}
