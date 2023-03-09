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
import UniformTypeIdentifiers

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let userId: String
    private let roomProxy: RoomProxyProtocol
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let mediaProvider: MediaProviderProtocol
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
         timelineProvider: RoomTimelineProviderProtocol,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.userId = userId
        self.timelineProvider = timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
        self.roomProxy = roomProxy
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider", qos: .utility)
        
        self.timelineProvider
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
    
    func processItemAppearance(_ itemID: String) async { }
    
    func processItemDisappearance(_ itemID: String) { }

    func processItemTap(_ itemID: String) async -> RoomTimelineControllerAction {
        guard let timelineItem = timelineItems.first(where: { $0.id == itemID }) else {
            return .none
        }
        
        var source: MediaSourceProxy?
        var type: UTType?
        var title: String
        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            source = item.source
            type = item.type
            title = item.body
        case let item as VideoRoomTimelineItem:
            source = item.source
            type = item.type
            title = item.body
        case let item as FileRoomTimelineItem:
            source = item.source
            type = item.type
            title = item.body
        case let item as AudioRoomTimelineItem:
            // For now we are just displaying audio messages with the File preview until we create a timeline player for them.
            source = item.source
            type = item.type
            title = item.body
        default:
            return .none
        }
        
        #warning("Try a type fallback base on the title?")
        guard let source, let type else { return .none }
        switch await mediaProvider.loadFileFromSource(source, type: type) {
        case .success(let file):
            return .displayMediaFile(file: file, title: title)
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
    
    func sendReaction(_ reaction: String, to itemID: String) async {
        MXLog.info("Send reaction in \(roomID)")
        switch await roomProxy.sendReaction(reaction, to: itemID) {
        case .success:
            MXLog.info("Finished sending reaction")
        case .failure(let error):
            MXLog.error("Failed sending reaction with error: \(error)")
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
    
    // Handle this parallel to the timeline items so we're not forced
    // to bundle the Rust side objects within them
    func debugDescription(for itemID: String) -> String {
        var description = "Unknown item"
        timelineProvider.itemsPublisher.value.forEach { timelineItemProxy in
            switch timelineItemProxy {
            case .event(let item):
                if item.id == itemID {
                    description = item.debugDescription
                    return
                }
            default:
                break
            }
        }
        
        return description
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
            
            let items = collapsibleChunk.compactMap { itemProxy in
                let timelineItem = buildTimelineItemFor(itemProxy: itemProxy)
                
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
    
    private func buildTimelineItemFor(itemProxy: TimelineItemProxy) -> RoomTimelineItemProtocol? {
        switch itemProxy {
        case .event(let eventItemProxy):
            return timelineItemFactory.buildTimelineItemFor(eventItemProxy: eventItemProxy)
        case .virtual(let virtualItem):
            switch virtualItem {
            case .dayDivider(let timestamp):
                // These components will be replaced by a timestamp in upcoming releases
                let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
                let dateString = date.formatted(date: .complete, time: .omitted)
                return SeparatorRoomTimelineItem(text: dateString)
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
        if !ServiceLocator.shared.settings.shouldCollapseRoomStateEvents {
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
    
    #warning("Move me to Rust, or replace me?")
    /// Temporary method that generates a file extension for a video file name
    /// using `UTType.movie` and falls back to .mp4 if anything goes wrong.
    ///
    /// Ideally Rust should be able to handle this for us, otherwise we should be
    /// attempting to detect the file type from the data itself.
    private func movieFileExtension(for text: String) -> String {
        let fallbackExtension = "mp4"
        
        // This is not great. We could better estimate file extension from the mimetype.
        guard let fileExtensionComponent = text.split(separator: ".").last else { return fallbackExtension }
        let fileExtension = String(fileExtensionComponent)
        
        // We can't trust that the extension provided is an extension that AVFoundation will accept.
        guard let fileType = UTType(filenameExtension: fileExtension),
              fileType.isSubtype(of: .movie)
        else { return fallbackExtension }
        
        return fileExtension
    }
}
