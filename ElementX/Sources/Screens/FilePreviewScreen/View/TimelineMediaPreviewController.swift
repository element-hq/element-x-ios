//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import QuickLook
import SwiftUI

class TimelineMediaPreviewController: QLPreviewController {
    private let context: TimelineMediaPreviewViewModel.Context
    
    private let headerHostingController: UIHostingController<HeaderView>
    private let detailsButtonHostingController: UIHostingController<DetailsButton>
    private let captionHostingController: UIHostingController<CaptionView>
    private let downloadIndicatorHostingController: UIHostingController<DownloadIndicatorView>
    private var detailsHostingController: UIHostingController<TimelineMediaPreviewDetailsView>?
    
    private var barButtonTimer: Timer?
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
        downloadIndicatorHostingController = UIHostingController(rootView: DownloadIndicatorView(context: context))
        downloadIndicatorHostingController.view.backgroundColor = .clear
        downloadIndicatorHostingController.sizingOptions = .intrinsicContentSize
        // Let swipes that start on the overlay reach the page scroll view underneath.
        downloadIndicatorHostingController.view.isUserInteractionEnabled = false
        
        super.init(nibName: nil, bundle: nil)
        
        view.addSubview(captionView)
        // Constraints added later as the toolbar isn't available yet.
        
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
        
        if topItem.leftBarButtonItem?.customView == nil {
            let button = UIBarButtonItem(customView: detailsButtonHostingController.view)
            navigationBar?.topItem?.leftBarButtonItem = button
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
    
    /// How long the user is kept on a "loading more" placeholder once items have arrived beyond it
    /// while a gap or undecryptable messages remain between (the data source's per-message wait).
    private static let placeholderHoldLimit: Duration = .seconds(TimelineMediaPreviewDataSource.pendingUTDWait)
    private var placeholderHoldStarted: ContinuousClock.Instant?
    private var placeholderHoldRecheckScheduled = false
    
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
        // Set once the clamp is actually taken: a merge whilst clamped re-runs this and restarting
        // the hold here left the user on "Loading more" indefinitely, which the bound exists to stop.
        placeholderHoldStarted = .now
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
        placeholderHoldStarted = nil
        MXLog.info("Media viewer: releasing the placeholder clamp")
        handleUpdatedItems()
    }
    
    /// A re-centre of the browse budget is waiting for the pages to stop moving.
    private var pendingBudgetRecentre = false
    
    /// Restores the phantom padding under a covered reload at the next rest, re-deriving the
    /// current item's index (a rebase shifts every index by the padding delta). Only from a
    /// settled media page: the "Loading more" stepping machinery owns the placeholder pages.
    private func recentreBrowseBudgetWhenResting() {
        pendingBudgetRecentre = true
        let index = currentPreviewItemIndex
        Task { [weak self] in
            guard let self, await waitUntilResting(atIndex: index), pendingBudgetRecentre else { return }
            pendingBudgetRecentre = false
            let dataSource = context.viewState.dataSource
            guard pendingMoveIndex == nil, dataSource.isBrowseBudgetLow,
                  let currentItemID = (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id else { return }
            dataSource.restoreBrowseBudget()
            guard let newIndex = dataSource.previewIndex(of: currentItemID) else { return }
            moveToIndexAndReload(newIndex)
            lastKnownItemCount = dataSource.numberOfPreviewItems(in: self)
            lastKnownFirstIndex = dataSource.firstPreviewItemIndex
        }
    }
    
    /// On a clamped "loading more" page whose items have arrived: step onto the newest of them
    /// (what the placeholder stood for), with the padding restored in the same reload. Returns
    /// whether it stepped, in which case the caller's own count bookkeeping is already done.
    private func steppedOffArrivedPlaceholder(_ dataSource: TimelineMediaPreviewDataSource) -> Bool {
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
            // The wait is bounded from when the user landed on the placeholder, not per undecryptable
            // message: a room full of them kept the user on "Loading more" for 13 s as each backfill
            // brought more (every one restarting the data source's wait) while the items that had
            // decrypted sat unreachable behind the clamp. Past the bound, step onto what has arrived;
            // what decrypts later is inserted behind as a reshuffle and rebuilt at rest, reachable.
            let heldFor = placeholderHoldStarted.map { ContinuousClock.now - $0 } ?? .zero
            if gapBetween, heldFor < Self.placeholderHoldLimit {
                MXLog.info("Media viewer: items arrived beyond the \(direction) placeholder but a gap or undecryptable messages remain between, waiting (held \(heldFor))")
                if !placeholderHoldRecheckScheduled {
                    placeholderHoldRecheckScheduled = true
                    Task { [weak self] in
                        try? await Task.sleep(for: Self.placeholderHoldLimit - heldFor + .milliseconds(50))
                        self?.placeholderHoldRecheckScheduled = false
                        guard let self, anchoredEdgeItemID != nil else { return }
                        handleUpdatedItems()
                    }
                }
            } else if stepped >= dataSource.firstPreviewItemIndex, stepped <= dataSource.lastPreviewItemIndex {
                if gapBetween {
                    MXLog.info("Media viewer: held on the \(direction) placeholder for \(heldFor), stepping past the undecryptable messages")
                }
                dataSource.isClampedToBackwardPlaceholder = false
                dataSource.isClampedToForwardPlaceholder = false
                anchoredEdgeItemID = nil
                placeholderHoldStarted = nil
                // Re-derived, not `stepped`: releasing the clamp above puts the phantom padding
                // back in place of the single placeholder page, shifting every index by it.
                if let edgeIndex = dataSource.previewIndex(of: edgeID) {
                    let target = direction == .backwards ? edgeIndex - 1 : edgeIndex + 1
                    MXLog.info("Media viewer: items arrived beyond the \(direction) placeholder, stepping to index \(target)")
                    moveToIndexAndReload(target)
                    lastKnownItemCount = dataSource.numberOfPreviewItems(in: self)
                    lastKnownFirstIndex = dataSource.firstPreviewItemIndex
                    return true
                }
            }
        }
        return false
    }
    
    private func handleUpdatedItems() {
        let dataSource = context.viewState.dataSource
        
        if steppedOffArrivedPlaceholder(dataSource) {
            return
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
            let newIndexDescription = newIndex.map(String.init) ?? "shift \(firstIndex - lastKnownFirstIndex)"
            MXLog.info("Media viewer: item count \(previousCount) -> \(count), first index \(lastKnownFirstIndex) -> \(firstIndex), current index \(currentPreviewItemIndex) -> \(newIndexDescription)")
            // On a placeholder page: follow the padding edge it belongs to, staying in range
            // (the placeholder vanishes when its side reaches the end: land on the edge item).
            let target = newIndex ?? min(max(currentPreviewItemIndex + firstIndex - lastKnownFirstIndex, 0), count - 1)
            moveToIndexAndReload(target)
        }
        lastKnownItemCount = count
        lastKnownFirstIndex = firstIndex
        
        // A pagination merge has nearly spent a side's browse budget: re-centre it at rest,
        // before the edge hardens into a false end of the timeline.
        if dataSource.isBrowseBudgetLow, !pendingBudgetRecentre {
            MXLog.info("Media viewer: browse budget low, re-centring when resting")
            recentreBrowseBudgetWhenResting()
        }
        
        guard let displayedItem = currentPreviewItem as? TimelineMediaPreviewItem.Loading else { return }
        
        // The index may now hold a media, or a different placeholder having reached the end of
        // the timeline, in which case what's on display is stale.
        if dataSource.previewController(self, previewItemAt: currentPreviewItemIndex) as AnyObject !== displayedItem {
            refreshCurrentPreviewItem() // This will trigger loadCurrentItem automatically.
        }
    }
    
    private func handleFileLoaded(itemID: MediaPreviewItemID) {
        guard (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id == itemID else { return }
        
        // There's a bug where refreshCurrentPreviewItem completely breaks the QLPreviewController
        // if it's called whilst swiping between items. So don't let that happen.
        if let scrollView = pageScrollView, scrollView.isDragging || scrollView.isDecelerating {
            return
        }
        
        refreshCurrentPreviewItem()
    }
    
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
                let isStill = !scrollView.isTracking && !scrollView.isDragging && !scrollView.isDecelerating && scrollView.contentOffset.x == restingOffset
                stillPolls = isStill ? stillPolls + 1 : 0
                restingOffset = scrollView.contentOffset.x
            } else {
                stillPolls += 1
            }
            if stillPolls >= 4 {
                return true
            }
            try? await Task.sleep(for: .milliseconds(50))
        }
        return false
    }
    
    /// The index a reload-then-set move is about to land on (see `moveToIndexAndReload`).
    private var pendingMoveIndex: Int?
    
    /// Moves QuickLook to `index` and reloads. QuickLook validates an index write against the
    /// count it last read, so an index beyond it (the count just grew: padding restored, items
    /// arrived) is set after the reload, not before (observed: the write silently dropped, the
    /// viewer left on the placeholder until the timeline's start).
    private func moveToIndexAndReload(_ index: Int) {
        if index < (lastKnownItemCount ?? 0) {
            currentPreviewItemIndex = index
            reloadData()
        } else {
            // Not in the same turn as the reload: QuickLook's page queue is left unable to page
            // either way (observed). Same remedy as returnToIndex; the reload cover hides the wait.
            pendingMoveIndex = index
            reloadData()
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
        if let item = currentPreviewItem as? TimelineMediaPreviewItem.Media {
            return "\(item.id)"
        }
        if let loading = currentPreviewItem as? TimelineMediaPreviewItem.Loading {
            return "\(loading.state)"
        }
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
    
    var body: some View {
        if let mediaItem = currentItem.mediaItem {
            VStack(spacing: 0) {
                Text(mediaItem.sender.displayName ?? mediaItem.sender.id)
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
        if let mediaItem = currentItem.mediaItem, mediaItem.hasCaption {
            CaptionScrollView(mediaItem: mediaItem)
                .transition(.move(edge: .bottom).combined(with: .opacity))
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
            } else if mediaItem.fileHandle == nil {
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
