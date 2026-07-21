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
import Synchronization

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
        
        let initialPreviewID = TimelineMediaPreviewItem.Media(timelineItem: initialItem).id
        if let initialItemArrayIndex = previewItems.firstIndex(where: { $0.id == initialPreviewID }) {
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
    
    /// Builds a data source scoped to a single gallery's previewable attachments.
    /// Used when the user taps a tile inside a gallery message — paging is local to that
    /// gallery and there's no timeline pagination to drive.
    init(galleryItem: GalleryRoomTimelineItem,
         initialIndex: Int,
         paginationState: TimelinePaginationState) {
        let media = galleryItem.content.items.compactMap { item in
            TimelineMediaPreviewItem.Media(galleryParent: galleryItem, item: item)
        }
        
        let clampedIndex = max(0, min(initialIndex, max(media.count - 1, 0)))
        if media.indices.contains(clampedIndex) {
            previewItems = media
            initialItemIndex = clampedIndex
            currentItem = .media(media[clampedIndex])
        } else {
            // Fall back to a synthetic placeholder for empty galleries — shouldn't happen in practice.
            previewItems = [.init(timelineItem: galleryItem)]
            initialItemIndex = 0
            currentItem = .media(previewItems[0])
        }
        
        // No surrounding pagination — the gallery is the whole world.
        backwardPadding = 0
        forwardPadding = 0
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
    case contentScan(Scan)
    case loading(Loading)
    
    /// The media item this preview is for, regardless of its content scanning state.
    var mediaItem: Media? {
        switch self {
        case .media(let mediaItem): mediaItem
        case .contentScan(let scan): scan.media
        case .loading: nil
        }
    }
    
    /// A media item that is being processed by the content scanner, or that failed a scan
    /// and therefore must not be downloaded or previewed.
    struct Scan: Equatable {
        enum State: Equatable {
            case scanning
            case failure(ContentScanningFailure)
        }
        
        let media: Media
        let state: State
    }
    
    /// Wraps a media file and title to be previewed with QuickLook.
    @Observable class Media: NSObject, QLPreviewItem, Identifiable {
        fileprivate(set) var timelineItem: EventBasedMessageTimelineItemProtocol {
            didSet { updatePreviewItemValues() }
        }
        
        /// When non-nil, this preview item represents a single attachment from a gallery message.
        /// Property accessors (mediaSource, filename, …) read from the gallery item instead of the
        /// parent timeline item — but `timelineItem.id` still points at the parent event so menu
        /// actions (redact, reply, …) target the gallery as a whole.
        let galleryItem: GalleryItem?
        
        var fileHandle: MediaFileHandleProxy? {
            didSet { updatePreviewItemValues() }
        }
        
        var downloadError: Error?
        
        private let previewID: String
        
        init(timelineItem: EventBasedMessageTimelineItemProtocol) {
            self.timelineItem = timelineItem
            galleryItem = nil
            previewID = Media.derivedID(for: timelineItem)
        }
        
        init?(roomTimelineItemViewState: RoomTimelineItemViewState) {
            let resolved: EventBasedMessageTimelineItemProtocol
            switch roomTimelineItemViewState.type {
            case .audio(let audioRoomTimelineItem):
                resolved = audioRoomTimelineItem
            case .file(let fileRoomTimelineItem):
                resolved = fileRoomTimelineItem
            case .image(let imageRoomTimelineItem):
                resolved = imageRoomTimelineItem
            case .video(let videoRoomTimelineItem):
                resolved = videoRoomTimelineItem
            default:
                return nil
            }
            timelineItem = resolved
            galleryItem = nil
            previewID = Media.derivedID(for: resolved)
        }
        
        /// Wraps a single attachment of a gallery message. `.other` items have no media source,
        /// so there's nothing to preview and the initialiser fails.
        init?(galleryParent: GalleryRoomTimelineItem, item: GalleryItem) {
            guard item.kind != .other else { return nil }
            timelineItem = galleryParent
            galleryItem = item
            previewID = "gallery:\(item.id)"
        }
        
        // MARK: Identifiable
        
        /// A stable identifier that's unique per preview item — including individual gallery
        /// attachments that would otherwise share their parent event's ID.
        var id: String {
            previewID
        }
        
        /// Derives a stable identifier from the timeline item's event or transaction ID.
        ///
        /// We identify items by this to ensure that all matching is made using only this part of the identifier. This is
        /// because the unique ID will be different across timelines so when the initial item comes from a regular timeline and
        /// we build a filtered timeline to fetch the other media items, it is impossible to match by the `TimelineItemIdentifier`.
        private static func derivedID(for timelineItem: EventBasedMessageTimelineItemProtocol) -> String {
            guard let id = timelineItem.id.eventOrTransactionID else { fatalError("Virtual items cannot be previewed.") }
            switch id {
            case .eventID(let value): return "event:\(value)"
            case .transactionID(let value): return "txn:\(value)"
            }
        }
        
        // MARK: QLPreviewItem
        
        private let _previewItemURL = Mutex<URL?>(nil)
        nonisolated var previewItemURL: URL? { // nonisolated as QuickLook can call from any thread (macOS 26).
            _previewItemURL.withLock { $0 }
        }
        
        private let _previewItemTitle = Mutex<String?>(" ")
        nonisolated var previewItemTitle: String? { // nonisolated as QuickLook can call from any thread (macOS 26).
            _previewItemTitle.withLock { $0 }
        }
        
        private func updatePreviewItemValues() {
            let url = fileHandle?.url
            _previewItemURL.withLock { $0 = url }
            
            // Don't show any background text (" ") while the preview is still loading.
            _previewItemTitle.withLock { $0 = url == nil ? " " : filename }
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
            if let galleryItem {
                return galleryItem.mediaSource
            }
            switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                return audioItem.content.source
            case let fileItem as FileRoomTimelineItem:
                return fileItem.content.source
            case let imageItem as ImageRoomTimelineItem:
                return imageItem.content.imageInfo.source
            case let videoItem as VideoRoomTimelineItem:
                return videoItem.content.videoInfo.source
            default:
                return nil
            }
        }
        
        var thumbnailMediaSource: MediaSourceProxy? {
            if let galleryItem {
                return galleryItem.thumbnailSource
            }
            switch timelineItem {
            case let fileItem as FileRoomTimelineItem:
                return fileItem.content.thumbnailSource
            case let imageItem as ImageRoomTimelineItem:
                return imageItem.content.thumbnailInfo?.source
            case let videoItem as VideoRoomTimelineItem:
                return videoItem.content.thumbnailInfo?.source
            default:
                return nil
            }
        }
        
        var filename: String? {
            if let galleryItem {
                return galleryItem.filename
            }
            switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                return audioItem.content.filename
            case let fileItem as FileRoomTimelineItem:
                return fileItem.content.filename
            case let imageItem as ImageRoomTimelineItem:
                return imageItem.content.filename
            case let videoItem as VideoRoomTimelineItem:
                return videoItem.content.filename
            default:
                return nil
            }
        }
        
        var fileSize: UInt? {
            previewItemURL.flatMap { try? FileManager.default.sizeForItem(at: $0) } ?? expectedFileSize
        }
        
        private var expectedFileSize: UInt? {
            if galleryItem != nil {
                return nil
            } // The SDK doesn't surface individual gallery item sizes.
            switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                return audioItem.content.fileSize
            case let fileItem as FileRoomTimelineItem:
                return fileItem.content.fileSize
            case let imageItem as ImageRoomTimelineItem:
                return imageItem.content.imageInfo.fileSize
            case let videoItem as VideoRoomTimelineItem:
                return videoItem.content.videoInfo.fileSize
            default:
                return nil
            }
        }
        
        var hasCaption: Bool {
            // Captions live on the gallery itself, not on individual items.
            timelineItem.hasMediaCaption
        }
        
        var caption: String? {
            timelineItem.mediaCaption
        }
        
        var formattedCaption: AttributedString? {
            timelineItem.formattedMediaCaption
        }
        
        var contentType: String? {
            if let galleryItem {
                return galleryItem.contentType?.localizedDescription
            }
            switch timelineItem {
            case let audioItem as AudioRoomTimelineItem:
                return audioItem.content.contentType?.localizedDescription
            case let fileItem as FileRoomTimelineItem:
                return fileItem.content.contentType?.localizedDescription
            case let imageItem as ImageRoomTimelineItem:
                return imageItem.content.contentType?.localizedDescription
            case let videoItem as VideoRoomTimelineItem:
                return videoItem.content.contentType?.localizedDescription
            default:
                return nil
            }
        }
        
        var blurhash: String? {
            if let galleryItem {
                return galleryItem.blurhash
            }
            switch timelineItem {
            case let imageItem as ImageRoomTimelineItem:
                return imageItem.content.blurhash
            case let videoItem as VideoRoomTimelineItem:
                return videoItem.content.blurhash
            default:
                return nil
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
