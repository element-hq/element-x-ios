//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

typealias TimelineMediaPreviewViewModelType = StateStoreViewModel<TimelineMediaPreviewViewState, TimelineMediaPreviewViewAction>

class TimelineMediaPreviewViewModel: TimelineMediaPreviewViewModelType {
    static let displayMessageForwardingDelay: TimeInterval = 1.0
    
    let instanceID = UUID()
    
    private let timelineViewModel: TimelineViewModelProtocol
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
    init(initialItem: EventBasedMessageTimelineItemProtocol,
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
                                                                                     paginationState: timelineState.paginationState,
                                                                                     allowedGalleryItemTypes: timelineViewModel.context.viewState.allowedGalleryItemTypes)),
                   mediaProvider: mediaProvider)
        
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
    
    /// Initialises the preview scoped to a single gallery's attachments. The data source is
    /// built from the gallery's items directly and isn't kept in sync with the underlying
    /// timeline — gallery contents don't change without the event being replaced or redacted.
    init(galleryItem: GalleryRoomTimelineItem,
         initialIndex: Int,
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
        
        super.init(initialViewState: TimelineMediaPreviewViewState(dataSource: .init(galleryItem: galleryItem,
                                                                                     initialIndex: initialIndex)),
                   mediaProvider: mediaProvider)
        
        rebuildCurrentItemActions()
        
        timelineViewModel.context.$viewState.map(\.canCurrentUserRedactSelf)
            .merge(with: timelineViewModel.context.$viewState.map(\.canCurrentUserRedactOthers))
            .sink { [weak self] _ in self?.rebuildCurrentItemActions() }
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
        setCurrentItem(previewItem)
        
        if case let .media(mediaItem) = previewItem {
            defer {
                preloadNeighbours(of: mediaItem)
                prefetchTimelinePaginationIfNeeded(around: mediaItem)
            }
            
            MXLog.info("PreviewDebug: current item \(mediaItem.id), file \(mediaItem.fileHandle == nil ? "missing" : "present"), preload \(preloads[mediaItem.id] == nil ? "none" : "in flight")")
            guard mediaItem.fileHandle == nil, let source = mediaItem.mediaSource else { return }
            
            guard await checkSourceIsSafeIfNeeded(for: mediaItem, source: source) else { return }
            
            // Join a preload already in flight for this item rather than downloading it a second time.
            let result = if let preload = preloads[mediaItem.id] {
                await preload.value
            } else {
                await mediaProvider.loadFileFromSource(source, filename: mediaItem.filename)
            }
            preloads[mediaItem.id] = nil
            
            switch result {
            case .success(let handle):
                MXLog.info("PreviewDebug: loaded \(mediaItem.id)")
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

    /// The thumbnail loads in flight, one per item at most.
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

        if index <= Self.paginationPrefetchDistance, state.dataSource.paginationState.backward == .idle {
            timelineViewModel.context.send(viewAction: .paginateBackwards)
        }
        if index >= items.count - 1 - Self.paginationPrefetchDistance, state.dataSource.paginationState.forward == .idle {
            timelineViewModel.context.send(viewAction: .paginateForwards)
        }
    }
    
    /// How many media on either side of the current one to fetch ahead. QuickLook only builds
    /// its pages (`builtPagesRadius`) as it settles on an item, so with a shallow reach a quick
    /// swipe outruns the downloads and lands on an empty page until the file arrives. Reaching
    /// well beyond the built pages keeps files ready ahead of the swipe. Tunable on feel; each
    /// unit is one extra concurrent download in each direction (small files only, deduped).
    private static let neighbourPreloadReach = 8

    /// Fetches the media around the current one so that a swipe reveals the media itself rather
    /// than an empty page: QuickLook builds the pages around the current one as it settles on it,
    /// so an item needs its file by the time it comes within that reach. Nearest first, small
    /// files only, and skipped when a content scanner is configured (a neighbour must be scanned
    /// as the current item is, on display).
    ///
    /// The neighbour gets its file handle straight away; the controller refreshes any page that
    /// QuickLook shows as unavailable on arrival.
    private func preloadNeighbours(of mediaItem: TimelineMediaPreviewItem.Media) {
        guard appSettings.preloadMediaInViewer, contentScannerService == nil else { return }

        let items = state.dataSource.previewItems
        guard let index = items.firstIndex(where: { $0.id == mediaItem.id }) else { return }

        // Nearest neighbours first (1, 1, 2, 2, …): they're the most urgent and get their
        // download slot before the further-ahead ones.
        let neighbourIndices = (1...Self.neighbourPreloadReach)
            .flatMap { [index - $0, index + $0] }
            .filter { items.indices.contains($0) }
        for neighbourIndex in neighbourIndices {
            let neighbour = items[neighbourIndex]
            guard neighbour.fileHandle == nil,
                  neighbour.downloadError == nil,
                  preloads[neighbour.id] == nil,
                  let source = neighbour.mediaSource,
                  neighbour.fileSize.map({ $0 <= Self.preloadFileSizeLimit }) ?? true else { continue }
            
            let neighbourID = neighbour.id
            preloads[neighbourID] = Task { [mediaProvider] in
                // Failures aren't recorded here: the load on display retries and reports them.
                let result = await mediaProvider.loadFileFromSource(source, filename: neighbour.filename)
                preloads[neighbourID] = nil
                if case .success(let handle) = result, neighbour.fileHandle == nil {
                    MXLog.info("PreviewDebug: preloaded \(neighbourID)")
                    neighbour.fileHandle = handle
                }
                return result
            }
        }
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
    
    private func paginateIfNeeded() {
        switch state.currentItem {
        case .loading(.paginatingBackwards):
            if state.dataSource.paginationState.backward == .idle {
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
