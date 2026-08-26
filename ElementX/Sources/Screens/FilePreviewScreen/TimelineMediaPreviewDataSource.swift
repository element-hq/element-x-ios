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
    /// Whether a real (post-load) pagination state has been seen. `.initial` is `endReached` on
    /// both sides as a "don't paginate yet" sentinel, indistinguishable by value from a genuinely
    /// exhausted small room, so we only collapse the phantom padding (below) once a real state has
    /// arrived; until then the padding stays, keeping room to paginate.
    private var hasReceivedRealPaginationState: Bool
    
    /// Reaching the end of the timeline changes which placeholder an index shows, so a change
    /// needs to be published too, not only the arrival of new items.
    var paginationState: TimelinePaginationState {
        didSet {
            guard paginationState != oldValue else { return }
            if paginationState != .initial {
                hasReceivedRealPaginationState = true
            }
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
        hasReceivedRealPaginationState = paginationState != .initial
        
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
        hasReceivedRealPaginationState = true
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
                if let oldItem = previewItems.first(where: { $0.id == newItem.id || $0.isLocalEcho(of: newItem) }) {
                    oldItem.content = newItem.content
                    oldItem.id = newItem.id // A sent local echo: transaction ID → event ID.
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
        } else if let anchor = [currentItem.mediaItem?.id].compactMap({ $0 }).first(where: { id in newItems.contains { $0.id == id } })
            ?? previewItems.first(where: { old in newItems.contains { $0.id == old.id } })?.id,
            let oldIndex = previewItems.firstIndex(where: { $0.id == anchor }),
            let newIndex = newItems.firstIndex(where: { $0.id == anchor }) {
            // The loaded run isn't a contiguous slice of the new list: the timeline reshuffled it
            // (de-duplication, a backfill landing in the middle). Ignoring such updates froze the
            // viewer at a handful of items while the timeline went on to the room's start. Keep the
            // current item (or any shared item) at its index and take the new list; the other pages
            // are rebuilt by the controller.
            let oldAfter = previewItems.count - 1 - oldIndex
            let newAfter = newItems.count - 1 - newIndex
            backwardPadding -= newIndex - oldIndex
            forwardPadding -= newAfter - oldAfter
            hasPaginated = true
            MXLog.info("Media viewer: items reshuffled (\(previewItems.count) -> \(newItems.count)), re-anchored at \(anchor)")
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
    
    /// Once a direction is fully paginated we drop its phantom padding to zero, so the last
    /// real item becomes QuickLook's own content edge and its scroll view bounces natively there
    /// (the affordance for "nothing more this way") instead of us hard-blocking the swipe.
    /// This only changes the reported count at the two end-reached transitions, so the padding
    /// invariant (constant count during normal pagination) still holds everywhere else.
    private var effectiveBackwardPadding: Int {
        if hasReceivedRealPaginationState, paginationState.backward == .endReached {
            return 0
        }
        return backwardPadding
    }
    
    private var effectiveForwardPadding: Int {
        if hasReceivedRealPaginationState, paginationState.forward == .endReached {
            return 0
        }
        return forwardPadding
    }
    
    var firstPreviewItemIndex: Int {
        effectiveBackwardPadding
    }
    
    var lastPreviewItemIndex: Int {
        effectiveBackwardPadding + previewItems.count - 1
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        previewItems.count + effectiveBackwardPadding + effectiveForwardPadding
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> any QLPreviewItem {
        let arrayIndex = index - effectiveBackwardPadding
        
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
            didSet { updatePreviewItemValues() }
        }
        
        /// The timeline's cached thumbnail written to a file, shown in place of the media while it
        /// downloads (the tapped image is otherwise a spinner on black until the full-size file
        /// lands). Superseded by `fileHandle`; the file dies with the view model.
        var placeholderURL: URL? {
            didSet { updatePreviewItemValues() }
        }
        
        /// QuickLook is (or will be) showing a placeholder rather than the media: the thumbnail, or
        /// the shared loading image every file-less item answers with.
        var isShowingPlaceholder: Bool {
            fileHandle == nil && (placeholderURL != nil || Self.loadingPlaceholderURL != nil)
        }
        
        /// What an item without a file or thumbnail hands QuickLook: a black image, so the page is
        /// built as a placeholder page (swapped when the media lands) rather than from nothing,
        /// which QuickLook renders as its "unavailable / copy to" page and never re-reads on its
        /// own. Written once per process into the temp directory.
        static let loadingPlaceholderURL: URL? = {
            let size = CGSize(width: 1080, height: 1920)
            let format = UIGraphicsImageRendererFormat()
            format.scale = 1
            let data = UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.5) { context in
                UIColor.black.setFill()
                context.fill(CGRect(origin: .zero, size: size))
            }
            let url = FileManager.default.temporaryDirectory.appendingPathComponent("media-preview-loading-\(ProcessInfo.processInfo.processIdentifier).jpg")
            do {
                try data.write(to: url)
                return url
            } catch {
                MXLog.error("Failed writing the media viewer's loading placeholder: \(error)")
                return nil
            }
        }()
        
        var downloadError: Error?
        
        /// A stable identifier that's unique per preview item — including individual gallery
        /// attachments that would otherwise share their parent event's ID. Only changes when a
        /// local echo is sent and its transaction ID gives way to the event ID.
        fileprivate(set) var id: MediaPreviewItemID
        
        /// Whether this is the local echo that `sentItem` is the remote echo of: sending swaps the
        /// transaction ID for an event ID (so `id` changes) but the timeline recycles the unique ID.
        /// Matching on it keeps the page, its file (loaded from the local media cache) and state
        /// instead of rebuilding the viewer around a "new" item.
        fileprivate func isLocalEcho(of sentItem: Media) -> Bool {
            guard timelineItem.id.transactionID != nil, sentItem.timelineItem.id.eventID != nil,
                  timelineItem.id.uniqueID == sentItem.timelineItem.id.uniqueID else { return false }
            switch (content, sentItem.content) {
            case (.timelineItem, .timelineItem): return true
            case (.galleryItem(_, let item), .galleryItem(_, let sentGalleryItem)): return item.id.mediaIndex == sentGalleryItem.id.mediaIndex
            default: return false
            }
        }
        
        init(timelineItem: EventBasedMessageTimelineItemProtocol) {
            content = .timelineItem(timelineItem)
            id = MediaPreviewItemID(timelineItem: timelineItem)
            super.init()
            updatePreviewItemValues()
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
            super.init()
            updatePreviewItemValues()
        }
        
        /// Wraps a single attachment of a gallery message. `.other` items have no media source,
        /// so QuickLook falls back to its default unsupported-item screen.
        init(galleryParent: GalleryRoomTimelineItem, item: GalleryItem) {
            content = .galleryItem(parent: galleryParent, item: item)
            id = .galleryItem(item.id)
            super.init()
            updatePreviewItemValues()
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
            _previewItemURL.withLock { $0 = fileHandle?.url ?? placeholderURL ?? Self.loadingPlaceholderURL }
            // No background text until there's something (the file or its placeholder) to show it under.
            _previewItemTitle.withLock { $0 = fileHandle != nil || placeholderURL != nil ? filename : " " }
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
        
        /// The media's pixel size from the event, when known.
        var mediaSize: CGSize? {
            switch content {
            case .galleryItem(_, let item):
                item.size
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let imageItem as ImageRoomTimelineItem: imageItem.content.imageInfo.size
                case let videoItem as VideoRoomTimelineItem: videoItem.content.videoInfo.size
                default: nil
                }
            }
        }
        
        /// The thumbnail's pixel size from the event, when known.
        var thumbnailSize: CGSize? {
            switch content {
            case .galleryItem(_, let item):
                switch item {
                case .image(_, let content): content.thumbnailInfo?.size
                case .video(_, let content): content.thumbnailInfo?.size
                default: nil
                }
            case .timelineItem(let timelineItem):
                switch timelineItem {
                case let imageItem as ImageRoomTimelineItem: imageItem.content.thumbnailInfo?.size
                case let videoItem as VideoRoomTimelineItem: videoItem.content.thumbnailInfo?.size
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
            fileHandle?.url.flatMap { try? FileManager.default.sizeForItem(at: $0) } ?? expectedFileSize
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
