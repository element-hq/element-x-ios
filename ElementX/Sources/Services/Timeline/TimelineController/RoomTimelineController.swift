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

        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            await loadFileForImageTimelineItem(item)
            guard let index = timelineItems.firstIndex(where: { $0.id == itemID }),
                  let item = timelineItems[index] as? ImageRoomTimelineItem,
                  let fileURL = item.cachedFileURL else {
                return .none
            }
            return .displayFile(fileURL: fileURL, title: item.body)
        case let item as VideoRoomTimelineItem:
            await loadVideoForTimelineItem(item)
            guard let index = timelineItems.firstIndex(where: { $0.id == itemID }),
                  let item = timelineItems[index] as? VideoRoomTimelineItem,
                  let videoURL = item.cachedVideoURL else {
                return .none
            }
            return .displayVideo(videoURL: videoURL, title: item.body)
        case let item as FileRoomTimelineItem:
            await loadFileForTimelineItem(item)
            guard let index = timelineItems.firstIndex(where: { $0.id == itemID }),
                  let item = timelineItems[index] as? FileRoomTimelineItem,
                  let fileURL = item.cachedFileURL else {
                return .none
            }
            return .displayFile(fileURL: fileURL, title: item.body)
        case let item as AudioRoomTimelineItem:
            await loadAudioForTimelineItem(item)
            guard let index = timelineItems.firstIndex(where: { $0.id == itemID }),
                  let item = timelineItems[index] as? AudioRoomTimelineItem,
                  let audioURL = item.cachedAudioURL else {
                return .none
            }
            // For now we are just displaying audio messages with the File preview until we create a timeline player for them.
            return .displayFile(fileURL: audioURL, title: item.body)
        default:
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

    func reportContent(_ itemID: String, reason: String?) async {
        MXLog.info("Send report content in \(roomID)")
        switch await roomProxy.reportContent(itemID, reason: reason) {
        case .success:
            MXLog.info("Finished reporting content")
        case .failure(let error):
            MXLog.error("Failed reporting content with error: \(error)")
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
    
    // swiftlint:disable:next cyclomatic_complexity
    private func updateTimelineItems() {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        var canBackPaginate = true
        var isBackPaginating = false
        
        var createdIdentifiers = [String: Bool]()

        for (index, itemProxy) in timelineProvider.itemsPublisher.value.enumerated() {
            if Task.isCancelled {
                return
            }

            let previousItemProxy = timelineProvider.itemsPublisher.value[safe: index - 1]
            let nextItemProxy = timelineProvider.itemsPublisher.value[safe: index + 1]

            let groupState = computeGroupState(for: itemProxy, previousItemProxy: previousItemProxy, nextItemProxy: nextItemProxy)
            
            switch itemProxy {
            case .event(let eventItemProxy):
                if let timelineItem = timelineItemFactory.buildTimelineItemFor(eventItemProxy: eventItemProxy, groupState: groupState) {
                    #warning("This works around duplicated items coming out of the SDK, remove once fixed")
                    if createdIdentifiers[timelineItem.id] == nil {
                        newTimelineItems.append(timelineItem)
                        createdIdentifiers[timelineItem.id] = true
                    } else {
                        MXLog.error("Found duplicated timeline item, ignoring")
                    }
                }
            case .virtual(let virtualItem):
                switch virtualItem {
                case .dayDivider(let timestamp):
                    // These components will be replaced by a timestamp in upcoming releases
                    let date = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
                    let dateString = date.formatted(date: .complete, time: .omitted)
                    newTimelineItems.append(SeparatorRoomTimelineItem(text: dateString))
                case .readMarker:
                    // Don't show the read marker if it's the last item in the timeline
                    if index != timelineProvider.itemsPublisher.value.indices.last {
                        newTimelineItems.append(ReadMarkerRoomTimelineItem())
                    }
                case .loadingIndicator:
                    newTimelineItems.append(PaginationIndicatorRoomTimelineItem())
                    isBackPaginating = true
                case .timelineStart:
                    newTimelineItems.append(TimelineStartRoomTimelineItem(name: roomProxy.displayName ?? roomProxy.name))
                    canBackPaginate = false
                }
            default:
                break
            }
        }
        
        if Task.isCancelled {
            return
        }

        timelineItems = newTimelineItems
        
        callbacks.send(.updatedTimelineItems)
        callbacks.send(.canBackPaginate(canBackPaginate))
        callbacks.send(.isBackPaginating(isBackPaginating))
    }
    
    private func computeGroupState(for itemProxy: TimelineItemProxy,
                                   previousItemProxy: TimelineItemProxy?,
                                   nextItemProxy: TimelineItemProxy?) -> TimelineItemGroupState {
        guard let previousItem = previousItemProxy else {
            //  no previous item, check next item
            guard let nextItem = nextItemProxy else {
                //  no next item neither, this is single
                return .single
            }
            guard nextItem.canBeGrouped(with: itemProxy) else {
                //  there is a next item but can't be grouped, this is single
                return .single
            }
            //  next will be grouped with this one, this is the start
            return .beginning
        }

        guard let nextItem = nextItemProxy else {
            //  no next item
            guard itemProxy.canBeGrouped(with: previousItem) else {
                //  there is a previous item but can't be grouped, this is single
                return .single
            }
            //  will be grouped with previous, this is the end
            return .end
        }

        guard itemProxy.canBeGrouped(with: previousItem) else {
            guard nextItem.canBeGrouped(with: itemProxy) else {
                //  there is a next item but can't be grouped, this is single
                return .single
            }
            //  next will be grouped with this one, this is the start
            return .beginning
        }

        guard nextItem.canBeGrouped(with: itemProxy) else {
            //  there is a next item but can't be grouped, this is the end
            return .end
        }

        //  next will be grouped with this one, this is the start
        return .middle
    }
    
    private func loadVideoForTimelineItem(_ timelineItem: VideoRoomTimelineItem) async {
        if timelineItem.cachedVideoURL != nil {
            // already cached
            return
        }

        guard let source = timelineItem.source else {
            return
        }
        
        let fileExtension = movieFileExtension(for: timelineItem.body)
        switch await mediaProvider.loadFileFromSource(source, fileExtension: fileExtension) {
        case .success(let fileURL):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? VideoRoomTimelineItem else {
                return
            }

            item.cachedVideoURL = fileURL
            timelineItems[index] = item
        case .failure:
            break
        }
    }
    
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

    private func loadFileForImageTimelineItem(_ timelineItem: ImageRoomTimelineItem) async {
        if timelineItem.cachedFileURL != nil {
            // already cached
            return
        }

        guard let source = timelineItem.source else {
            return
        }

        // This is not great. We could better estimate file extension from the mimetype.
        guard let fileExtension = timelineItem.body.split(separator: ".").last else {
            return
        }
        switch await mediaProvider.loadFileFromSource(source, fileExtension: String(fileExtension)) {
        case .success(let fileURL):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? ImageRoomTimelineItem else {
                return
            }

            item.cachedFileURL = fileURL
            timelineItems[index] = item
        case .failure:
            break
        }
    }

    private func loadFileForTimelineItem(_ timelineItem: FileRoomTimelineItem) async {
        if timelineItem.cachedFileURL != nil {
            // already cached
            return
        }

        guard let source = timelineItem.source else {
            return
        }

        // This is not great. We could better estimate file extension from the mimetype.
        guard let fileExtension = timelineItem.body.split(separator: ".").last else {
            return
        }
        switch await mediaProvider.loadFileFromSource(source, fileExtension: String(fileExtension)) {
        case .success(let fileURL):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? FileRoomTimelineItem else {
                return
            }

            item.cachedFileURL = fileURL
            timelineItems[index] = item
        case .failure:
            break
        }
    }

    private func loadAudioForTimelineItem(_ timelineItem: AudioRoomTimelineItem) async {
        if timelineItem.cachedAudioURL != nil {
            // already cached
            return
        }

        guard let source = timelineItem.source else {
            return
        }

        // This is not great. We could better estimate file extension from the mimetype.
        guard let fileExtension = timelineItem.body.split(separator: ".").last else {
            return
        }

        switch await mediaProvider.loadFileFromSource(source, fileExtension: String(fileExtension)) {
        case .success(let audioURL):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? AudioRoomTimelineItem else {
                return
            }

            item.cachedAudioURL = audioURL
            timelineItems[index] = item
        case .failure:
            break
        }
    }
}
