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
    
    /// When not nil, the given item will have its caption hidden.
    private var captionHiddenForItemID: MediaPreviewItemID?
    
    @CancellableTask private var settledRefreshTask: Task<Void, Never>?
    /// Media whose file loaded, kept until the swipe settles as each load is only reported once.
    /// Whichever is on display by then gets refreshed and the rest are dropped.
    private var itemIDsAwaitingRefresh: Set<MediaPreviewItemID> = []
    
    private var pageScrollViewObservation: AnyCancellable?
    /// The content offset that the page scroll view rests at when showing the current item.
    private var pageScrollViewRestingOffset: CGFloat = 0
    
    private let dismissGestureRecognizer = UIPanGestureRecognizer()
    private let dismissGestureDelegate = EmptyItemDismissGestureDelegate()
    /// The dismissal driven by the dismiss gesture, from the moment it starts until it has settled.
    private var interactiveDismissal: InteractiveDismissal?
    
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
    
    /// Whether the pages are being touched or are still moving, including a touch that hasn't started dragging yet.
    private var isSwiping: Bool {
        guard let pageScrollView else { return false }
        return pageScrollView.isTracking || pageScrollView.isDragging || pageScrollView.isDecelerating
    }
    
    private var captionView: UIView {
        captionHostingController.view
    }
    
    private var currentPreviewItemMediaID: MediaPreviewItemID? {
        (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id
    }
    
    /// Whether the displayed placeholder's index now holds a media, or a different placeholder
    /// having reached the end of the timeline, in which case what's on display is stale.
    private var isDisplayedPlaceholderStale: Bool {
        guard let displayedItem = currentPreviewItem as? TimelineMediaPreviewItem.Loading else { return false }
        let dataSource = context.viewState.dataSource
        return dataSource.previewController(self, previewItemAt: currentPreviewItemIndex) as AnyObject !== displayedItem
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
        
        headerHostingController.rootView.onMoveToWindow = { [weak self] in
            guard #available(iOS 26, *) else { return }
            self?.updateCaptionVisibility()
        }
        
        view.addSubview(captionView)
        // Constraints added later as the toolbar isn't available yet.
        
        view.addSubview(downloadIndicatorHostingController.view)
        downloadIndicatorHostingController.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            downloadIndicatorHostingController.view.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            downloadIndicatorHostingController.view.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        dismissGestureDelegate.previewController = self
        dismissGestureDelegate.captionView = captionView
        dismissGestureRecognizer.delegate = dismissGestureDelegate
        dismissGestureRecognizer.addTarget(self, action: #selector(handleDismissGesture))
        view.addGestureRecognizer(dismissGestureRecognizer)
        
        // Observation of currentPreviewItem doesn't work, so use the index instead.
        publisher(for: \.currentPreviewItemIndex)
            .sink { [weak self] _ in
                // This isn't removing duplicates which may try to download and/or write to disk concurrently????
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
                case .dismissPreview:
                    self?.presentingViewController?.dismiss(animated: false)
                }
            }
            .store(in: &cancellables)
        
        dataSource = context.viewState.dataSource
        currentPreviewItemIndex = context.viewState.dataSource.initialItemIndex
    }
    
    @available(*, unavailable) required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: Layout
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if let bottomBarItemsContainer {
            if #unavailable(iOS 26) {
                // Using the toolbar's visibility doesn't work so check its frame.
                captionView.isHidden = bottomBarItemsContainer.frame.minY >= view.frame.maxY
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
        super.viewWillDisappear(animated)
        
        barButtonTimer?.invalidate()
        barButtonTimer = nil
    }
    
    @available(iOS 26, *)
    private func updateCaptionVisibility() {
        // The caption should be hidden alongside the header.
        let isHeaderHidden = headerHostingController.view.window == nil
        let currentItemID = currentPreviewItemMediaID
        
        let isHidden = isHeaderHidden || currentItemID == captionHiddenForItemID
        if captionView.isHidden != isHidden {
            captionView.isHidden = isHidden
            if isHidden {
                captionHiddenForItemID = currentItemID // Don't show the caption again for this item.
            }
        }
    }
    
    private func updateBarButtons() {
        guard let topItem = navigationBar?.topItem else { return }
        
        if #available(iOS 27, *) {
            if topItem.rightBarButtonItem?.customView == nil {
                topItem.rightBarButtonItem = UIBarButtonItem(customView: detailsButtonHostingController.view)
            }
        } else if topItem.leftBarButtonItem?.customView == nil {
            topItem.leftBarButtonItem = UIBarButtonItem(customView: detailsButtonHostingController.view)
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
        // The overlay follows the finger whilst the preview is being dismissed.
        guard interactiveDismissal == nil else { return }
        guard let pageScrollView, let overlayView = downloadIndicatorHostingController.view else { return }
        
        let pageWidth = pageScrollView.bounds.width
        guard pageWidth > 0 else { return }
        
        // Whilst resting on an item, keep track of the offset that any swipe will start from.
        if !pageScrollView.isDragging, !pageScrollView.isDecelerating {
            pageScrollViewRestingOffset = pageScrollView.contentOffset.x
        }
        
        let delta = pageScrollView.contentOffset.x - pageScrollViewRestingOffset
        overlayView.transform = CGAffineTransform(translationX: -delta, y: 0)
        // Fade towards the midpoint so the overlay never clashes with the neighbouring item's state.
        overlayView.alpha = max(0, 1 - abs(delta) / (pageWidth / 2))
    }
    
    // MARK: Item loading
    
    private func loadCurrentItem() {
        headerHostingController.view.sizeToFit() // Resizing isn't automatic in the toolbar 😒
        
        if #available(iOS 26, *), view.window != nil {
            if captionHiddenForItemID != currentPreviewItemMediaID {
                captionHiddenForItemID = nil // Allow the caption to be re-shown when swiping.
            }
            
            updateCaptionVisibility()
        }
        
        if let previewItem = currentPreviewItem as? TimelineMediaPreviewItem.Media {
            context.send(viewAction: .updateCurrentItem(.media(previewItem)))
        } else if let loadingItem = currentPreviewItem as? TimelineMediaPreviewItem.Loading {
            // QuickLook prefetches every item up front, so the placeholder may predate a timeline update.
            guard !isDisplayedPlaceholderStale else {
                refreshCurrentItemWhenSettled()
                return
            }
            
            switch loadingItem.state {
            case .paginating:
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
        context.send(viewAction: .timelineEndReached)
    }
    
    private func handleUpdatedItems() {
        guard isDisplayedPlaceholderStale else { return }
        refreshCurrentItemWhenSettled()
    }
    
    private func handleFileLoaded(itemID: MediaPreviewItemID) {
        itemIDsAwaitingRefresh.insert(itemID)
        refreshCurrentItemWhenSettled()
    }
    
    private func refreshCurrentItemWhenSettled() {
        settledRefreshTask = Task {
            // Refreshing whilst swiping completely breaks the QLPreviewController, so wait for the swipe to settle.
            // The sleep returns immediately once cancelled, so stop waiting rather than spinning.
            while !Task.isCancelled, isSwiping {
                try? await Task.sleep(for: .seconds(0.1))
            }
            guard !Task.isCancelled else { return }
            
            let isDisplayedMediaAwaitingRefresh = (currentPreviewItem as? TimelineMediaPreviewItem.Media).map { itemIDsAwaitingRefresh.contains($0.id) } ?? false
            itemIDsAwaitingRefresh.removeAll()
            
            if isDisplayedMediaAwaitingRefresh || isDisplayedPlaceholderStale {
                refreshCurrentPreviewItem() // This will trigger loadCurrentItem automatically.
            }
        }
    }
    
    // MARK: Dismiss gesture
    
    @objc private func handleDismissGesture(_ gestureRecognizer: UIPanGestureRecognizer) {
        let translation = gestureRecognizer.translation(in: view)
        
        switch gestureRecognizer.state {
        case .began:
            beginInteractiveDismissal()
        case .changed:
            interactiveDismissal?.update(translation: translation)
        case .ended:
            let velocity = gestureRecognizer.velocity(in: view)
            // As with a loaded item, moving the finger back up before letting go cancels the dismissal.
            if velocity.y >= 0, translation.y > 100 || velocity.y > 800 {
                interactiveDismissal?.finish(velocity: velocity)
            } else {
                interactiveDismissal?.cancel(velocity: velocity)
            }
        case .cancelled, .failed:
            interactiveDismissal?.cancel()
        default:
            break
        }
    }
    
    /// Starts dismissing the preview under the user's finger, mirroring QuickLook's own gesture for a loaded item.
    private func beginInteractiveDismissal() {
        guard interactiveDismissal == nil, let contentView = downloadIndicatorHostingController.view else { return }
        
        let chromeViews = [navigationBar, bottomBarItemsContainer, captionView].compactMap { $0 }
        let dismissal = InteractiveDismissal(previewController: self, contentView: contentView, chromeViews: chromeViews)
        dismissal.onCompletion = { [weak self] didDismiss in
            self?.endInteractiveDismissal(didDismiss: didDismiss)
        }
        
        interactiveDismissal = dismissal
        // Don't page between items whilst the preview follows the finger.
        pageScrollView?.isScrollEnabled = false
        
        dismissal.begin()
    }
    
    private func endInteractiveDismissal(didDismiss: Bool) {
        guard didDismiss else {
            interactiveDismissal = nil
            pageScrollView?.isScrollEnabled = true
            updateOverlayPosition()
            return
        }
        
        // Everything has already animated away, so remove the preview without QuickLook's own animation. QuickLook doesn't
        // call `previewControllerDidDismiss` when dismissed programmatically, so tell the delegate (captured up front as
        // QuickLook clears it whilst dismissing), letting the presenter clean up its state.
        let delegate = delegate
        dismiss(animated: false) { [weak self] in
            guard let self else { return }
            delegate?.previewControllerDidDismiss?(self)
        }
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
    /// Called whenever the header is added or removed from a window.
    var onMoveToWindow: () -> Void = { }
    
    private var currentItem: TimelineMediaPreviewItem {
        context.viewState.currentItem
    }
    
    var body: some View {
        content
            .background(WindowTrackingView(onMoveToWindow: onMoveToWindow))
    }
    
    @ViewBuilder
    private var content: some View {
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

/// Lets a downward swipe dismiss the preview while the current item has nothing to show (still downloading,
/// failed or loading more), as QuickLook only provides that gesture once an item's file has loaded.
///
/// A separate object so that QuickLook's own gesture recognizer delegate methods aren't overridden.
private final class EmptyItemDismissGestureDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var previewController: QLPreviewController?
    /// The caption scrolls by itself, so drags that start on it are left alone.
    weak var captionView: UIView?
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let previewController,
              previewController.currentPreviewItem?.previewItemURL == nil,
              let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer else {
            return false
        }
        
        // Only a downward swipe, matching QuickLook's own gesture for a loaded item.
        let velocity = panGestureRecognizer.velocity(in: previewController.view)
        return velocity.y > abs(velocity.x)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        guard let captionView, !captionView.isHidden else { return true }
        return !captionView.bounds.contains(touch.location(in: captionView))
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Recognise alongside the page scroll view, which receives the touch first.
        true
    }
}

/// Dismisses the preview under the user's finger, the way QuickLook does for a loaded item: the content follows the finger
/// and shrinks whilst everything else fades away to reveal what's underneath. Letting go either carries the content away
/// with the finger's momentum or springs everything back into place.
///
/// QuickLook doesn't honour a custom transitioning delegate, so this does by hand what UIKit does for an interactive
/// dismissal: whilst the gesture is in progress, the presenter's view (which a full screen presentation removes) is put
/// back underneath the preview so that it can be revealed.
@MainActor
private final class InteractiveDismissal {
    private weak var previewController: UIViewController?
    /// The view that follows the finger.
    private let contentView: UIView
    /// The bars and caption, which fade out quickly as soon as the content is moved.
    private let chromeViews: [UIView]
    
    /// Called once the content has animated away (`true`) or back into place (`false`).
    var onCompletion: ((_ didDismiss: Bool) -> Void)?
    
    /// The views that make up the preview's backdrop, which fade proportionally to how far the content has moved.
    private var backdropViews: [UIView] = []
    /// How opaque the backdrop and chrome were beforehand, to fade from and restore if the dismissal is cancelled.
    private var originalAlphas: [UIView: CGFloat] = [:]
    private var previewBackgroundColor: UIColor?
    /// The presenter's view, when it was added back underneath the preview to be revealed.
    private var revealedView: UIView?
    private var translation: CGPoint = .zero
    /// Whether the finger has been lifted, in which case the content is settling.
    private var isSettling = false
    
    private var previewView: UIView? {
        previewController?.view
    }
    
    /// How far along the dismissal is, reaching the end once the finger has travelled half the screen down.
    private var progress: CGFloat {
        guard let height = previewView?.bounds.height, height > 0 else { return 0 }
        return min(max(translation.y / (height / 2), 0), 1)
    }
    
    init(previewController: UIViewController, contentView: UIView, chromeViews: [UIView]) {
        self.previewController = previewController
        self.contentView = contentView
        self.chromeViews = chromeViews
    }
    
    func begin() {
        guard let previewView else { return }
        backdropViews = previewView.subviews.filter { $0 !== contentView && !chromeViews.contains($0) }
        originalAlphas = Dictionary((backdropViews + chromeViews).map { ($0, $0.alpha) }) { first, _ in first }
        previewBackgroundColor = previewView.backgroundColor
        
        if let presenterView = previewController?.presentingViewController?.view,
           presenterView.window == nil,
           let containerView = previewView.superview {
            containerView.insertSubview(presenterView, belowSubview: previewView)
            revealedView = presenterView
        }
        
        UIView.animate(withDuration: 0.2) {
            self.chromeViews.forEach { $0.alpha = 0 }
        }
    }
    
    func update(translation: CGPoint) {
        guard !isSettling else { return }
        self.translation = translation
        
        let progress = progress
        setBackdropOpacity(1 - progress)
        contentView.transform = contentTransform(translation: translation, progress: progress)
    }
    
    func finish(velocity: CGPoint) {
        guard !isSettling else { return }
        isSettling = true
        
        // Carry on in the direction of the finger so the content leaves with its momentum.
        let finalTranslation = CGPoint(x: translation.x + velocity.x * 0.2,
                                       y: translation.y + max(velocity.y * 0.2, 200))
        let animator = UIViewPropertyAnimator(duration: 0.3, curve: .easeOut) {
            self.setBackdropOpacity(0)
            self.contentView.transform = self.contentTransform(translation: finalTranslation, progress: 1)
            self.contentView.alpha = 0
        }
        animator.addCompletion { _ in
            self.onCompletion?(true)
        }
        animator.startAnimation()
    }
    
    func cancel(velocity: CGPoint = .zero) {
        guard !isSettling else { return }
        isSettling = true
        
        // Pick up from the finger's speed so that letting go mid-movement flows straight into the spring back.
        let distance = -translation.y
        let relativeVelocity = abs(distance) > 1 ? velocity.y / distance : 0
        let timingParameters = UISpringTimingParameters(dampingRatio: 0.8, initialVelocity: CGVector(dx: relativeVelocity, dy: 0))
        let animator = UIViewPropertyAnimator(duration: 0.45, timingParameters: timingParameters)
        animator.addAnimations {
            self.setBackdropOpacity(1)
            self.chromeViews.forEach { $0.alpha = self.originalAlphas[$0] ?? 1 }
            self.contentView.transform = .identity
        }
        animator.addCompletion { _ in
            self.previewView?.backgroundColor = self.previewBackgroundColor
            self.revealedView?.removeFromSuperview()
            self.onCompletion?(false)
        }
        animator.startAnimation()
    }
    
    // MARK: Private
    
    private func setBackdropOpacity(_ opacity: CGFloat) {
        backdropViews.forEach { $0.alpha = (originalAlphas[$0] ?? 1) * opacity }
        let backgroundAlpha = previewBackgroundColor?.cgColor.alpha ?? 1
        previewView?.backgroundColor = previewBackgroundColor?.withAlphaComponent(backgroundAlpha * opacity)
    }
    
    /// Follows the finger, with resistance when pulled upwards, shrinking a little the further down it goes.
    private func contentTransform(translation: CGPoint, progress: CGFloat) -> CGAffineTransform {
        let y = translation.y >= 0 ? translation.y : translation.y / 3
        let scale = UIAccessibility.isReduceMotionEnabled ? 1 : 1 - 0.25 * progress
        return CGAffineTransform(translationX: translation.x, y: y).scaledBy(x: scale, y: scale)
    }
}

/// An invisible view that reports when it is added to or removed from a window.
private struct WindowTrackingView: UIViewRepresentable {
    let onMoveToWindow: () -> Void
    
    func makeUIView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.isUserInteractionEnabled = false
        view.onMoveToWindow = onMoveToWindow
        return view
    }
    
    func updateUIView(_ uiView: TrackingView, context: Context) {
        uiView.onMoveToWindow = onMoveToWindow
    }
    
    class TrackingView: UIView {
        var onMoveToWindow: (() -> Void)?
        
        override func didMoveToWindow() {
            super.didMoveToWindow()
            onMoveToWindow?()
        }
    }
}

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
