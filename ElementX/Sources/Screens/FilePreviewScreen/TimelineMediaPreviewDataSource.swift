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
    
    /// Reaching the end of the timeline changes which placeholder an index shows, so a change
    /// needs to be published too, not only the arrival of new items.
    var paginationState: TimelinePaginationState {
        didSet {
            guard paginationState != oldValue else { return }
            previewItemsPaginationPublisher.send()
        }
    }
    
    /// The gallery attachments to include, so that a gallery only contributes the media being browsed.
    private let allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]?
    
    /// Builds a data source spanning every previewable attachment in the timeline, paginating
    /// as the user swipes past the loaded range. Used when tapping a standalone media message.
    init(itemViewStates: [RoomTimelineItemViewState],
         initialItem: EventBasedMessageTimelineItemProtocol,
         initialPadding: Int = 100,
         paginationState: TimelinePaginationState,
         allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]? = nil) {
        self.allowedGalleryItemTypes = allowedGalleryItemTypes
        
        previewItems = itemViewStates.flatMap { $0.previewableMedia(allowedGalleryItemTypes: allowedGalleryItemTypes) }
        
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
         initialIndex: Int) {
        allowedGalleryItemTypes = nil // All of the gallery's attachments are shown.
        
        let media = galleryItem.content.items.map { item in
            TimelineMediaPreviewItem.Media(galleryParent: galleryItem, item: item)
        }
        
        if media.indices.contains(initialIndex) {
            // We set the entire gallery here up front.
            previewItems = media
            initialItemIndex = initialIndex
            currentItem = .media(media[initialIndex])
        } else {
            // Fall back to a synthetic placeholder for empty galleries — shouldn't happen in practice.
            previewItems = [.init(timelineItem: galleryItem)]
            initialItemIndex = 0
            currentItem = .media(previewItems[0])
        }
        
        // And we disable any use of the timeline by configuring the data source as though everything has paginated.
        backwardPadding = 0
        forwardPadding = 0
        paginationState = .init(backward: .endReached, forward: .endReached)
    }
    
    func updateCurrentItem(_ item: TimelineMediaPreviewItem) {
        currentItem = item
    }
    
    func updatePreviewItems(itemViewStates: [RoomTimelineItemViewState]) {
        let newItems: [TimelineMediaPreviewItem.Media] = itemViewStates
            .flatMap { $0.previewableMedia(allowedGalleryItemTypes: allowedGalleryItemTypes) }
            .map { newItem in
                // If an item already exists use that instead to preserve the file handle, download error etc.
                if let oldItem = previewItems.first(where: { $0.id == newItem.id }) {
                    oldItem.content = newItem.content
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
        /// A standalone timeline message, or a single gallery attachment with its parent event.
        fileprivate enum Content {
            case timelineItem(EventBasedMessageTimelineItemProtocol)
            case galleryItem(parent: EventBasedMessageTimelineItemProtocol, item: GalleryItem)
        }
        
        fileprivate var content: Content {
            didSet { updatePreviewItemValues() }
        }
        
        /// The parent event, so menu actions (redact, reply, …) target the gallery as a whole.
        var timelineItem: EventBasedMessageTimelineItemProtocol {
            switch content {
            case .timelineItem(let timelineItem): timelineItem
            case .galleryItem(let parent, _): parent
            }
        }
        
        var fileHandle: MediaFileHandleProxy? {
            didSet {
                // The full media arriving over a thumbnail means QuickLook, which built the page
                // from the thumbnail, needs a refresh to show the full media (it won't otherwise:
                // the page isn't "unavailable"). Flag it so the controller can force that refresh.
                if fileHandle != nil, thumbnailFileHandle != nil {
                    wasUpgradedFromThumbnail = true
                }
                updatePreviewItemValues()
            }
        }

        /// A cached thumbnail shown while the full media downloads, so a swipe never lands on a
        /// blank page. Superseded by `fileHandle` once the full media is ready.
        var thumbnailFileHandle: MediaFileHandleProxy? {
            didSet { updatePreviewItemValues() }
        }

        /// Whether the full media has just replaced a thumbnail that was already on screen.
        private(set) var wasUpgradedFromThumbnail = false

        /// Clears the upgrade flag once the controller has refreshed the page for it.
        func didHandleThumbnailUpgrade() {
            wasUpgradedFromThumbnail = false
        }

        var downloadError: Error?
        
        /// A stable identifier that's unique per preview item — including individual gallery
        /// attachments that would otherwise share their parent event's ID.
        let id: MediaPreviewItemID
        
        init(timelineItem: EventBasedMessageTimelineItemProtocol) {
            content = .timelineItem(timelineItem)
            id = MediaPreviewItemID(timelineItem: timelineItem)
        }
        
        init?(roomTimelineItemViewState: RoomTimelineItemViewState) {
            let timelineItem: EventBasedMessageTimelineItemProtocol
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
            content = .timelineItem(timelineItem)
            id = MediaPreviewItemID(timelineItem: timelineItem)
        }
        
        /// Wraps a single attachment of a gallery message. `.other` items have no media source,
        /// so QuickLook falls back to its default unsupported-item screen.
        init(galleryParent: GalleryRoomTimelineItem, item: GalleryItem) {
            content = .galleryItem(parent: galleryParent, item: item)
            id = .galleryItem(item.id)
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
            // Fall back to the thumbnail while the full media downloads, so QuickLook shows the
            // thumbnail rather than a blank page.
            let url = fileHandle?.url ?? thumbnailFileHandle?.url
            _previewItemURL.withLock { $0 = url }

            // Don't show any background text (" ") until the full media is ready.
            _previewItemTitle.withLock { $0 = fileHandle == nil ? " " : filename }
        }
        
        // MARK: Event details
        
        var sender: TimelineItemSender {
            timelineItem.sender
        }
        
        var timestamp: Date {
            timelineItem.timestamp
        }
        
        // MARK: Media details
        
        /// The kind of media, used to decide how it should be saved.
        enum Kind { case image, video, file }
        
        var kind: Kind {
            switch content {
            case .galleryItem(_, let item):
                switch item {
                case .image: .image
                case .video: .video
                case .audio, .file, .other: .file
                }
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case is ImageRoomTimelineItem: .image
                case is VideoRoomTimelineItem: .video
                default: .file
                }
            }
        }
        
        var mediaSource: MediaSourceProxy? {
            switch content {
            case .galleryItem(_, let item):
                item.mediaSource
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let audioItem as AudioRoomTimelineItem: audioItem.content.source
                case let fileItem as FileRoomTimelineItem: fileItem.content.source
                case let imageItem as ImageRoomTimelineItem: imageItem.content.imageInfo.source
                case let videoItem as VideoRoomTimelineItem: videoItem.content.videoInfo.source
                default: nil
                }
            }
        }
        
        var thumbnailMediaSource: MediaSourceProxy? {
            switch content {
            case .galleryItem(_, let item):
                item.thumbnailSource
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let fileItem as FileRoomTimelineItem: fileItem.content.thumbnailSource
                case let imageItem as ImageRoomTimelineItem: imageItem.content.thumbnailInfo?.source
                case let videoItem as VideoRoomTimelineItem: videoItem.content.thumbnailInfo?.source
                default: nil
                }
            }
        }
        
        var filename: String? {
            switch content {
            case .galleryItem(_, let item):
                item.filename
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let audioItem as AudioRoomTimelineItem: audioItem.content.filename
                case let fileItem as FileRoomTimelineItem: fileItem.content.filename
                case let imageItem as ImageRoomTimelineItem: imageItem.content.filename
                case let videoItem as VideoRoomTimelineItem: videoItem.content.filename
                default: nil
                }
            }
        }
        
        var fileSize: UInt? {
            previewItemURL.flatMap { try? FileManager.default.sizeForItem(at: $0) } ?? expectedFileSize
        }
        
        private var expectedFileSize: UInt? {
            switch content {
            case .galleryItem(_, let item):
                item.fileSize
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let audioItem as AudioRoomTimelineItem: audioItem.content.fileSize
                case let fileItem as FileRoomTimelineItem: fileItem.content.fileSize
                case let imageItem as ImageRoomTimelineItem: imageItem.content.imageInfo.fileSize
                case let videoItem as VideoRoomTimelineItem: videoItem.content.videoInfo.fileSize
                default: nil
                }
            }
        }
        
        var hasCaption: Bool {
            // No need to special-case gallery items here, captions live on the gallery event itself
            timelineItem.hasMediaCaption
        }
        
        var caption: String? {
            timelineItem.mediaCaption
        }
        
        var formattedCaption: AttributedString? {
            timelineItem.formattedMediaCaption
        }
        
        var contentType: String? {
            switch content {
            case .galleryItem(_, let item):
                item.contentType?.localizedDescription
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let audioItem as AudioRoomTimelineItem: audioItem.content.contentType?.localizedDescription
                case let fileItem as FileRoomTimelineItem: fileItem.content.contentType?.localizedDescription
                case let imageItem as ImageRoomTimelineItem: imageItem.content.contentType?.localizedDescription
                case let videoItem as VideoRoomTimelineItem: videoItem.content.contentType?.localizedDescription
                default: nil
                }
            }
        }
        
        var blurhash: String? {
            switch content {
            case .galleryItem(_, let item):
                item.blurhash
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let imageItem as ImageRoomTimelineItem: imageItem.content.blurhash
                case let videoItem as VideoRoomTimelineItem: videoItem.content.blurhash
                default: nil
                }
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

private extension RoomTimelineItemViewState {
    /// The media of this item that can be previewed, flattening a gallery message into its individual
    /// attachments so that they can be browsed alongside the timeline's other media.
    /// - Parameter allowedGalleryItemTypes: Restricts a gallery's attachments to the media being
    ///   browsed, as the SDK can only filter the gallery event as a whole.
    func previewableMedia(allowedGalleryItemTypes: [TimelineAllowedGalleryItemType]?) -> [TimelineMediaPreviewItem.Media] {
        guard case .gallery(let galleryItem) = type else {
            return [TimelineMediaPreviewItem.Media(roomTimelineItemViewState: self)].compactMap { $0 }
        }
        
        return galleryItem.content.items(matching: allowedGalleryItemTypes).map {
            TimelineMediaPreviewItem.Media(galleryParent: galleryItem, item: $0.item)
        }
    }
}
