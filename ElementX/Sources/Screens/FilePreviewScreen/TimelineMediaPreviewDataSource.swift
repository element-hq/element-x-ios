//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import QuickLook

/// A dedicated data source for QLPreviewController to support timeline updates. This was added to
/// workaround the fact that calling `reloadData` on the controller **always** reloads the current
/// item (even if hasn't changed), so any interaction (zoom, media playback, scroll position) would be
/// lost.
///
/// This data source pads the initial array with 100 spaces before and after, adding any pagination into
/// this fixed space. This removes the need to reload the data and preserves the current item's index
/// in the data.
class TimelineMediaPreviewDataSource: NSObject, QLPreviewControllerDataSource {
    /// All of the items in the timeline that can be previewed.
    private(set) var previewItems: [TimelineMediaPreviewItem.Media]
    let previewItemsPaginationPublisher = PassthroughSubject<Void, Never>()
    
    private let initialItem: EventBasedMessageTimelineItemProtocol
    /// The index of the initial item inside of `previewItems` that is to be shown.
    let initialItemIndex: Int
    
    /// The media item that is currently being previewed.
    private(set) var currentItem: TimelineMediaPreviewItem
    
    private var backwardPadding: Int
    private var forwardPadding: Int
    
    var paginationState: PaginationState
    
    init(itemViewStates: [RoomTimelineItemViewState],
         initialItem: EventBasedMessageTimelineItemProtocol,
         initialPadding: Int = 100,
         paginationState: PaginationState) {
        previewItems = itemViewStates.compactMap(TimelineMediaPreviewItem.Media.init)
        self.initialItem = initialItem
        
        let initialItemArrayIndex = previewItems.firstIndex { $0.id == initialItem.id } ?? 0
        initialItemIndex = initialItemArrayIndex + initialPadding
        currentItem = .media(previewItems[initialItemArrayIndex])
        
        backwardPadding = initialPadding
        forwardPadding = initialPadding
        
        self.paginationState = paginationState
    }
    
    func updateCurrentItem(_ item: TimelineMediaPreviewItem) {
        currentItem = item
    }
    
    func updatePreviewItems(itemViewStates: [RoomTimelineItemViewState]) {
        let newItems: [TimelineMediaPreviewItem.Media] = itemViewStates.compactMap { itemViewState in
            guard let newItem = TimelineMediaPreviewItem.Media(roomTimelineItemViewState: itemViewState) else { return nil }
            
            // If an item already exists use that instead to preserve the file handle, download error etc.
            if let oldItem = previewItems.first(where: { $0.id == newItem.id }) {
                oldItem.timelineItem = newItem.timelineItem
                return oldItem
            }
            
            return newItem
        }
        
        var hasPaginated = false
        if let range = newItems.map(\.id).firstRange(of: previewItems.map(\.id)) {
            let backPaginationCount = range.lowerBound
            let forwardPaginationCount = newItems.indices.upperBound - range.upperBound
            
            // Don't worry about negative padding here. Turns out that it just limits
            // the displayable items from growing any more, but makes sure that the
            // current item doesn't jump around so we don't need to reload anything.
            backwardPadding -= backPaginationCount
            forwardPadding -= forwardPaginationCount
            
            if backPaginationCount > 0 || forwardPaginationCount > 0 {
                hasPaginated = true
            }
        } else {
            // Do nothing! Not ideal but if we reload the data source the current item will
            // also be, reloaded resetting any interaction the user has made with it. If we
            // ignore the pagination, then the next time they swipe they'll land on a different
            // media but this is probably less jarring overall. I hate QLPreviewController!
        }
        
        previewItems = newItems
        
        if hasPaginated {
            previewItemsPaginationPublisher.send()
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    var firstPreviewItemIndex: Int { backwardPadding }
    var lastPreviewItemIndex: Int { backwardPadding + previewItems.count - 1 }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewItems.count + backwardPadding + forwardPadding
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        let arrayIndex = index - backwardPadding
        
        if index < firstPreviewItemIndex {
            return paginationState.backward == .timelineEndReached ? TimelineMediaPreviewItem.Loading.timelineStart : .paginating
        } else if index > lastPreviewItemIndex {
            return paginationState.forward == .timelineEndReached ? TimelineMediaPreviewItem.Loading.timelineEnd : .paginating
        } else {
            return previewItems[arrayIndex]
        }
    }
}

// MARK: - TimelineMediaPreviewItem

enum TimelineMediaPreviewItem: Equatable {
    case media(Media)
    case loading(Loading)
    
    /// Wraps a media file and title to be previewed with QuickLook.
    class Media: NSObject, QLPreviewItem, Identifiable {
        fileprivate(set) var timelineItem: EventBasedMessageTimelineItemProtocol
        var fileHandle: MediaFileHandleProxy?
        var downloadError: Error?
        
        init(timelineItem: EventBasedMessageTimelineItemProtocol) {
            self.timelineItem = timelineItem
        }
        
        init?(roomTimelineItemViewState: RoomTimelineItemViewState) {
            switch roomTimelineItemViewState.type {
            case .audio(let audioRoomTimelineItem):
                timelineItem = audioRoomTimelineItem
            case .file(let fileRoomTimelineItem):
                timelineItem = fileRoomTimelineItem
            case .image(let imageRoomTimelineItem):
                timelineItem = imageRoomTimelineItem
            case .video(let videoRoomTimelineItem):
                timelineItem = videoRoomTimelineItem
            default:
                return nil
            }
        }
        
        // MARK: Identifiable
        
        var id: TimelineItemIdentifier { timelineItem.id }
        
        // MARK: QLPreviewItem
        
        var previewItemURL: URL? {
            // Falling back to a clear image allows the presentation animation to work when
            // the item is in the event cache and just needs to be loaded from the store.
            fileHandle?.url ?? Bundle.main.url(forResource: "clear", withExtension: "png")
        }
        
        var previewItemTitle: String? {
            filename
        }
        
        // MARK: Event details
        
        var sender: TimelineItemSender {
            timelineItem.sender
        }
        
        var timestamp: Date {
            timelineItem.timestamp
        }
        
        // MARK: Media details
        
        var mediaSource: MediaSourceProxy? {
            switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                audioItem.content.source
            case let fileItem as FileRoomTimelineItem:
                fileItem.content.source
            case let imageItem as ImageRoomTimelineItem:
                imageItem.content.imageInfo.source
            case let videoItem as VideoRoomTimelineItem:
                videoItem.content.videoInfo.source
            default:
                nil
            }
        }
        
        var thumbnailMediaSource: MediaSourceProxy? {
            switch timelineItem {
            case let fileItem as FileRoomTimelineItem:
                fileItem.content.thumbnailSource
            case let imageItem as ImageRoomTimelineItem:
                imageItem.content.thumbnailInfo?.source
            case let videoItem as VideoRoomTimelineItem:
                videoItem.content.thumbnailInfo?.source
            default:
                nil
            }
        }
        
        var filename: String? {
            switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                audioItem.content.filename
            case let fileItem as FileRoomTimelineItem:
                fileItem.content.filename
            case let imageItem as ImageRoomTimelineItem:
                imageItem.content.filename
            case let videoItem as VideoRoomTimelineItem:
                videoItem.content.filename
            default:
                nil
            }
        }
        
        var fileSize: Double? {
            previewItemURL.flatMap { try? FileManager.default.sizeForItem(at: $0) } ?? expectedFileSize
        }
        
        private var expectedFileSize: Double? {
            let fileSize: UInt? = switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                audioItem.content.fileSize
            case let fileItem as FileRoomTimelineItem:
                fileItem.content.fileSize
            case let imageItem as ImageRoomTimelineItem:
                imageItem.content.imageInfo.fileSize
            case let videoItem as VideoRoomTimelineItem:
                videoItem.content.videoInfo.fileSize
            default:
                nil
            }
            
            return fileSize.map(Double.init)
        }
        
        var caption: String? {
            timelineItem.mediaCaption
        }
        
        var contentType: String? {
            switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                audioItem.content.contentType?.localizedDescription
            case let fileItem as FileRoomTimelineItem:
                fileItem.content.contentType?.localizedDescription
            case let imageItem as ImageRoomTimelineItem:
                imageItem.content.contentType?.localizedDescription
            case let videoItem as VideoRoomTimelineItem:
                videoItem.content.contentType?.localizedDescription
            default:
                nil
            }
        }
        
        var blurhash: String? {
            switch timelineItem {
            case let imageItem as ImageRoomTimelineItem:
                imageItem.content.blurhash
            case let videoItem as VideoRoomTimelineItem:
                videoItem.content.blurhash
            default:
                nil
            }
        }
    }
    
    class Loading: NSObject, QLPreviewItem {
        static let paginating = Loading(state: .paginating)
        static let timelineStart = Loading(state: .timelineStart)
        static let timelineEnd = Loading(state: .timelineEnd)
        
        enum State { case paginating, timelineStart, timelineEnd }
        let state: State
        
        let previewItemURL: URL? = nil
        let previewItemTitle: String? = "" // Empty to force QLPreviewController to not show any text.
        
        init(state: State) {
            self.state = state
        }
    }
}
