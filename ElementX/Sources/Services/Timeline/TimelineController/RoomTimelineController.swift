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
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let mediaProvider: MediaProviderProtocol
    let roomProxy: RoomProxyProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var timelineItemsUpdateTask: Task<Void, Never>? {
        willSet {
            timelineItemsUpdateTask?.cancel()
        }
    }
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()
    
    var roomId: String {
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
        
        self.timelineProvider
            .itemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.updateTimelineItems()
            }
            .store(in: &cancellables)
        
        updateTimelineItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineControllerError> {
        switch await timelineProvider.paginateBackwards(requestSize: requestSize, untilNumberOfItems: untilNumberOfItems) {
        case .success:
            return .success(())
        case .failure(let error):
            if error == .noMoreMessagesToBackPaginate {
                return .success(())
            }
            return .failure(.generic)
        }
    }
    
    func processItemAppearance(_ itemId: String) async {
        guard let timelineItem = timelineItems.first(where: { $0.id == itemId }) else {
            return
        }
        
        if let item = timelineItem as? EventBasedTimelineItemProtocol {
            await loadUserAvatarForTimelineItem(item)
            await loadUserDisplayNameForTimelineItem(item)
        }
                
        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            await loadThumbnailForImageTimelineItem(item)
        case let item as VideoRoomTimelineItem:
            await loadThumbnailForVideoTimelineItem(item)
        case let item as StickerRoomTimelineItem:
            await loadImageForStickerTimelineItem(item)
        default:
            break
        }
    }
    
    func processItemDisappearance(_ itemId: String) { }

    // swiftlint:disable:next cyclomatic_complexity
    func processItemTap(_ itemId: String) async -> RoomTimelineControllerAction {
        guard let timelineItem = timelineItems.first(where: { $0.id == itemId }) else {
            return .none
        }

        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            await loadFileForImageTimelineItem(item)
            guard let index = timelineItems.firstIndex(where: { $0.id == itemId }),
                  let item = timelineItems[index] as? ImageRoomTimelineItem else {
                return .none
            }
            if let fileURL = item.cachedFileURL {
                return .displayFile(fileURL: fileURL, title: item.text)
            }
            return .none
        case let item as VideoRoomTimelineItem:
            await loadVideoForTimelineItem(item)
            guard let index = timelineItems.firstIndex(where: { $0.id == itemId }),
                  let item = timelineItems[index] as? VideoRoomTimelineItem else {
                return .none
            }
            if let videoURL = item.cachedVideoURL {
                return .displayVideo(videoURL: videoURL, title: item.text)
            }
            return .none
        case let item as FileRoomTimelineItem:
            await loadFileForTimelineItem(item)
            guard let index = timelineItems.firstIndex(where: { $0.id == itemId }),
                  let item = timelineItems[index] as? FileRoomTimelineItem else {
                return .none
            }
            if let fileURL = item.cachedFileURL {
                return .displayFile(fileURL: fileURL, title: item.text)
            }
            return .none
        default:
            return .none
        }
    }
    
    func sendMessage(_ message: String) async {
        MXLog.info("Send message in \(roomId)")
        switch await timelineProvider.sendMessage(message) {
        default:
            break
        }
    }
    
    func sendReply(_ message: String, to itemId: String) async {
        MXLog.info("Send reply in \(roomId)")
        switch await timelineProvider.sendMessage(message, inReplyToItemId: itemId) {
        default:
            break
        }
    }
    
    func sendReaction(_ reaction: String, for itemId: String) async {
        MXLog.info("Send reaction in \(roomId)")
        switch await timelineProvider.sendReaction(reaction, for: itemId) {
        default:
            break
        }
    }

    func editMessage(_ newMessage: String, of itemId: String) async {
        MXLog.info("Edit message in \(roomId)")
        switch await timelineProvider.editMessage(newMessage, originalItemId: itemId) {
        default:
            break
        }
    }
    
    func redact(_ eventID: String) async {
        MXLog.info("Send redaction in \(roomId)")
        switch await timelineProvider.redact(eventID) {
        default:
            break
        }
    }
    
    // Handle this paralel to the timeline items so we're not forced
    // to bundle the Rust side objects within them
    func debugDescriptionFor(_ itemId: String) -> String {
        var description = "Unknown item"
        timelineProvider.itemsPublisher.value.forEach { timelineItemProxy in
            switch timelineItemProxy {
            case .event(let item):
                if item.id == itemId {
                    description = item.debugDescription
                    return
                }
            default:
                break
            }
        }
        
        return description
    }
    
    func retryDecryption(forSessionId sessionId: String) async {
        await timelineProvider.retryDecryption(forSessionId: sessionId)
    }

    // MARK: - Private
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        updateTimelineItems()
    }
    
    private func updateTimelineItems() {
        timelineItemsUpdateTask = Task {
            await asyncUpdateTimelineItems()
        }
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    private func asyncUpdateTimelineItems() async {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        var canBackPaginate = true
        var isBackPaginating = false

        for (index, itemProxy) in timelineProvider.itemsPublisher.value.enumerated() {
            if Task.isCancelled {
                return
            }

            let previousItemProxy = timelineProvider.itemsPublisher.value[safe: index - 1]
            let nextItemProxy = timelineProvider.itemsPublisher.value[safe: index + 1]

            let groupState = computeGroupState(for: itemProxy, previousItemProxy: previousItemProxy, nextItemProxy: nextItemProxy)
            
            switch itemProxy {
            case .event(let eventItem):
                newTimelineItems.append(timelineItemFactory.buildTimelineItemFor(eventItemProxy: eventItem,
                                                                                 groupState: groupState))
            case .virtual(let virtualItem):
                switch virtualItem {
                case .dayDivider(let year, let month, let day):
                    // These components will be replaced by a timestamp in upcoming releases
                    let dateComponents = DateComponents(calendar: .current, year: Int(year), month: Int(month), day: Int(day))
                    if let dateString = dateComponents.date?.formatted(date: .complete, time: .omitted) {
                        newTimelineItems.append(SeparatorRoomTimelineItem(text: dateString))
                    } else {
                        MXLog.error("Failed formatting separator date")
                    }
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
    
    private func loadThumbnailForImageTimelineItem(_ timelineItem: ImageRoomTimelineItem) async {
        if timelineItem.image != nil {
            return
        }
        
        guard let source = timelineItem.source else {
            return
        }
        
        switch await mediaProvider.loadImageFromSource(source) {
        case .success(let image):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? ImageRoomTimelineItem else {
                return
            }
            
            item.image = image
            timelineItems[index] = item
            callbacks.send(.updatedTimelineItem(timelineItem.id))
        case .failure:
            break
        }
    }

    private func loadThumbnailForVideoTimelineItem(_ timelineItem: VideoRoomTimelineItem) async {
        if timelineItem.image != nil {
            return
        }

        guard let source = timelineItem.thumbnailSource else {
            return
        }

        switch await mediaProvider.loadImageFromSource(source) {
        case .success(let image):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? VideoRoomTimelineItem else {
                return
            }

            item.image = image
            timelineItems[index] = item
            callbacks.send(.updatedTimelineItem(timelineItem.id))
        case .failure:
            break
        }
    }
    
    private func loadImageForStickerTimelineItem(_ timelineItem: StickerRoomTimelineItem) async {
        if timelineItem.image != nil {
            return
        }
        
        guard let url = timelineItem.imageURL else {
            return
        }
        
        switch await mediaProvider.loadImageFromURL(url) {
        case .success(let image):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? StickerRoomTimelineItem else {
                return
            }
            
            item.image = image
            timelineItems[index] = item
            callbacks.send(.updatedTimelineItem(timelineItem.id))
        case .failure:
            break
        }
    }

    private func loadVideoForTimelineItem(_ timelineItem: VideoRoomTimelineItem) async {
        if timelineItem.cachedVideoURL != nil {
            // already cached
            return
        }

        guard let source = timelineItem.source else {
            return
        }
        
        let fileExtension = movieFileExtension(for: timelineItem.text)
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
        guard let fileExtension = timelineItem.text.split(separator: ".").last else {
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
        guard let fileExtension = timelineItem.text.split(separator: ".").last else {
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
    
    private func loadUserAvatarForTimelineItem(_ timelineItem: EventBasedTimelineItemProtocol) async {
        guard timelineItem.shouldShowSenderDetails,
              let avatarURL = timelineItem.sender.avatarURL,
              timelineItem.sender.avatar == nil else {
            return
        }
        
        switch await mediaProvider.loadImageFromURL(avatarURL, avatarSize: .user(on: .timeline)) {
        case .success(let avatar):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? EventBasedTimelineItemProtocol else {
                return
            }
            
            item.sender.avatar = avatar
            timelineItems[index] = item
            callbacks.send(.updatedTimelineItem(timelineItem.id))
        case .failure:
            break
        }
    }
    
    #warning("This is here because sender profiles aren't working properly. Remove it entirely later")
    private func loadUserDisplayNameForTimelineItem(_ timelineItem: EventBasedTimelineItemProtocol) async {
        if timelineItem.shouldShowSenderDetails == false || timelineItem.sender.displayName != nil {
            return
        }
        
        switch await roomProxy.loadDisplayNameForUserId(timelineItem.sender.id) {
        case .success(let displayName):
            guard let displayName,
                  let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? EventBasedTimelineItemProtocol else {
                return
            }
            
            item.sender.displayName = displayName
            timelineItems[index] = item
            callbacks.send(.updatedTimelineItem(timelineItem.id))
        case .failure:
            break
        }
    }
}
