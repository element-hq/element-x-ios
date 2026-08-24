//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit

typealias TimelineMediaPreviewViewModelType = StateStoreViewModel<TimelineMediaPreviewViewState, TimelineMediaPreviewViewAction>

class TimelineMediaPreviewViewModel: TimelineMediaPreviewViewModelType {
    static let displayMessageForwardingDelay: TimeInterval = 1.0
    
    let instanceID = UUID()
    
    private let timelineViewModel: TimelineViewModelProtocol
    private var utdExpiryTask: Task<Void, Never>?
    private let mediaProvider: MediaProviderProtocol
    private let photoLibraryManager: PhotoLibraryManagerProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    
    private var contentScannerService: ContentScannerServiceProtocol? {
        timelineViewModel.context.contentScannerService
    }
    
    private let actionsSubject: PassthroughSubject<TimelineMediaPreviewViewModelAction, Never> = .init()
    var actions: AnyPublisher<TimelineMediaPreviewViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    /// Initialises a preview spanning the whole timeline's media, staying in sync with it as it paginates.
    /// `initialGalleryIndex` picks the tapped attachment when `initialItem` is a gallery.
    init(initialItem: EventBasedMessageTimelineItemProtocol,
         initialGalleryIndex: Int? = nil,
         timelineViewModel: TimelineViewModelProtocol,
         mediaProvider: MediaProviderProtocol,
         photoLibraryManager: PhotoLibraryManagerProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings) {
        self.timelineViewModel = timelineViewModel
        self.mediaProvider = mediaProvider
        self.photoLibraryManager = photoLibraryManager
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.appSettings = appSettings
        
        let timelineState = timelineViewModel.context.viewState.timelineState
        
        super.init(initialViewState: TimelineMediaPreviewViewState(dataSource: .init(itemViewStates: timelineState.itemViewStates,
                                                                                     initialItem: initialItem,
                                                                                     initialGalleryIndex: initialGalleryIndex,
                                                                                     paginationState: timelineState.paginationState,
                                                                                     allowedGalleryItemTypes: timelineViewModel.context.viewState.allowedGalleryItemTypes)),
                   mediaProvider: mediaProvider)
        
        startInitialLoad()
        rebuildCurrentItemActions()
        
        let canRedactSelfPublisher = timelineViewModel.context.$viewState.map(\.canCurrentUserRedactSelf)
        let canRedactOthersPublisher = timelineViewModel.context.$viewState.map(\.canCurrentUserRedactOthers)
        
        canRedactSelfPublisher.merge(with: canRedactOthersPublisher)
            .sink { [weak self] _ in
                self?.rebuildCurrentItemActions()
            }
            .store(in: &cancellables)
        
        timelineViewModel.context.$viewState.map(\.timelineState.itemViewStates)
            .removeDuplicates()
            .sink { [weak self] itemViewStates in
                guard let self else { return }
                state.dataSource.updatePreviewItems(itemViewStates: itemViewStates)
                scheduleUTDExpiry()
                // The pending UTDs this update resolved may have been holding the pagination back.
                paginateIfNeeded()
                // Opened from the room screen, the media timeline is still loading when the current
                // item is first shown, so its neighbours only become known (and preloadable) now.
                if let mediaItem = state.currentItem.mediaItem {
                    preloadNeighbours(of: mediaItem)
                }
            }
            .store(in: &cancellables)
        
        timelineViewModel.context.$viewState.map(\.timelineState.paginationState)
            .removeDuplicates()
            .sink { [weak self] paginationState in
                guard let self else { return }
                state.dataSource.paginationState = paginationState
                paginateIfNeeded()
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: TimelineMediaPreviewViewAction) {
        switch viewAction {
        case .updateCurrentItem(let item):
            Task { await updateCurrentItem(item) }
        case .showItemDetails(let mediaItem):
            state.previewControllerDriver.send(.showItemDetails(mediaItem))
        case .menuAction(let action, let item):
            switch action {
            case .viewInRoomTimeline:
                state.previewControllerDriver.send(.dismissDetailsSheet)
                actionsSubject.send(.viewInRoomTimeline(item.timelineItem.id))
            case .downloadMedia:
                Task { await saveCurrentItem() }
            case .redact:
                state.bindings.redactConfirmationItem = item
            case .forward(let itemID):
                Task { await forwardItem(itemID: itemID) }
            default:
                MXLog.error("Received unexpected action: \(action)")
            }
        case .redactConfirmation(let item):
            redactItem(item)
        }
    }
    
    private func forwardItem(itemID: TimelineItemIdentifier) async {
        guard let forwardingItem = await timelineViewModel.makeForwardingItem(for: itemID) else { return }
        state.previewControllerDriver.send(.dismissDetailsSheet)
        actionsSubject.send(.displayMessageForwarding(forwardingItem))
    }
    
    private func updateCurrentItem(_ previewItem: TimelineMediaPreviewItem) async {
        if case let .media(item) = previewItem {
            item.downloadError = nil // Clear any existing error so that the download is retried.
        }
        if let left = state.dataSource.currentItem.mediaItem, left.id != previewItem.mediaItem?.id {
            cancelDownloadIfSwipedAway(from: left)
        }
        setCurrentItem(previewItem)
        
        if case let .media(mediaItem) = previewItem {
            defer { prefetchTimelinePaginationIfNeeded(around: mediaItem) }
            
            var load: Task<Result<MediaFileHandleProxy, MediaProviderError>, Never>?
            if mediaItem.fileHandle == nil, let source = mediaItem.mediaSource {
                guard await checkSourceIsSafeIfNeeded(for: mediaItem, source: source) else { return }
                
                // Join a load already in flight for this item (a preload, or this same page asked
                // for again as QuickLook rebuilds it mid-download) rather than downloading it a
                // second time: two downloads of one video fed one progress bar (it bounced) and
                // doubled the traffic. Started before the neighbours' loads so it keeps the head
                // download slot, and registered so they and the placeholder grace see it.
                if let inFlight = preloads[mediaItem.id] {
                    load = inFlight
                } else {
                    let placeholderFirst = isPlaceholderFirst(mediaItem)
                    let task = Task { [weak self, mediaProvider] in
                        if placeholderFirst {
                            await self?.preparePlaceholder(for: mediaItem)
                        }
                        return await mediaProvider.loadFileFromSource(source, filename: mediaItem.filename) { mediaItem.downloadProgress = $0 }
                    }
                    preloads[mediaItem.id] = task
                    load = task
                    // Otherwise show the timeline's thumbnail (when it's cached) if the media
                    // doesn't land quickly.
                    if !placeholderFirst {
                        preparePlaceholderIfLoadIsSlow(for: mediaItem)
                    }
                }
            }
            
            // Queue the neighbours now rather than once this item has landed: on cellular a load
            // can take seconds, and QuickLook builds the neighbouring pages as soon as it settles.
            preloadNeighbours(of: mediaItem)
            
            guard let load else { return }
            let result = await load.value
            preloads[mediaItem.id] = nil
            mediaItem.downloadProgress = nil
            
            switch result {
            case .success(let handle):
                // A joined preload has already stored the handle and told the controller (one
                // `.itemLoaded`, one page rebuild); only a load of our own needs to.
                guard mediaItem.fileHandle == nil else { break }
                MXLog.info("Media viewer: file for \(mediaItem.id): \(handle.url?.lastPathComponent ?? "nil") (filename: \(mediaItem.filename ?? "nil"), mime: \(mediaItem.mediaSource?.mimeType ?? "nil"))")
                mediaItem.fileHandle = handle
                state.previewControllerDriver.send(.itemLoaded(mediaItem.id))
            case .failure(let error):
                MXLog.error("Failed loading media: \(error)")
                context.objectWillChange.send() // Manually trigger the SwiftUI view update.
                mediaItem.downloadError = error
            }
        } else {
            paginateIfNeeded()
        }
    }
    
    /// The largest neighbouring media fetched ahead of a swipe (media of unknown size are fetched).
    private static let preloadFileSizeLimit: UInt = 10 * 1024 * 1024
    
    /// The neighbour loads in flight, joined by the load on display if the user swipes before they finish.
    private var preloads = [MediaPreviewItemID: Task<Result<MediaFileHandleProxy, MediaProviderError>, Never>]()

    /// How many media items ahead of the loaded edge to start paginating the underlying timeline.
    /// Chosen so the next media's event is loaded before the user swipes onto it, rather than
    /// swiping onto a black placeholder that only then triggers the pagination.
    private static let paginationPrefetchDistance = 5

    /// Paginate the underlying timeline ahead of the swipe: when the current media is within
    /// `paginationPrefetchDistance` of the loaded range's edge, kick off a pagination in that
    /// direction (if one isn't already running) so the media beyond the edge is loaded before
    /// it's reached. Without this, pagination is only triggered once the user lands on the
    /// placeholder page, so every time the loaded window is exhausted a swipe lands on black.
    private func prefetchTimelinePaginationIfNeeded(around mediaItem: TimelineMediaPreviewItem.Media) {
        let items = state.dataSource.previewItems
        guard let index = items.firstIndex(where: { $0.id == mediaItem.id }) else { return }

        let backwardState = state.dataSource.paginationState.backward
        let forwardState = state.dataSource.paginationState.forward
        let nearBack = index <= Self.paginationPrefetchDistance
        let nearFwd = index >= items.count - 1 - Self.paginationPrefetchDistance

        if nearBack, backwardState == .idle {
            timelineViewModel.context.send(viewAction: .paginateBackwards)
        }
        if nearFwd, forwardState == .idle {
            timelineViewModel.context.send(viewAction: .paginateForwards)
        }
    }
    
    /// How many neighbours are fetched ahead of a swipe. QuickLook builds the two pages either side
    /// of the current one, so an item's file must be there by the time the user is two swipes away,
    /// and what bounds that is download time × swipe rate, not QuickLook: phone photos take 1-3s on
    /// cellular, so at a ~1s swipe cadence a reach of 3 reliably lost the race on the 4th swipe
    /// (the file was only queued one swipe earlier) whilst 8 keeps ahead of it. On opening there's
    /// no direction yet, so both sides get the minimum (QuickLook's two + a spare); once the user
    /// swipes, the deep reach only goes the way they're heading and the other side keeps the
    /// minimum, rather than spending the downloads on files a reversal never shows.
    private static let preloadReachAhead = 8
    private static let preloadReachBehind = 2
    private static let preloadReachUndirected = 3
    
    /// The item the last preload was centred on, to tell which way the user is swiping.
    private var lastPreloadCentreID: MediaPreviewItemID?
    
    /// Fetches the media around the current one so that a swipe reveals the media itself rather
    /// than an empty page: QuickLook builds the pages around the current one as it settles on it,
    /// so an item needs its file by the time it comes within that reach. Small files only, and
    /// skipped when a content scanner is configured (a neighbour must be scanned as the current
    /// item is, on display).
    ///
    /// The neighbour gets its file handle straight away; the controller rebuilds any page that
    /// QuickLook built before the file was there.
    private func preloadNeighbours(of mediaItem: TimelineMediaPreviewItem.Media) {
        guard appSettings.preloadMediaInViewer, contentScannerService == nil else { return }

        let items = state.dataSource.previewItems
        guard let index = items.firstIndex(where: { $0.id == mediaItem.id }) else { return }
        
        // By item (not index): pagination prepends items, shifting every index.
        let lastIndex = lastPreloadCentreID.flatMap { lastID in items.firstIndex { $0.id == lastID } }
        lastPreloadCentreID = mediaItem.id
        let direction = lastIndex.map { (index - $0).signum() } ?? 0
        let forwardReach = switch direction {
        case 1: Self.preloadReachAhead
        case -1: Self.preloadReachBehind
        default: Self.preloadReachUndirected
        }
        let backwardReach = switch direction {
        case 1: Self.preloadReachBehind
        case -1: Self.preloadReachAhead
        default: Self.preloadReachUndirected
        }
        
        // Nearest first (1, 1, 2, 2, …) so the most urgent get their download slot first.
        let neighbourIndices = (1...max(forwardReach, backwardReach)).flatMap { distance in
            [distance <= forwardReach ? index + distance : nil,
             distance <= backwardReach ? index - distance : nil].compactMap { $0 }
        }
        for neighbourIndex in neighbourIndices where items.indices.contains(neighbourIndex) {
            preload(items[neighbourIndex])
        }
        
        // QuickLook is handed EVERY loaded item at each (re)build, caches what it got, and never
        // re-reads on its own - and at a sustained swipe cadence the heal reload never finds a
        // quiet gap to run in, so any page built black stays black until landed on. A bounded
        // reach just moves where that first happens (3 made it the 4th swipe, 8 the 9th): give
        // every page a thumbnail to build from instead. Jobs are one-shot per item and mostly
        // memory-cache hits; the media swaps in when it lands.
        for neighbourIndex in items.indices where neighbourIndex != index {
            let neighbour = items[neighbourIndex]
            // Thumbnails only: the no-thumbnail highres fallback would fetch full-size content
            // for a speculative neighbour (encrypted media can't be server-thumbnailed, and the
            // bytes land in the image cache so the file is downloaded again anyway). The
            // exception is media whose sender skipped the thumbnail because the original is
            // already thumbnail-sized: its full-res costs what the thumbnail would have. A rare
            // large thumbnail-less neighbour builds black and gets its poster on display instead.
            guard neighbour.fileHandle == nil, neighbour.placeholderURL == nil, neighbour.kind != .file,
                  neighbour.thumbnailMediaSource != nil || isThumbnailSized(neighbour),
                  !placeholderJobs.contains(neighbour.id) else { continue }
            placeholderJobs.insert(neighbour.id)
            Task { [weak self] in
                await self?.preparePlaceholder(for: neighbour)
                self?.placeholderJobs.remove(neighbour.id)
            }
        }
    }
    
    /// An image whose sender legitimately skipped the thumbnail because the original is already
    /// thumbnail-sized (MSC4409: none required at <=800x600). Fetching its full-res costs what
    /// the thumbnail would have, so the placeholder pass treats it as one - by pixel size when
    /// the event says, else by a small file size.
    private func isThumbnailSized(_ item: TimelineMediaPreviewItem.Media) -> Bool {
        guard item.kind == .image, item.thumbnailMediaSource == nil else { return false }
        if let size = item.mediaSize {
            return min(size.width, size.height) <= 600 && max(size.width, size.height) <= 800
        }
        return item.fileSize.map { $0 <= 1_000_000 } ?? false
    }

    /// Placeholder jobs in flight, so a neighbour isn't rendered twice while swiping around it.
    private var placeholderJobs = Set<MediaPreviewItemID>()
    
    /// With the setting on, a download only runs while the user is explicitly waiting on it: the
    /// item just swiped away from loses its in-flight download, unless it's one the neighbour
    /// preload would fetch anyway (small, with preloading on), so swiping over a run of videos
    /// doesn't quietly fetch all of them. Swiping back retries it.
    private func cancelDownloadIfSwipedAway(from item: TimelineMediaPreviewItem.Media) {
        guard appSettings.cancelMediaDownloadsOnSwipeAway, let load = preloads[item.id],
              isLargeFile(item) || !appSettings.preloadMediaInViewer else { return }
        MXLog.info("Media viewer: swiped away from \(item.id) mid-download, cancelling it")
        load.cancel()
    }
    
    /// Fetches an item's file into the cache ahead of it being displayed (small files only).
    private func preload(_ item: TimelineMediaPreviewItem.Media) {
        guard item.downloadError == nil,
              let source = item.mediaSource,
              !isLargeFile(item) else { return }
        preload(item, source: source)
    }
    
    /// Whether the item's file is too big to fetch speculatively: over ``preloadFileSizeLimit``,
    /// or a video of unknown size (an unsized neighbouring video was preloaded next to the one on
    /// display and starved its download).
    private func isLargeFile(_ item: TimelineMediaPreviewItem.Media) -> Bool {
        item.fileSize.map { $0 > Self.preloadFileSizeLimit } ?? (item.kind == .video)
    }
    
    private func preload(_ item: TimelineMediaPreviewItem.Media, source: MediaSourceProxy, placeholderFirst: Bool = false) {
        guard item.fileHandle == nil, preloads[item.id] == nil else { return }
        
        let itemID = item.id
        preloads[itemID] = Task { [mediaProvider] in
            if placeholderFirst {
                await self.preparePlaceholder(for: item)
            }
            // Failures aren't recorded here: the load on display retries and reports them.
            let result = await mediaProvider.loadFileFromSource(source, filename: item.filename) { item.downloadProgress = $0 }
            preloads[itemID] = nil
            item.downloadProgress = nil
            if case .success(let handle) = result, item.fileHandle == nil {
                MXLog.info("Media viewer: file for \(itemID): \(handle.url?.lastPathComponent ?? "nil") (filename: \(item.filename ?? "nil"), mime: \(source.mimeType ?? "nil"))")
                item.fileHandle = handle
                // Let the controller rebuild QuickLook's page for this item if it built it
                // blank before the file was ready, so a swipe lands on the media not a blank.
                state.previewControllerDriver.send(.itemLoaded(itemID))
            }
            return result
        }
        // A neighbour that isn't cached gets its thumbnail too, so a swipe lands on that, not black.
        preparePlaceholderIfLoadIsSlow(for: item)
    }
    
    /// Scans the media when a content scanner is configured, returning whether it's safe to be downloaded
    /// and previewed, reflecting the scan's progress and outcome in the current item. Both the media and
    /// its thumbnail are scanned as either being downloaded through the scanner can flag the media.
    private func checkSourceIsSafeIfNeeded(for mediaItem: TimelineMediaPreviewItem.Media, source: MediaSourceProxy) async -> Bool {
        guard let contentScannerService else { return true }
        
        let sources = [source, mediaItem.thumbnailMediaSource].compactMap { $0 }
        
        // Only reflect the scanning state when there's no cached verdict, so that
        // scanned items don't flash the scanning indicator when they're revisited.
        if contentScannerService.scanResultFromSources(sources) == nil {
            setCurrentItem(.contentScan(.init(media: mediaItem, state: .scanning)))
        }
        
        switch await contentScannerService.loadScanResultFromSources(sources) {
        case .success(true):
            finishScan(with: .media(mediaItem), for: mediaItem)
            return true
        case .success(false):
            finishScan(with: .contentScan(.init(media: mediaItem, state: .failure(.notSafe))), for: mediaItem)
            return false
        case .failure:
            finishScan(with: .contentScan(.init(media: mediaItem, state: .failure(.notFound))), for: mediaItem)
            return false
        }
    }
    
    /// Reflects the outcome of a scan in the current item, unless the user has already swiped on to another item.
    private func finishScan(with previewItem: TimelineMediaPreviewItem, for mediaItem: TimelineMediaPreviewItem.Media) {
        guard state.currentItem.mediaItem === mediaItem else { return }
        setCurrentItem(previewItem)
    }
    
    private func setCurrentItem(_ previewItem: TimelineMediaPreviewItem) {
        context.objectWillChange.send() // The data source is a reference type so the view needs a manual update.
        state.dataSource.updateCurrentItem(previewItem)
        rebuildCurrentItemActions()
    }
    
    /// Re-evaluates the timeline's shape once the wait on its pending UTDs runs out (see the data source).
    private func scheduleUTDExpiry() {
        utdExpiryTask?.cancel()
        guard let expiry = state.dataSource.nextPendingUTDExpiry else { return }
        utdExpiryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(max(0, expiry.timeIntervalSinceNow)))
            guard !Task.isCancelled, let self else { return }
            state.dataSource.pendingUTDsExpired()
            paginateIfNeeded()
            // Newer pending UTDs (seen later, e.g. brought in by the last pagination) have a later
            // expiry: re-arm for it, or the "Loading more" page waits until the timeline next changes
            // (it sat there indefinitely until a swipe away and back).
            scheduleUTDExpiry()
        }
    }
    
    private func paginateIfNeeded() {
        switch state.currentItem {
        case .loading(.paginatingBackwards):
            if state.dataSource.hasPendingUTDsBeforeOldestMedia {
                // Resolve the nearest ones first: they may be the media we're after, and paginating
                // on would request keys for older pages ahead of theirs (and step past them).
                MXLog.info("Media viewer: undecryptable messages pending behind the oldest media, not paginating yet")
            } else if state.dataSource.paginationState.backward == .idle {
                timelineViewModel.context.send(viewAction: .paginateBackwards)
            }
        case .loading(.paginatingForwards):
            if state.dataSource.paginationState.forward == .idle {
                timelineViewModel.context.send(viewAction: .paginateForwards)
            }
        default:
            break
        }
    }
    
    private func rebuildCurrentItemActions() {
        let timelineContext = timelineViewModel.context
        state.currentItemActions = state.currentItem.mediaItem.flatMap { mediaItem in
            TimelineItemMenuActionProvider(timelineItem: mediaItem.timelineItem,
                                           canCurrentUserSendMessage: timelineContext.viewState.canCurrentUserSendMessage,
                                           canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                           canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                           canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                           pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                           isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                           areThreadsEnabled: timelineContext.viewState.areThreadsEnabled,
                                           timelineKind: timelineContext.viewState.timelineKind,
                                           emojiProvider: timelineContext.viewState.emojiProvider)
                .makeActions()
        }
    }
    
    private func saveCurrentItem() async {
        guard case let .media(mediaItem) = state.currentItem, let fileURL = mediaItem.fileHandle?.url else {
            MXLog.error("Unable to save an item without a URL, the button shouldn't be visible.")
            return
        }
        
        // Dismiss the details sheet (nicer flow for images/video but _required_ in order to select a file directory).
        state.previewControllerDriver.send(.dismissDetailsSheet)
        
        do {
            switch mediaItem.kind {
            case .file:
                state.previewControllerDriver.send(.exportFile(.init(url: fileURL)))
                return // Don't show the indicator.
            case .image:
                try await photoLibraryManager.addResource(.photo, at: fileURL).get()
            case .video:
                try await photoLibraryManager.addResource(.video, at: fileURL).get()
            }
            
            showSavedIndicator()
        } catch PhotoLibraryManagerError.notAuthorized {
            MXLog.error("Not authorised to save item to photo library")
            state.previewControllerDriver.send(.authorizationRequired(appMediator: appMediator))
        } catch {
            MXLog.error("Failed saving item: \(error)")
            showErrorIndicator()
        }
    }
    
    private func redactItem(_ item: TimelineMediaPreviewItem.Media) {
        timelineViewModel.context.send(viewAction: .handleTimelineItemMenuAction(itemID: item.timelineItem.id, action: .redact(isMedia: true)))
        state.bindings.redactConfirmationItem = nil
        state.previewControllerDriver.send(.dismissDetailsSheet)
        actionsSubject.send(.dismiss)
        showRedactedIndicator()
    }
    
    // MARK: - Thumbnail placeholder
    
    /// A temp directory for the placeholder files, removed wholesale when the view model goes.
    private let placeholderDirectory = FileManager.default.temporaryDirectory
        .appendingPathComponent("media-preview-placeholders-\(UUID().uuidString)")
    
    /// The longest side of a placeholder file, in pixels. QuickLook lays an image out at its native
    /// size when it fits the screen and fit-to-screen otherwise, so the placeholder is rendered at
    /// the media's own size (capped to keep the file small) rather than the thumbnail's: a small
    /// file would sit tiny in the middle of the page and jump when the media replaces it.
    private static let placeholderMaxSide: CGFloat = 2048
    
    /// When the item's media isn't downloaded yet but the timeline already drew its thumbnail, writes
    /// that thumbnail to a file for QuickLook to show while the media downloads (the tapped image is
    /// otherwise a spinner on black until the full-size file lands). The controller then refreshes
    /// the page as it does when a file arrives, and swaps the media in when it does.
    private func preparePlaceholder(for item: TimelineMediaPreviewItem.Media) async {
        let directory = placeholderDirectory
        guard let (thumbnail, size, url) = await placeholderJob(for: item, thumbnailTimeout: Self.thumbnailTimeoutOnDisplay) else {
            if item.fileHandle == nil, item.placeholderURL == nil {
                MXLog.info("Media viewer: no thumbnail for \(item.id), no placeholder")
            }
            return
        }
        let written = await Task.detached(priority: .userInitiated) {
            Self.writePlaceholder(thumbnail, size: size, to: url, in: directory)
        }.value
        guard written, item.fileHandle == nil, item.placeholderURL == nil else { return }
        item.placeholderURL = url
        MXLog.info("Media viewer: placeholder for \(item.id) \(Int(size.width))x\(Int(size.height))")
        state.previewControllerDriver.send(.itemLoaded(item.id))
    }
    
    /// Files this big take long enough that the page should show the thumbnail before the download
    /// starts: fetched alongside it, the thumbnail was starved by the download (~5 s on device for
    /// a 90 MB video), leaving the bar over a black page.
    private static let placeholderFirstFileSize: UInt = 10_000_000
    
    private func isPlaceholderFirst(_ item: TimelineMediaPreviewItem.Media) -> Bool {
        contentScannerService == nil && item.kind != .file && item.placeholderURL == nil && item.thumbnailMediaSource != nil
            && item.fileSize.map { $0 >= Self.placeholderFirstFileSize } ?? (item.kind == .video)
    }
    
    /// How long a media load gets before its thumbnail placeholder is made: whether the media is
    /// already in the cache can't be known without an async store read, and a cached load lands
    /// within this, so only media that actually has to download gets (and briefly shows) a placeholder.
    private static let placeholderGrace: Duration = .milliseconds(300)
    /// How long the initial item's presentation waits for a placeholder-first thumbnail.
    private static let placeholderFirstPresentationWait: Duration = .seconds(1)
    
    /// Completes once the initial item's file has loaded or `placeholderGrace` has passed, with the
    /// placeholder written in the latter case. The preview is presented after it, so QuickLook
    /// builds its first page from the file or the thumbnail rather than black and reloaded later.
    private(set) var initialPresentationGate: Task<Void, Never>?
    
    /// Starts loading the initial item straight away (rather than when the controller asks) and
    /// arms the presentation gate. The load on display joins this rather than starting another.
    private func startInitialLoad() {
        guard let item = state.currentItem.mediaItem, item.fileHandle == nil, let source = item.mediaSource,
              contentScannerService == nil else { return }
        if isPlaceholderFirst(item) {
            // The thumbnail first (the download follows it); present once it's up, or after a
            // bounded wait with the page refreshing when it lands.
            preload(item, source: source, placeholderFirst: true)
            initialPresentationGate = Task {
                let started = ContinuousClock.now
                while item.fileHandle == nil, item.placeholderURL == nil, ContinuousClock.now - started < Self.placeholderFirstPresentationWait {
                    try? await Task.sleep(for: .milliseconds(10))
                }
                MXLog.info("Media viewer: placeholder-first initial item, presenting after \(ContinuousClock.now - started), placeholder: \(item.placeholderURL != nil)")
            }
            return
        }
        preload(item, source: source)
        initialPresentationGate = Task { [weak self] in
            // Prepared alongside the grace wait rather than after it, so it adds nothing to the
            // presentation (a wasted temp file if the media arrives in time; cleaned up with the rest).
            let placeholder = Task { [weak self] () -> (URL, CGSize)? in
                guard let self, let (thumbnail, size, url) = await placeholderJob(for: item) else { return nil }
                let directory = placeholderDirectory
                let written = await Task.detached(priority: .userInitiated) {
                    Self.writePlaceholder(thumbnail, size: size, to: url, in: directory)
                }.value
                return written ? (url, size) : nil
            }
            await self?.awaitPlaceholderGrace(for: item)
            guard item.fileHandle == nil else {
                MXLog.info("Media viewer: initial item loaded within the grace period")
                return
            }
            guard let (url, size) = await placeholder.value, item.fileHandle == nil, item.placeholderURL == nil else {
                MXLog.info("Media viewer: no thumbnail for the initial item, no placeholder")
                return
            }
            item.placeholderURL = url
            MXLog.info("Media viewer: placeholder for the initial item \(Int(size.width))x\(Int(size.height))")
        }
    }
    
    /// Makes the item's placeholder once its load has outlived the grace period without landing.
    private func preparePlaceholderIfLoadIsSlow(for item: TimelineMediaPreviewItem.Media) {
        Task { [weak self] in
            await self?.awaitPlaceholderGrace(for: item)
            guard let self, item.fileHandle == nil else { return }
            await preparePlaceholder(for: item)
        }
    }
    
    /// Waits for the item's in-flight load or the grace period, whichever comes first.
    private func awaitPlaceholderGrace(for item: TimelineMediaPreviewItem.Media) async {
        // A poll, not a task-group race: the race's sleep branch never won on device (the gate
        // always waited for the load, the thumbnail path never ran).
        let started = ContinuousClock.now
        while item.fileHandle == nil, preloads[item.id] != nil, ContinuousClock.now - started < Self.placeholderGrace {
            try? await Task.sleep(for: .milliseconds(10))
        }
        MXLog.info("Media viewer: grace wait for \(item.id) ended after \(ContinuousClock.now - started), file: \(item.fileHandle != nil)")
    }
    
    /// What's needed to render an item's placeholder, or nil when it doesn't get one.
    private func placeholderJob(for item: TimelineMediaPreviewItem.Media,
                                thumbnailTimeout: Duration = TimelineMediaPreviewViewModel.thumbnailTimeout) async -> (UIImage, CGSize, URL)? {
        // Videos too: a poster (with the header saying it is loading) beats a black page.
        guard contentScannerService == nil, item.kind != .file, item.fileHandle == nil, item.placeholderURL == nil,
              let thumbnail = await thumbnail(for: item, timeout: thumbnailTimeout) else { return nil }
        let size = Self.placeholderSize(mediaSize: item.mediaSize,
                                        thumbnailSize: CGSize(width: thumbnail.size.width * thumbnail.scale,
                                                              height: thumbnail.size.height * thumbnail.scale))
        return (thumbnail, size, placeholderDirectory.appendingPathComponent("\(UUID().uuidString).jpg"))
    }
    
    /// The poster is the bare thumbnail: a video's play badge is the controller's vector overlay
    /// (`DownloadIndicatorView`), crisp at any poster resolution rather than baked in at the
    /// thumbnail's pixel density.
    private nonisolated static func writePlaceholder(_ thumbnail: UIImage, size: CGSize, to url: URL, in directory: URL) -> Bool {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let data = UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.8) { _ in
            thumbnail.draw(in: CGRect(origin: .zero, size: size))
        }
        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            try data.write(to: url)
            return true
        } catch {
            MXLog.error("Failed writing the media placeholder: \(error)")
            return false
        }
    }
    
    /// The longest a thumbnail is waited for: the SDK's media store answers in milliseconds when it
    /// has it; anything slower is a network fetch that would land after the point.
    private static let thumbnailTimeout: Duration = .milliseconds(400)
    /// Once the page is on display nothing waits on the placeholder, and a big download takes far
    /// longer than this: give a thumbnail that has to be fetched (a cleared media cache, a slow
    /// network, a fetch queued behind the video's own download) time to land rather than leaving
    /// the bar over a black page. The wait ends early anyway once the media lands.
    private static let thumbnailTimeoutOnDisplay: Duration = .seconds(30)
    
    /// The item's thumbnail: the in-memory image cache (what the timeline drew, keyed as the
    /// timeline, gallery and media-grid cells load it) or, that being short-lived, the SDK's
    /// media store via the provider, which caches the result.
    private func thumbnail(for item: TimelineMediaPreviewItem.Media, timeout: Duration) async -> UIImage? {
        let candidates: [(MediaSourceProxy?, CGSize?)] = [(item.thumbnailMediaSource, item.thumbnailSize),
                                                          (item.thumbnailMediaSource ?? item.mediaSource, item.mediaSize),
                                                          (item.mediaSource, item.mediaSize),
                                                          (item.mediaSource, nil)]
        for (source, size) in candidates {
            if let source, let image = mediaProvider.imageFromSource(source, size: size) {
                return image
            }
        }
        guard let source = item.thumbnailMediaSource ?? item.mediaSource else { return nil }
        // A thumbnail-sized original (sent without a thumbnail, MSC4409) is fetched as full
        // content: passing a size here means the thumbnail endpoint, which cannot serve
        // encrypted media - these items could never get a poster at all.
        let size: CGSize? = if item.thumbnailMediaSource == nil {
            isThumbnailSized(item) ? nil : item.mediaSize
        } else {
            item.thumbnailSize
        }
        let lookupStarted = ContinuousClock.now
        let load = mediaProvider.loadImageRetryingOnReconnection(source, size: size)
        // A poll, not a task-group race: the group waited for its load child, which awaited the
        // unstructured load (not cancelled until after the group returned), so the timeout neither
        // bounded the wait nor kept a late result: a poster that landed at 17-20 s (its fetch
        // starved by the video's own download) was dropped and the page stayed black.
        final class Arrival { var image: UIImage?; var done = false }
        let arrival = Arrival()
        Task { arrival.image = try? await load.value; arrival.done = true }
        // Ends early once the media itself lands: a placeholder is pointless then.
        while !arrival.done, item.fileHandle == nil, ContinuousClock.now - lookupStarted < timeout {
            try? await Task.sleep(for: .milliseconds(50))
        }
        let image = arrival.image
        if !arrival.done {
            load.cancel() // Timed out, or overtaken by the media: don't keep a fetch going that nothing will use.
        }
        MXLog.info("Media viewer: thumbnail for \(item.id) from the store: \(image != nil) after \(ContinuousClock.now - lookupStarted)")
        return image
    }
    
    /// The media's size capped to `placeholderMaxSide`; with no size on the event, the thumbnail
    /// scaled up to the cap (photos are bigger than the screen, so fit-to-screen is the right bet).
    private static func placeholderSize(mediaSize: CGSize?, thumbnailSize: CGSize) -> CGSize {
        let base = mediaSize ?? thumbnailSize
        let longest = max(base.width, base.height)
        guard longest > 0 else { return CGSize(width: placeholderMaxSide, height: placeholderMaxSide) }
        let scale = mediaSize == nil ? placeholderMaxSide / longest : min(1, placeholderMaxSide / longest)
        return CGSize(width: (base.width * scale).rounded(), height: (base.height * scale).rounded())
    }
    
    isolated deinit {
        try? FileManager.default.removeItem(at: placeholderDirectory)
        // Closing the viewer: nothing is waiting on the downloads any more.
        if appSettings.cancelMediaDownloadsOnSwipeAway {
            preloads.values.forEach { $0.cancel() }
        }
    }
    
    // MARK: - Indicators
    
    private func showRedactedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.commonFileDeleted,
                                                              icon: \.check))
    }
    
    private func showSavedIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.commonFileSaved,
                                                              icon: \.check))
    }
    
    private func showErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              icon: \.close))
    }
    
    private var statusIndicatorID: String {
        "\(Self.self)-Status"
    }
}
