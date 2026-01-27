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
        
        updateBarButtons()
        
        // Ridiculous hack to undo the controller's attempt to replace our info button with the list button.
        if barButtonTimer == nil {
            barButtonTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                self?.updateBarButtons()
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
    
    // MARK: Item loading
    
    private func loadCurrentItem() {
        headerHostingController.view.sizeToFit() // Resizing isn't automatic in the toolbar 😒
        
        if let previewItem = currentPreviewItem as? TimelineMediaPreviewItem.Media {
            context.send(viewAction: .updateCurrentItem(.media(previewItem)))
        } else if let loadingItem = currentPreviewItem as? TimelineMediaPreviewItem.Loading {
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
        if currentPreviewItem is TimelineMediaPreviewItem.Loading {
            let dataSource = context.viewState.dataSource
            if dataSource.previewController(self, previewItemAt: currentPreviewItemIndex) is TimelineMediaPreviewItem.Media {
                refreshCurrentPreviewItem() // This will trigger loadCurrentItem automatically.
            }
        }
    }
    
    private func handleFileLoaded(itemID: TimelineItemIdentifier.EventOrTransactionID) {
        guard (currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id == itemID else { return }
        
        // There's a bug where refreshCurrentPreviewItem completely breaks the QLPreviewController
        // if it's called whilst swiping between items. So don't let that happen.
        if let scrollView = pageScrollView, scrollView.isDragging || scrollView.isDecelerating {
            return
        }
        
        refreshCurrentPreviewItem()
    }
    
    // MARK: - Actions
    
    private func presentMediaDetails(for mediaItem: TimelineMediaPreviewItem.Media) {
        let safeArea = view.safeAreaInsets.bottom
        let sheetHeightBinding = Binding { safeArea } set: { [weak self] newValue, _ in
            self?.detailsHostingController?.sheetPresentationController?.detents = [.height(newValue + safeArea)]
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
        switch currentItem {
        case .media(let mediaItem):
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
        case .loading:
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
    
    var isHidden: Bool {
        switch currentItem {
        case .media: false
        case .loading: true
        }
    }
    
    var body: some View {
        if case .media(let mediaItem) = currentItem {
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
        if case let .media(mediaItem) = currentItem, let caption = mediaItem.caption {
            Text(caption)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textPrimary)
                .lineLimit(5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
                .padding(16)
                .background {
                    BlurEffectView(style: .systemChromeMaterial) // Darkest material available, matches the bottom bar when content is beneath.
                        .ignoresSafeArea()
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }
}

private struct DownloadIndicatorView: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    private var currentItem: TimelineMediaPreviewItem {
        context.viewState.currentItem
    }
    
    private var shouldShowDownloadIndicator: Bool {
        switch currentItem {
        case .media(let mediaItem): mediaItem.fileHandle == nil
        case .loading(.paginatingBackwards), .loading(.paginatingForwards): true
        case .loading: false
        }
    }
    
    var body: some View {
        if case let .media(mediaItem) = currentItem, mediaItem.downloadError != nil {
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
        } else if shouldShowDownloadIndicator {
            ProgressView()
                .controlSize(.large)
                .tint(.compound.iconPrimary)
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
