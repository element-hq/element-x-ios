//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    
    var paginationState: TimelinePaginationState
    
    init(itemViewStates: [RoomTimelineItemViewState],
         initialItem: EventBasedMessageTimelineItemProtocol,
         initialPadding: Int = 100,
         paginationState: TimelinePaginationState) {
        previewItems = itemViewStates.compactMap(TimelineMediaPreviewItem.Media.init)
        self.initialItem = initialItem
        
        if let initialItemArrayIndex = previewItems.firstIndex(where: { $0.id == initialItem.id.eventOrTransactionID }) {
            initialItemIndex = initialItemArrayIndex + initialPadding
            currentItem = .media(previewItems[initialItemArrayIndex])
        } else {
            // The timeline hasn't loaded the initial item yet, so replace the whatever was loaded with
            // the item the user wants to preview.
            initialItemIndex = initialPadding
            previewItems = [.init(timelineItem: initialItem)]
            currentItem = .media(previewItems[0])
        }
        
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
            // When the timeline is loading items from the store and the initial item is the only
            // preview in the array, we don't want to wipe it out, so if the existing items aren't
            // found within the new items then let's ignore the update for now. This comes with a
            // tradeoff that when a media gets redacted, no more previews will be added to the viewer.
            //
            // Note for the future if anyone wants to fix the redaction issue: Reloading the data source,
            // will also reload the current item resetting any interaction the user has made with it.
            // If you ignore the pagination, then the next time they swipe they'll land on a different
            // media but this is probably less jarring overall. I hate QLPreviewController!
            
            MXLog.info("Ignoring update: unable to find existing preview items range.")
            return
        }
        
        previewItems = newItems
        
        if hasPaginated {
            previewItemsPaginationPublisher.send()
        }
    }
    
    // MARK: - QLPreviewControllerDataSource
    
    var firstPreviewItemIndex: Int {
        backwardPadding
    }

    var lastPreviewItemIndex: Int {
        backwardPadding + previewItems.count - 1
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewItems.count + backwardPadding + forwardPadding
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        let arrayIndex = index - backwardPadding
        
        if index < firstPreviewItemIndex {
            return paginationState.backward == .endReached ? TimelineMediaPreviewItem.Loading.timelineStart : .paginatingBackwards
        } else if index > lastPreviewItemIndex {
            return paginationState.forward == .endReached ? TimelineMediaPreviewItem.Loading.timelineEnd : .paginatingForwards
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
    @Observable class Media: NSObject, QLPreviewItem, Identifiable {
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
        
        /// The timeline item's event or transaction ID.
        ///
        /// We're identifying items by this to ensure that all matching is made using only this part of the identifier. This is
        /// because the unique ID will be different across timelines so when the initial item comes from a regular timeline and
        /// we build a filtered timeline to fetch the other media items, it is impossible to match by the `TimelineItemIdentifier`.
        var id: TimelineItemIdentifier.EventOrTransactionID {
            guard let id = timelineItem.id.eventOrTransactionID else { fatalError("Virtual items cannot be previewed.") }
            return id
        }
        
        // MARK: QLPreviewItem
        
        var previewItemURL: URL? {
            fileHandle?.url
        }
        
        var previewItemTitle: String? {
            switch fileHandle?.url {
            case .some: filename
            case .none: " " // Don't show any background text when the preview is still loading.
            }
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
        
        var fileSize: UInt? {
            previewItemURL.flatMap { try? FileManager.default.sizeForItem(at: $0) } ?? expectedFileSize
        }
        
        private var expectedFileSize: UInt? {
            switch timelineItem {
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
        static let paginatingBackwards = Loading(state: .paginating(.backwards))
        static let paginatingForwards = Loading(state: .paginating(.forwards))
        static let timelineStart = Loading(state: .timelineStart)
        static let timelineEnd = Loading(state: .timelineEnd)
        
        enum State { case paginating(PaginationDirection), timelineStart, timelineEnd }
        let state: State
        
        let previewItemURL: URL? = nil
        let previewItemTitle: String? = "" // Empty to force QLPreviewController to not show any text.
        
        init(state: State) {
            self.state = state
        }
    }
}
