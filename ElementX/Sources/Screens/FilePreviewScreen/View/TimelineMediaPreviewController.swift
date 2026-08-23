//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Combine
import Compound
import QuickLook
import SwiftUI

class TimelineMediaPreviewController: QLPreviewController {
    private let context: TimelineMediaPreviewViewModel.Context
    
    private let headerHostingController: UIHostingController<HeaderView>
    private let detailsButtonHostingController: UIHostingController<DetailsButton>
    private let captionHostingController: UIHostingController<CaptionView>
    private let progressBarHostingController: UIHostingController<ProgressBarView>
    private let downloadIndicatorHostingController: UIHostingController<DownloadIndicatorView>
    private var detailsHostingController: UIHostingController<TimelineMediaPreviewDetailsView>?
    
    private var barButtonTimer: Timer?
    /// The navigation item whose left button is being watched, and the watch itself.
    private var observedNavigationItem: UINavigationItem?
    private var leftBarButtonObservation: NSKeyValueObservation?
    
    private var pageScrollViewObservation: AnyCancellable?
    /// The content offset that the page scroll view rests at when showing the current item.
    private var pageScrollViewRestingOffset: CGFloat = 0
    
    private var cancellables: Set<AnyCancellable> = []
    
    private var navigationBar: UINavigationBar? {
        view.subviews.first?.subviews.first { $0 is UINavigationBar } as? UINavigationBar
    }
    
    private var bottomBarItemsContainer: UIView? {
        if #available(iOS 26, *) {
            view.subviews.first?.subviews.last?.subviews.first
        } else {
            view.subviews.first?.subviews.last { $0 is UIToolbar }
        }
    }
    
    private var pageScrollView: UIScrollView? {
        view.firstScrollView()
    }
    
    private var captionView: UIView {
        captionHostingController.view
    }
    
    override var overrideUserInterfaceStyle: UIUserInterfaceStyle {
        get { .dark }
        set { }
    }
    
    init(context: TimelineMediaPreviewViewModel.Context) {
        self.context = context
        
        headerHostingController = UIHostingController(rootView: HeaderView(context: context))
        headerHostingController.view.backgroundColor = .clear
        headerHostingController.sizingOptions = .intrinsicContentSize
        detailsButtonHostingController = UIHostingController(rootView: DetailsButton(context: context))
        detailsButtonHostingController.view.backgroundColor = .clear
        detailsButtonHostingController.sizingOptions = .intrinsicContentSize
        captionHostingController = UIHostingController(rootView: CaptionView(context: context))
        captionHostingController.view.backgroundColor = .clear
        captionHostingController.sizingOptions = .intrinsicContentSize
        progressBarHostingController = UIHostingController(rootView: ProgressBarView(context: context))
        progressBarHostingController.view.backgroundColor = .clear
        progressBarHostingController.view.isUserInteractionEnabled = false
        downloadIndicatorHostingController = UIHostingController(rootView: DownloadIndicatorView(context: context))
        downloadIndicatorHostingController.view.backgroundColor = .clear
        downloadIndicatorHostingController.sizingOptions = .intrinsicContentSize
        // Let swipes that start on the overlay reach the page scroll view underneath.
        downloadIndicatorHostingController.view.isUserInteractionEnabled = false
        
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(captionView)
        // Constraints added later as the toolbar isn't available yet.
        view.addSubview(progressBarHostingController.view) // Framed by hand along the content's bottom edge.
        
        view.addSubview(downloadIndicatorHostingController.view)
        downloadIndicatorHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            downloadIndicatorHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadIndicatorHostingController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        // Observation of currentPreviewItem doesn't work, so use the index instead.
        publisher(for: \.currentPreviewItemIndex)
            .sink { [weak self] index in
                // This isn't removing duplicates which may try to download and/or write to disk concurrently????
                MXLog.info("Media viewer: index \(index) -> \(self?.currentPreviewItemDescription ?? "nil")")
                self?.loadCurrentItem()
                self?.checkCurrentItemOnArrival()
            }
            .store(in: &cancellables)
        
        context.viewState.dataSource.previewItemsPaginationPublisher
            .sink { [weak self] in
                self?.handleUpdatedItems()
            }
            .store(in: &cancellables)
        
        context.viewState.previewControllerDriver
            .sink { [weak self] action in
                switch action {
                case .itemLoaded(let itemID):
                    self?.handleFileLoaded(itemID: itemID)
                case .showItemDetails(let mediaItem):
                    self?.presentMediaDetails(for: mediaItem)
                case .exportFile(let file):
                    self?.exportFile(file)
                case .authorizationRequired(let appMediator):
                    self?.presentAuthorizationRequiredAlert(appMediator: appMediator)
                case .dismissDetailsSheet:
                    self?.dismiss(animated: true)
                }
            }
            .store(in: &cancellables)
        
        dataSource = context.viewState.dataSource
        currentPreviewItemIndex = context.viewState.dataSource.initialItemIndex
        // The geometry QuickLook builds with, so the first count change already shifts the index
        // (the padding can collapse before the first items update, which used to slip through).
        lastKnownItemCount = context.viewState.dataSource.numberOfPreviewItems(in: self)
        lastKnownFirstIndex = context.viewState.dataSource.firstPreviewItemIndex
        recordBuiltBlankPages() // Seed the blank model from the initial (mostly file-less) build.
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let bottomBarItemsContainer {
            // Using the toolbar's visibility doesn't work so check its frame.
            captionView.isHidden = if #available(iOS 26, *) {
                navigationBar?.topItem?.leftBarButtonItem?.frame(in: view) == nil
            } else {
                bottomBarItemsContainer.frame.minY >= view.frame.maxY
            }
            
            if captionView.constraints.isEmpty {
                captionHostingController.view.translatesAutoresizingMaskIntoConstraints = false
                
                let bottomConstraint = if #available(iOS 26, *) {
                    captionView.bottomAnchor.constraint(equalTo: bottomBarItemsContainer.safeAreaLayoutGuide.bottomAnchor, constant: -50)
                } else {
                    captionView.bottomAnchor.constraint(equalTo: bottomBarItemsContainer.topAnchor)
                }
                
                NSLayoutConstraint.activate([
                    bottomConstraint,
                    captionView.leadingAnchor.constraint(equalTo: bottomBarItemsContainer.leadingAnchor),
                    captionView.trailingAnchor.constraint(equalTo: bottomBarItemsContainer.trailingAnchor)
                ])
            }
        }
        
        navigationBar?.topItem?.titleView = headerHostingController.view
        
        observePageScrollViewIfNeeded()
        
        updateBarButtons()
        layoutProgressBar()
        
        // Ridiculous hack to undo the controller's attempt to replace our info button with the list button.
        if barButtonTimer == nil {
            barButtonTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                // The timer is scheduled on the main run loop so it always fires on the main actor.
                MainActor.assumeIsolated {
                    self?.updateBarButtons()
                    // Also re-centers the overlay once the scroll view has settled on an item.
                    self?.updateOverlayPosition()
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        barButtonTimer?.invalidate()
        barButtonTimer = nil
    }
    
    private func updateBarButtons() {
        guard let topItem = navigationBar?.topItem else { return }
        
        // React to the controller re-installing its list button as it happens (KVO fires
        // synchronously in the setter, before the frame renders) rather than on the timer's
        // next tick, which left the list button visible for up to 100ms on every item refresh
        // (a "pulse" of the (i) icon). The timer stays as a fallback.
        if observedNavigationItem !== topItem {
            observedNavigationItem = topItem
            leftBarButtonObservation = topItem.observe(\.leftBarButtonItem) { [weak self] _, _ in
                MainActor.assumeIsolated { self?.updateBarButtons() }
            }
        }
        
        // The controller also swaps its navigation item (and with it our title view) on the same
        // refreshes, after which it shows the item's filename until the next layout pass; put the
        // sender/timestamp header back here, on the same trigger as the button.
        if topItem.titleView !== headerHostingController.view {
            topItem.titleView = headerHostingController.view
        }
        
        if topItem.leftBarButtonItem?.customView == nil {
            let button = UIBarButtonItem(customView: detailsButtonHostingController.view)
            // The controller re-installs its own button after every item refresh (e.g. once the
            // file has loaded), so this swap happens repeatedly; don't animate it back in each time.
            UIView.performWithoutAnimation {
                navigationBar?.topItem?.leftBarButtonItem = button
            }
        }
    }
    
    /// Makes the centered overlay (scan failure, download error/indicator) track the page scroll view
    /// when swiping between items, as it would otherwise float statically above the moving pages.
    private func observePageScrollViewIfNeeded() {
        guard pageScrollViewObservation == nil, let pageScrollView else { return }
        
        pageScrollViewObservation = pageScrollView.publisher(for: \.contentOffset)
            .sink { [weak self] _ in
                self?.updateOverlayPosition()
            }
    }
    
    private func updateOverlayPosition() {
        guard let pageScrollView, let overlayView = downloadIndicatorHostingController.view else { return }

        let pageWidth = pageScrollView.bounds.width
        guard pageWidth > 0 else { return }

        // Whilst resting on an item, keep track of the offset that any swipe will start from.
        if !pageScrollView.isDragging, !pageScrollView.isDecelerating {
            pageScrollViewRestingOffset = pageScrollView.contentOffset.x
        } else {
            removeReloadCover(animated: false) // Don't freeze the pages under a swipe.
        }

        let delta = pageScrollView.contentOffset.x - pageScrollViewRestingOffset

        // At the timeline ends QuickLook now bounces natively (the data source drops its phantom
        // padding once a side is fully paginated), so there's nothing to hard-block here; the
        // overlay just tracks whatever the scroll view does, bounce included.

        overlayView.transform = CGAffineTransform(translationX: -delta, y: 0)
        // Fade towards the midpoint so the overlay never clashes with the neighbouring item's state.
        overlayView.alpha = max(0, 1 - abs(delta) / (pageWidth / 2))
    }


    // MARK: Item loading

    private func loadCurrentItem() {
        headerHostingController.view.sizeToFit() // Resizing isn't automatic in the toolbar 😒
        
        // The clamp transitions set the index and reload; done from inside this index
        // observation QuickLook drops the index write (observed: the set logged as a no-op),
        // which toggled clamp/release forever. Defer them to the next run-loop turn. And while
        // a move is mid-flight (reload done, index set pending) the reload's own index callback
        // must not re-clamp the page being moved away from (observed: the move then dropped).
        // The page the reload of a move passes through isn't anyone's current item: handling it
        // (clamp, the "loading" state's spinner over the cover) is what the user saw as a spinner
        // over the previous media. The move's landing re-runs this.
        guard pendingMoveIndex == nil else { return }
        if let previewItem = currentPreviewItem as? TimelineMediaPreviewItem.Media {
            scheduleWhenResting { $0.releasePlaceholderClamp() }
            context.send(viewAction: .updateCurrentItem(.media(previewItem)))
        } else if let loadingItem = currentPreviewItem as? TimelineMediaPreviewItem.Loading {
            // A page QuickLook built as "loading more" whose index now holds a media (items the
            // padding absorbed since the build): rebuild it rather than treat it as the edge. Once
            // the pages have stopped moving: refreshing mid-swipe wedges QuickLook (the stuck
            // blank video), and a covered reload is what reliably rebuilds a page on device.
            if case .paginating = loadingItem.state,
               context.viewState.dataSource.previewController(self, previewItemAt: currentPreviewItemIndex) is TimelineMediaPreviewItem.Media {
                MXLog.info("Media viewer: stale placeholder page at index \(currentPreviewItemIndex), rebuilding when resting")
                let index = currentPreviewItemIndex
                Task { [weak self] in
                    guard await self?.waitUntilResting(atIndex: index) == true else { return }
                    self?.reloadDataTrackingBlanks()
                }
                return
            }
            switch loadingItem.state {
            case .paginating(let direction):
                scheduleWhenResting { $0.clampToPlaceholder(direction) }
                context.send(viewAction: .updateCurrentItem(.loading(loadingItem)))
            case .timelineStart:
                Task { await returnToIndex(context.viewState.dataSource.firstPreviewItemIndex) }
            case .timelineEnd:
                Task { await returnToIndex(context.viewState.dataSource.lastPreviewItemIndex) }
            }
        } else {
            MXLog.error("Unexpected preview item type: \(type(of: currentPreviewItem))")
        }
    }
    
    private func returnToIndex(_ index: Int) async {
        // Sleep to fix a bug where the update didn't take effect when the swipe velocity was slow.
        try? await Task.sleep(for: .seconds(0.1))
        
        currentPreviewItemIndex = index
    }
    
    /// The QuickLook item count and first-item index at the last update, tracked so we notice
    /// when a side's phantom padding collapses at end-reached (see the data source). Normal
    /// pagination keeps the count constant (the padding trick), so these change only at the two
    /// end transitions, when the items shift and QuickLook's cached count goes stale.
    private var lastKnownItemCount: Int?
    private var lastKnownFirstIndex = 0

    /// The loaded item at the edge the user paged off onto a "loading more" page, so that when
    /// its items arrive the viewer steps onto the newest of them (the page the placeholder stood for).
    private var anchoredEdgeItemID: MediaPreviewItemID?
    
    /// The user has paged onto a "loading more" placeholder: make it QuickLook's content edge on
    /// that side (one placeholder page, native bounce beyond it) rather than one of a hundred.
    /// Clamp transitions in the last second: a toggling loop (clamp, release, clamp…) is stopped
    /// rather than left to starve the main thread, whatever new way QuickLook finds to cause one.
    private var clampTransitionTimes = [ContinuousClock.Instant]()
    private func recordClampTransition() -> Bool {
        let now = ContinuousClock.now
        clampTransitionTimes = clampTransitionTimes.filter { now - $0 < .seconds(1) } + [now]
        if clampTransitionTimes.count > 4 {
            MXLog.error("Media viewer: placeholder clamp is toggling, leaving it alone")
            return false
        }
        return true
    }
    
    private func clampToPlaceholder(_ direction: PaginationDirection) {
        let dataSource = context.viewState.dataSource
        // Still on that placeholder? (Deferred from the index change; the pages may have moved on.)
        guard let placeholder = currentPreviewItem as? TimelineMediaPreviewItem.Loading,
              case .paginating(let current) = placeholder.state, current == direction,
              recordClampTransition() else { return }
        switch direction {
        case .backwards:
            guard !dataSource.isClampedToBackwardPlaceholder else { return }
            dataSource.isClampedToBackwardPlaceholder = true
            anchoredEdgeItemID = dataSource.previewItems.first?.id
        case .forwards:
            guard !dataSource.isClampedToForwardPlaceholder else { return }
            dataSource.isClampedToForwardPlaceholder = true
            anchoredEdgeItemID = dataSource.previewItems.last?.id
        }
        MXLog.info("Media viewer: clamping to the \(direction) placeholder page")
        handleUpdatedItems() // Count changed: the placeholder keeps its page, the count is re-read on reload.
    }
    
    /// Back on a media page: the padding returns so pagination keeps the indices stable again.
    private func releasePlaceholderClamp() {
        let dataSource = context.viewState.dataSource
        guard dataSource.isClampedToBackwardPlaceholder || dataSource.isClampedToForwardPlaceholder,
              currentPreviewItem is TimelineMediaPreviewItem.Media,
              recordClampTransition() else { return }
        dataSource.isClampedToBackwardPlaceholder = false
        dataSource.isClampedToForwardPlaceholder = false
        anchoredEdgeItemID = nil
        MXLog.info("Media viewer: releasing the placeholder clamp")
        handleUpdatedItems()
    }
    
    private func handleUpdatedItems() {
        let dataSource = context.viewState.dataSource
        
        // On a clamped "loading more" page whose items have arrived: step onto the newest of them
        // (what the placeholder stood for), with the padding restored in the same reload.
        if let edgeID = anchoredEdgeItemID,
           let placeholder = currentPreviewItem as? TimelineMediaPreviewItem.Loading,
           case .paginating(let direction) = placeholder.state,
           let edgeIndex = dataSource.previewIndex(of: edgeID) {
            let stepped = direction == .backwards ? edgeIndex - 1 : edgeIndex + 1
            // Only onto an item adjacent to the edge in the timeline: a backfill can land older
            // items first with a gap, or messages still waiting on their keys, between them and
            // the edge (stepping then skipped the ~20 items that filled in afterwards). Until that
            // resolves, stay on the placeholder.
            let olderID = direction == .backwards ? dataSource.mediaItem(atPreviewIndex: stepped)?.id : edgeID
            let gapBetween = olderID.map { dataSource.itemIDsWithGapOnNewerSide.contains($0) } ?? false
            if gapBetween {
                MXLog.info("Media viewer: items arrived beyond the \(direction) placeholder but a gap or undecryptable messages remain between, waiting")
            } else if stepped >= dataSource.firstPreviewItemIndex, stepped <= dataSource.lastPreviewItemIndex {
                dataSource.isClampedToBackwardPlaceholder = false
                dataSource.isClampedToForwardPlaceholder = false
                anchoredEdgeItemID = nil
                if let edgeIndex = dataSource.previewIndex(of: edgeID) {
                    let target = direction == .backwards ? edgeIndex - 1 : edgeIndex + 1
                    MXLog.info("Media viewer: items arrived beyond the \(direction) placeholder, stepping to index \(target)")
                    moveToIndexAndReload(target)
                    lastKnownItemCount = dataSource.numberOfPreviewItems(in: self)
                    lastKnownFirstIndex = dataSource.firstPreviewItemIndex
                    return
                }
            }
        }

        // When a side reaches the end of the timeline its phantom padding drops to zero so the
        // last real item becomes QuickLook's content edge (native bounce). That changes the
        // count and can move the current item's index; QuickLook only re-reads the count on
        // reloadData, so re-derive the current item's index from the data source and reload
        // just then. Re-derived, not shifted by the first index's change: a prepend the padding
        // absorbs moves the first index without moving any page (shifting by it opened the
        // viewer on an item ~N older than the one tapped).
        let count = dataSource.numberOfPreviewItems(in: self)
        let firstIndex = dataSource.firstPreviewItemIndex
        if let previousCount = lastKnownItemCount, previousCount != count {
            // QuickLook's own current item, or the item the viewer opens on before it has built.
            let currentItemID = currentPreviewItem == nil ? dataSource.currentItem.mediaItem?.id : (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id
            let newIndex = currentItemID.flatMap { dataSource.previewIndex(of: $0) }
            MXLog.info("Media viewer: item count \(previousCount) -> \(count), first index \(lastKnownFirstIndex) -> \(firstIndex), current index \(currentPreviewItemIndex) -> \(newIndex.map(String.init) ?? "shift \(firstIndex - lastKnownFirstIndex)")")
            // On a placeholder page: follow the padding edge it belongs to, staying in range
            // (the placeholder vanishes when its side reaches the end: land on the edge item).
            let target = newIndex ?? min(max(currentPreviewItemIndex + firstIndex - lastKnownFirstIndex, 0), count - 1)
            moveToIndexAndReload(target)
        }
        let reloaded = lastKnownItemCount != count
        lastKnownItemCount = count
        lastKnownFirstIndex = firstIndex
        
        // A reshuffle without a count change: the pages still need rebuilding (covered, at rest).
        if dataSource.needsRebuild {
            dataSource.needsRebuild = false
            if !reloaded {
                MXLog.info("Media viewer: items reshuffled, rebuilding the pages when resting")
                scheduleWhenResting { $0.reloadDataTrackingBlanks() }
            }
        }

        guard let displayedItem = currentPreviewItem as? TimelineMediaPreviewItem.Loading else { return }

        // The index may now hold a media, or a different placeholder having reached the end of
        // the timeline, in which case what's on display is stale.
        if dataSource.previewController(self, previewItemAt: currentPreviewItemIndex) as AnyObject !== displayedItem {
            refreshCurrentPreviewItem() // This will trigger loadCurrentItem automatically.
        }
    }
    
    /// How far from the current item QuickLook builds pages ahead (observed: the two either side).
    static let builtPagesRadius = 2
    
    /// The refresh checks in flight, one per item at most.
    private var refreshChecks = [MediaPreviewItemID: Task<Void, Never>]()
    /// The item last arrived at (index changed to another item), and whether its arrival check
    /// has already refreshed it: once per arrival, as a refresh re-fires the index and a page that
    /// never satisfies the check (a video's, say) would otherwise be refreshed forever.
    private var arrivalItemID: MediaPreviewItemID?
    private var didRefreshOnArrival = false
    
    /// Once settled on an item, QuickLook may be showing its "content unavailable" placeholder
    /// instead of the item (it does when swiped through quickly, whether or not the file was
    /// there when it built the page), and only a refresh clears it: check, and refresh if so.
    private func checkCurrentItemOnArrival() {
        guard let item = currentPreviewItem as? TimelineMediaPreviewItem.Media else { return }
        let itemID = item.id
        if itemID != arrivalItemID {
            arrivalItemID = itemID
            didRefreshOnArrival = false
        }
        // A page built from the thumbnail placeholder whose media has since arrived isn't
        // "unavailable" to QuickLook, so it's swapped explicitly.
        let upgrade = builtPlaceholderItemIDs.contains(itemID) && item.fileHandle != nil
        refreshIfUnavailableWhenResting(itemID: itemID, force: upgrade, upgrade: upgrade)
        // Also heal the page we're about to swipe into: while resting here, a built neighbour may be
        // showing QuickLook's blank placeholder with its file already present (its file arrived long
        // before we approached, so no file-load event re-checks it). Proactively reload once so the
        // next swipe lands on the media, not blank.
        scheduleHealReloadIfResting()
    }
    
    /// The item's file has just arrived: QuickLook built its page without it, so refresh it.
    private func handleFileLoaded(itemID: MediaPreviewItemID) {
        // A neighbour (not the current item) finished preloading: QuickLook may have built its
        // page blank before the file was ready, and only the current page can be refreshed, so
        // rebuild the built neighbourhood while resting. Without this the blank is only fixed once
        // you land on it (swipe into blank, then it pops in) rather than swiping into the media.
        guard (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id == itemID else {
            scheduleHealReloadIfResting()
            return
        }

        refreshIfUnavailableWhenResting(itemID: itemID, force: true, upgrade: builtPlaceholderItemIDs.contains(itemID))
    }

    /// A debounced reload used to rebuild QuickLook's pages when a neighbour finishes preloading
    /// whilst the user is resting, so pre-built blank pages become the media before the next swipe.
    /// Reload (not refresh) because QuickLook only refreshes the current page; the padding trick
    /// keeps the current item's index across it.
    ///
    /// No proximity guard: QuickLook does NOT only build the 2 pages either side. Its initial load
    /// (and every reloadData) builds a wide range of pages up front, so a page many items away can
    /// already be cached blank. Meanwhile preload delivers files several items ahead (reach grows
    /// to preloadReachAheadMax), so the file for a blank-built page routinely arrives while that
    /// page is well outside +/-2. Gating on builtPagesRadius skipped exactly those heals and left
    /// the page blank until the user landed on it (swipe into blank, then it pops in). Any preloaded
    /// neighbour arriving whilst resting is worth one debounced, resting-gated reload.
    private var neighbourReloadTask: Task<Void, Never>?
    /// The item the last heal reload fired on, so we reload at most once per rest. Keyed on the
    /// item (not the scroll offset: QuickLook reuses the same offset after a reload, so an offset
    /// key over-fired across different pages and suppressed legitimate heals).
    private var lastHealReloadItemID: MediaPreviewItemID?
    private func scheduleHealReloadIfResting() {
        neighbourReloadTask?.cancel()
        neighbourReloadTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(350)) // Coalesce a trickle of neighbour loads into one reload.
            guard let self, !Task.isCancelled,
                  let scrollView = pageScrollView, !scrollView.isDragging, !scrollView.isDecelerating else { return }
            // One reload per rest: a single reloadData rebuilds every page with whatever files are
            // present now, so later arrivals in the same rest need no further reload (they would just
            // re-flash the current page). Files that land after this reload heal on the next rest,
            // before the user can swipe to them.
            let currentItemID = (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id
            guard currentItemID != lastHealReloadItemID else { return }
            // Only reload if a built page is actually blank while its file is present: reload is
            // QuickLook's only re-read lever, so skip it when every built page already renders.
            guard let staleBlankDelta = healableBlankPageDelta() else { return }
            lastHealReloadItemID = currentItemID
            MXLog.info("Media viewer: healing a page built before its file arrived, \(staleBlankDelta) from the current item")
            reloadDataTrackingBlanks()
        }
    }
    
    /// Whether the page on display is QuickLook's "content unavailable" placeholder.
    /// DIAG: existence and size of the file behind a preview item (strip pre-upstream).
    private static func fileDiagnostics(_ url: URL?) -> String {
        guard let url else { return "no URL" }
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        let size = (attributes?[.size] as? NSNumber)?.intValue
        return "\(url.lastPathComponent) \(size.map { "\($0) bytes" } ?? "MISSING")"
    }
    
    private var isCurrentPageUnavailable: Bool {
        let center = CGPoint(x: view.bounds.midX, y: view.bounds.midY)
        return view.firstDescendant { subview in
            String(describing: type(of: subview)).contains("ContentUnavailable")
                && !subview.isHidden && subview.alpha > 0 && subview.window != nil
                && subview.convert(subview.bounds, to: view).contains(center)
        } != nil
    }
    
    /// The items QuickLook has built into pages while their file was absent, so it is caching a blank
    /// "content unavailable" page for them. QuickLook never re-reads such a page on its own, and it
    /// does NOT keep the blank neighbour's view in the hierarchy while offscreen (so it can't be found
    /// by inspecting subviews) - the only signal we have is the file state at build time, which we
    /// model here. Recomputed from actual file state after every (re)build; an item leaves the set
    /// only when a reload rebuilds it with its file present.
    private var builtBlankItemIDs = Set<MediaPreviewItemID>()
    
    /// The items whose page QuickLook built from the thumbnail placeholder (media absent at build
    /// time). Once the media arrives the page needs rebuilding, as a blank one does, but QuickLook
    /// doesn't consider it unavailable, so it's tracked separately and swapped explicitly.
    private var builtPlaceholderItemIDs = Set<MediaPreviewItemID>()

    /// Snapshot which built pages are blank, from the data source's current file state. Called after
    /// every build/reload: QuickLook (re)builds its pages from the files present at that instant, so
    /// items still missing a file are blank and items that now have one have been rebuilt correctly.
    private func recordBuiltBlankPages() {
        let items = context.viewState.dataSource.previewItems
        builtBlankItemIDs = Set(items.filter { $0.previewItemURL == nil }.map(\.id))
        builtPlaceholderItemIDs = Set(items.filter(\.isShowingPlaceholder).map(\.id))
    }

    /// reloadData plus a blank-set refresh, so every rebuild keeps the model in sync. `covered`
    /// hides the rebuild behind a snapshot; pass false when the page on display is blank anyway
    /// (a snapshot of it would only delay the media the reload brings in).
    private func reloadDataTrackingBlanks(covered: Bool = true) {
        MXLog.info("Media viewer: reloadData (covered: \(covered)) at index \(currentPreviewItemIndex) of \(context.viewState.dataSource.numberOfPreviewItems(in: self)), \(currentPreviewItemDescription)")
        if covered {
            coverReload { reloadData() }
        } else {
            reloadData()
        }
        recordBuiltBlankPages()
    }
    
    /// The longest the cover stays up if the rebuilt page's arrival can't be detected (a page
    /// type without a recognised content view, say).
    private static let reloadCoverTimeout: Duration = .seconds(1)
    private var reloadCoverView: UIView?
    
    /// Hides the flash reloadData causes (QuickLook rebuilds every page, the current one
    /// included): freeze a snapshot of the pages over the page scroll view (below the bars, so
    /// their glass keeps animating), reload underneath, and drop the snapshot the moment the
    /// rebuilt page has content again. QuickLook empties the current page synchronously and
    /// repopulates it ~20ms (image) to ~100ms (video) later, so the signal is a new content
    /// view under the centre of the screen.
    /// `completion` says whether the rebuilt page was detected.
    private func coverReload(_ reload: () -> Void, completion: ((Bool) -> Void)? = nil) {
        reloadCoverView?.removeFromSuperview()
        let previousContent = renderedPageContentView
        let previousImage = (previousContent as? UIImageView)?.image
        if let pageScrollView, let snapshot = pageScrollView.snapshotView(afterScreenUpdates: false) {
            snapshot.frame = pageScrollView.frame
            snapshot.isUserInteractionEnabled = false
            pageScrollView.superview?.insertSubview(snapshot, aboveSubview: pageScrollView)
            reloadCoverView = snapshot
        }
        reload()
        Task { [weak self] in
            let started = ContinuousClock.now
            var rendered = false
            while let self, reloadCoverView != nil, ContinuousClock.now - started < Self.reloadCoverTimeout {
                if let content = renderedPageContentView,
                   content !== previousContent || (content as? UIImageView)?.image !== previousImage {
                    rendered = true
                    break
                }
                try? await Task.sleep(for: .milliseconds(16))
            }
            MXLog.info("Media viewer: reload cover down after \(ContinuousClock.now - started), rebuilt page \(rendered ? "rendered" : "not detected")")
            self?.removeReloadCover(animated: false)
            completion?(rendered)
        }
    }
    
    private static let progressBarHeight: CGFloat = 3
    
    /// Puts the download bar along the very bottom edge of the screen (tracking the content's edge
    /// fell apart once the placeholder was pinched/zoomed).
    private func layoutProgressBar() {
        let height = Self.progressBarHeight
        progressBarHostingController.view.frame = CGRect(x: 0, y: view.bounds.maxY - height, width: view.bounds.width, height: height)
    }
    
    /// The view QuickLook is rendering the current page's content with (an image view showing
    /// an image, or a video layer ready for display), or nil while the page is being (re)built.
    /// The page containers are the plain UIViews directly inside the page scroll view.
    private var renderedPageContentView: UIView? {
        guard let pageScrollView else { return nil }
        let center = view.convert(CGPoint(x: view.bounds.midX, y: view.bounds.midY), to: pageScrollView)
        guard let page = pageScrollView.subviews.first(where: { type(of: $0) == UIView.self && $0.frame.contains(center) }) else { return nil }
        return page.firstVisibleDescendant { subview in
            if let imageView = subview as? UIImageView { return imageView.image != nil }
            if let playerLayer = subview.layer as? AVPlayerLayer { return playerLayer.isReadyForDisplay }
            return false
        }
    }
    
    private func removeReloadCover(animated: Bool) {
        guard let cover = reloadCoverView else { return }
        reloadCoverView = nil
        UIView.animate(withDuration: animated ? 0.15 : 0) {
            cover.alpha = 0
        } completion: { _ in
            cover.removeFromSuperview()
        }
    }

    /// The offset from the current item of a page within QuickLook's build radius that it built
    /// blank and whose file has since arrived - a stale blank a reload would heal - or nil if
    /// there's none. Reloading only for these (not on every rest) keeps the rebuild to the rare
    /// pages that actually need it.
    private func healableBlankPageDelta() -> Int? {
        let dataSource = context.viewState.dataSource
        let firstIndex = dataSource.firstPreviewItemIndex
        for delta in -Self.builtPagesRadius...Self.builtPagesRadius {
            let arrayIndex = currentPreviewItemIndex + delta - firstIndex
            guard dataSource.previewItems.indices.contains(arrayIndex) else { continue }
            let item = dataSource.previewItems[arrayIndex]
            let healable = builtBlankItemIDs.contains(item.id) ? item.previewItemURL != nil
                : builtPlaceholderItemIDs.contains(item.id) && item.fileHandle != nil
            if healable {
                return delta
            }
        }
        return nil
    }

    private func refreshIfUnavailableWhenResting(itemID: MediaPreviewItemID, force: Bool, upgrade: Bool = false) {
        guard refreshChecks[itemID] == nil else { return }
        refreshChecks[itemID] = Task { [weak self] in
            await self?.refreshIfUnavailableWhenResting(itemID: itemID, force: force, upgrade: upgrade)
            self?.refreshChecks[itemID] = nil
        }
    }

    /// Refreshes the current item once it's `itemID`, the pages have stopped moving, its file is
    /// there and QuickLook is showing the placeholder instead of it. `force` bypasses the
    /// once-per-arrival limit (for a file that has just arrived). `upgrade` swaps a page built
    /// from the thumbnail placeholder for the media regardless of availability.
    private func refreshIfUnavailableWhenResting(itemID: MediaPreviewItemID, force: Bool, upgrade: Bool) async {
        // There's a bug where refreshCurrentPreviewItem completely breaks the QLPreviewController
        // if it's called whilst swiping between items. So wait for the swipe to settle (the index
        // changes whilst the pages are still decelerating).
        // Resting = not dragging or decelerating, and the offset unchanged for a few polls: the
        // snap to a page after a flick is QuickLook's own animation, invisible to those flags.
        var restingOffset: CGFloat?
        var stillPolls = 0
        for _ in 0..<60 {
            guard let item = currentPreviewItem as? TimelineMediaPreviewItem.Media, item.id == itemID else {
                return // Swiped on: its next arrival checks it again.
            }
            guard item.previewItemURL != nil else { return } // Its load will refresh it.
            if let scrollView = pageScrollView {
                let isStill = !scrollView.isDragging && !scrollView.isDecelerating && scrollView.contentOffset.x == restingOffset
                stillPolls = isStill ? stillPolls + 1 : 0
                restingOffset = scrollView.contentOffset.x
            } else {
                stillPolls += 1
            }
            if stillPolls >= 4 {
                if upgrade {
                    upgradePlaceholderPage(itemID: itemID)
                    return
                }
                guard isCurrentPageUnavailable else { return }
                // DIAG: "copy to preview" pages seen on device for items with a file. Says whether the
                // file QuickLook was handed exists and how big it is, and whether we already reloaded
                // for it (a second unavailable after a reload = the file itself, not a stale page).
                MXLog.info("Media viewer: unavailable page for \(itemID): \(Self.fileDiagnostics(item.previewItemURL)), already reloaded on arrival: \(didRefreshOnArrival), forced: \(force)")
                guard force || !didRefreshOnArrival else { return }
                if itemID == arrivalItemID {
                    didRefreshOnArrival = true
                }
                // reloadData rather than refreshCurrentPreviewItem: the latter reliably fails to
                // clear QuickLook's pre-built "content unavailable" placeholder for the item the
                // user rests on (observed on device), leaving it blank. reloadData rebuilds the
                // pages so the now-present file renders; the padding trick keeps the current index.
                // Uncovered: the page is blank, a snapshot of it would only delay the media.
                MXLog.info("Media viewer: landed on a blank page for \(itemID), reloading")
                reloadDataTrackingBlanks(covered: false)
                return
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
    }
    
    /// The current page was built from the thumbnail placeholder and the media has arrived: refresh
    /// the page so QuickLook re-reads the item (now the file). Verified, as QuickLook's refresh is
    /// not always honoured on device: if the page's content hasn't changed shortly after, every
    /// page is rebuilt behind a cover instead.
    private func upgradePlaceholderPage(itemID: MediaPreviewItemID) {
        builtPlaceholderItemIDs.remove(itemID)
        MXLog.info("Media viewer: swapping the placeholder for the media of \(itemID)")
        // Under a page cover: the refresh flashes the page black, so the thumbnail stays up until the
        // media has rendered. The bars are left uncovered: their buttons re-animating is the cue
        // that the media has arrived.
        coverReload {
            refreshCurrentPreviewItem()
        } completion: { [weak self] rendered in
            guard let self else { return }
            if rendered {
                MXLog.info("Media viewer: placeholder swapped")
                // The user has sat through the download looking at the poster: start a video rather
                // than asking for another tap.
                if let playerLayer = renderedPageContentView?.layer as? AVPlayerLayer, let player = playerLayer.player {
                    MXLog.info("Media viewer: autoplaying the swapped-in video")
                    player.play()
                }
            } else if (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id == itemID {
                MXLog.info("Media viewer: placeholder swap not detected for \(itemID), reloading")
                reloadDataTrackingBlanks()
            }
        }
    }
    
    /// Moves QuickLook to `index` and reloads. QuickLook validates an index write against the
    /// count it last read, so an index beyond it (the count just grew: padding restored, items
    /// arrived) is set after the reload, not before (observed: the write silently dropped, the
    /// viewer left on the placeholder until the timeline's start).
    /// Runs `action` once the pages have stopped moving, if the user is still on this page by then.
    /// The clamp transitions reload; a reload while QuickLook is still decelerating wedges it
    /// (half-scrolled page, stale title, the transit page's spinner: observed on release).
    private func scheduleWhenResting(_ action: @escaping (TimelineMediaPreviewController) -> Void) {
        let index = currentPreviewItemIndex
        Task { [weak self] in
            guard let self, await waitUntilResting(atIndex: index) else { return }
            action(self)
        }
    }
    
    /// Waits until the pages have stopped moving while still on `index` (same test as the arrival
    /// check: not dragging or decelerating, offset unchanged for a few polls). False if swiped on.
    private func waitUntilResting(atIndex index: Int) async -> Bool {
        var restingOffset: CGFloat?
        var stillPolls = 0
        for _ in 0..<60 {
            guard currentPreviewItemIndex == index else { return false }
            if let scrollView = pageScrollView {
                let isStill = !scrollView.isDragging && !scrollView.isDecelerating && scrollView.contentOffset.x == restingOffset
                stillPolls = isStill ? stillPolls + 1 : 0
                restingOffset = scrollView.contentOffset.x
            } else {
                stillPolls += 1
            }
            if stillPolls >= 4 { return true }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return false
    }
    
    /// The index a reload-then-set move is about to land on (see `moveToIndexAndReload`).
    private var pendingMoveIndex: Int?
    
    private func moveToIndexAndReload(_ index: Int) {
        if index < (lastKnownItemCount ?? 0) {
            currentPreviewItemIndex = index
            reloadDataTrackingBlanks()
        } else {
            // Not in the same turn as the reload: QuickLook's page queue is left unable to page
            // either way (observed). Same remedy as returnToIndex; the reload cover hides the wait.
            pendingMoveIndex = index
            reloadDataTrackingBlanks()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                guard let self else { return }
                MXLog.info("Media viewer: moving to index \(index) after the reload")
                currentPreviewItemIndex = index
                pendingMoveIndex = nil
                // The landing page's own handling (clamp/release) was skipped while moving; redo it.
                loadCurrentItem()
            }
        }
    }
    
    /// The current item, for the logs: its event ID, or the placeholder kind.
    private var currentPreviewItemDescription: String {
        if let item = currentPreviewItem as? TimelineMediaPreviewItem.Media { return "\(item.id)" }
        if let loading = currentPreviewItem as? TimelineMediaPreviewItem.Loading { return "\(loading.state)" }
        return "nil"
    }
    
    // MARK: - Actions
    
    private func presentMediaDetails(for mediaItem: TimelineMediaPreviewItem.Media) {
        let safeArea = view.safeAreaInsets.bottom
        let sheetHeightBinding = Binding { safeArea } set: { [weak self] newValue, _ in
            self?.detailsHostingController?.sheetPresentationController?.detents = [.height(newValue)]
        }
        
        let hostingController = UIHostingController(rootView: TimelineMediaPreviewDetailsView(item: mediaItem,
                                                                                              context: context,
                                                                                              sheetHeight: sheetHeightBinding))
        hostingController.view.backgroundColor = .compound.bgCanvasDefault
        hostingController.overrideUserInterfaceStyle = .dark
        hostingController.sheetPresentationController?.detents = [.height(safeArea)]
        hostingController.sheetPresentationController?.prefersGrabberVisible = true
        
        present(hostingController, animated: true)
        
        detailsHostingController = hostingController
    }
    
    private func exportFile(_ file: TimelineMediaPreviewFileExportPicker.File) {
        let hostingController = UIHostingController(rootView: TimelineMediaPreviewFileExportPicker(file: file))
        present(hostingController, animated: true)
    }
    
    private func presentAuthorizationRequiredAlert(appMediator: AppMediatorProtocol) {
        let alertController = UIAlertController(title: L10n.dialogPermissionPhotoLibraryTitleIos(InfoPlistReader.main.bundleDisplayName),
                                                message: nil,
                                                preferredStyle: .alert)
        alertController.addAction(.init(title: L10n.commonSettings, style: .default) { _ in appMediator.openAppSettings() })
        alertController.addAction(.init(title: L10n.actionCancel, style: .cancel))
        
        present(alertController, animated: true)
    }
}

// MARK: - Subviews

private struct HeaderView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    private var currentItem: TimelineMediaPreviewItem {
        context.viewState.currentItem
    }
    
    /// The sender (or "Loading…" over a thumbnail placeholder), with the attachment's place in its
    /// gallery appended, e.g. "Alice (2 of 3)", now that galleries are browsed inline with other media.
    private func headerTitle(for mediaItem: TimelineMediaPreviewItem.Media) -> String {
        let title = mediaItem.isShowingPlaceholder ? L10n.commonLoading : mediaItem.sender.displayName ?? mediaItem.sender.id
        guard let position = mediaItem.galleryPosition else { return title }
        return "\(title) (\(L10n.screenRoomPinnedBannerIndicator(String(position.index), String(position.count))))"
    }
    
    var body: some View {
        if let mediaItem = currentItem.mediaItem {
            VStack(spacing: 0) {
                Text(headerTitle(for: mediaItem))
                    .font(.compound.bodySMSemibold)
                    .foregroundStyle(.compound.textPrimary)
                Text(mediaItem.timestamp.formatted(date: .abbreviated, time: .omitted))
                    .font(.compound.bodyXS)
                    .foregroundStyle(.compound.textPrimary)
                    .textCase(.uppercase)
            }
            .fixedSize(horizontal: true, vertical: false)
        } else {
            Text(L10n.commonLoadingMore)
                .font(.compound.bodySMSemibold)
                .foregroundStyle(.compound.textPrimary)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

private struct DetailsButton: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    private var currentItem: TimelineMediaPreviewItem {
        context.viewState.currentItem
    }
    
    var body: some View {
        if let mediaItem = currentItem.mediaItem {
            Button { context.send(viewAction: .showItemDetails(mediaItem)) } label: {
                CompoundIcon(\.info)
            }
        }
    }
}

private struct CaptionView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    private var currentItem: TimelineMediaPreviewItem {
        context.viewState.currentItem
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if let mediaItem = currentItem.mediaItem, mediaItem.hasCaption {
                CaptionScrollView(mediaItem: mediaItem)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }
}

/// The download's progress bar; the controller frames it along the bottom edge of the page's
/// content (the header says it's loading, the bar how far).
private struct ProgressBarView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    
    var body: some View {
        if let mediaItem = context.viewState.currentItem.mediaItem, mediaItem.fileHandle == nil {
            MediaProgressBar(progress: mediaItem.downloadProgress)
        }
    }
}

private struct CaptionScrollView: View {
    private let maxHeight: CGFloat = 120
    
    let mediaItem: TimelineMediaPreviewItem.Media
    
    @State private var shouldShowFade = false
    
    var body: some View {
        ScrollView(.vertical) {
            captionContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
        }
        .onScrollGeometryChange(for: Bool.self) { geometry in
            geometry.contentOffset.y >= geometry.contentSize.height - geometry.containerSize.height - geometry.contentInsets.bottom
        } action: { _, isBottomVisible in
            if shouldShowFade == isBottomVisible {
                withAnimation(.elementDefault) { shouldShowFade = !isBottomVisible }
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .frame(maxHeight: maxHeight)
        .overlay(alignment: .bottom) {
            if shouldShowFade {
                LinearGradient(stops: [.init(color: .clear, location: 0.0),
                                       .init(color: .black.opacity(0.5), location: 1.0)],
                               startPoint: .top,
                               endPoint: .bottom)
                    .frame(height: 40)
            }
        }
        .background {
            BlurEffectView(style: .systemChromeMaterial)
                .ignoresSafeArea()
        }
    }
    
    @ViewBuilder
    private var captionContent: some View {
        if let formattedCaption = mediaItem.formattedCaption {
            FormattedBodyText(attributedString: formattedCaption)
        } else if let caption = mediaItem.caption {
            FormattedBodyText(text: caption)
        }
    }
}

private struct DownloadIndicatorView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    private var currentItem: TimelineMediaPreviewItem {
        context.viewState.currentItem
    }
    
    var body: some View {
        switch currentItem {
        case .media(let mediaItem):
            if mediaItem.downloadError != nil {
                downloadErrorView
            } else if mediaItem.fileHandle == nil,
                      mediaItem.placeholderURL == nil && mediaItem.downloadProgress == nil || mediaItem.downloadProgress == 1 {
                // The placeholder's title says it's loading, the progress bar shows how far. Once every
                // byte is in, the SDK still decrypts and stores the file (6 s for a 90 MB video), so the
                // spinner says something is happening while the bar sits at 100 %.
                loadingIndicator(isScanning: false)
            }
        case .contentScan(let scan):
            switch scan.state {
            case .scanning:
                loadingIndicator(isScanning: true)
            case .failure(let failure):
                TimelineMediaContentScanningFailureView(failure: failure)
            }
        case .loading(.paginatingBackwards), .loading(.paginatingForwards):
            loadingIndicator(isScanning: false)
        case .loading:
            EmptyView()
        }
    }
    
    private var downloadErrorView: some View {
        VStack(spacing: 24) {
            CompoundIcon(\.errorSolid, size: .custom(48), relativeTo: .compound.headingLG)
                .foregroundStyle(.compound.iconCriticalPrimary)
                .padding(.vertical, 24.5)
                .padding(.horizontal, 28.5)
            
            VStack(spacing: 2) {
                Text(L10n.commonDownloadFailed)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.screenMediaBrowserDownloadErrorMessage)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 40)
        .background(.compound.bgSubtlePrimary, in: RoundedRectangle(cornerRadius: 14))
    }
    
    private func loadingIndicator(isScanning: Bool) -> some View {
        VStack(spacing: 32) {
            ProgressView()
                .controlSize(.large)
                .tint(.compound.iconPrimary)
            
            if isScanning {
                Text(L10n.contentScannerScanning)
                    .font(.compound.bodyLGSemibold)
                    .foregroundStyle(.compound.textPrimary)
            }
        }
    }
}

// MARK: - Helpers

private extension UIView {
    func firstDescendant(where predicate: (UIView) -> Bool) -> UIView? {
        for view in subviews {
            if predicate(view) {
                return view
            }
            if let match = view.firstDescendant(where: predicate) {
                return match
            }
        }
        return nil
    }

    
    /// Like `firstDescendant`, skipping hidden/transparent subtrees.
    func firstVisibleDescendant(where predicate: (UIView) -> Bool) -> UIView? {
        for view in subviews where !view.isHidden && view.alpha > 0 {
            if predicate(view) {
                return view
            }
            if let match = view.firstVisibleDescendant(where: predicate) {
                return match
            }
        }
        return nil
    }
    
    func firstScrollView() -> UIScrollView? {
        for view in subviews {
            if let scrollView = view as? UIScrollView ?? view.firstScrollView() {
                return scrollView
            }
        }
        return nil
    }
}

private extension UISheetPresentationController.Detent {
    static func height(_ height: CGFloat) -> UISheetPresentationController.Detent {
        .custom { _ in height }
    }
}
