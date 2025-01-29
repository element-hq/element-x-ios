//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import QuickLook
import SwiftUI

struct TimelineMediaPreviewScreen: View {
    @ObservedObject var context: TimelineMediaPreviewViewModel.Context
    var itemIDHandler: ((TimelineItemIdentifier?) -> Void)?
    
    @State private var isFullScreen = false
    private var toolbarVisibility: Visibility { isFullScreen ? .hidden : .visible }
    
    private var currentItem: TimelineMediaPreviewItem { context.viewState.currentItem }
    private var currentItemID: TimelineItemIdentifier? {
        guard case .media(let mediaItem) = currentItem else { return nil }
        return mediaItem.id
    }
    
    private var shouldShowDownloadIndicator: Bool {
        switch currentItem {
        case .media(let mediaItem): mediaItem.fileHandle == nil
        case .loading(let loadingItem): loadingItem.state == .paginating
        }
    }
    
    var body: some View {
        NavigationStack {
            quickLookPreview
        }
        .introspect(.navigationStack, on: .supportedVersions) {
            // Fixes a bug where the QuickLook view overrides the .toolbarBackground(.visible) after it loads the real item.
            $0.navigationBar.scrollEdgeAppearance = $0.navigationBar.standardAppearance
            $0.toolbar.scrollEdgeAppearance = $0.toolbar.standardAppearance
        }
        .sheet(item: $context.mediaDetailsItem) { item in
            TimelineMediaPreviewDetailsView(item: item, context: context)
        }
        .sheet(item: $context.fileToExport) { file in
            TimelineMediaPreviewFileExportPicker(file: file)
                .preferredColorScheme(.dark)
        }
        .alert(item: $context.alertInfo)
        .preferredColorScheme(.dark)
        .onDisappear {
            itemIDHandler?(nil)
        }
        .zoomTransition(sourceID: currentItemID, in: context.viewState.transitionNamespace)
    }
    
    var quickLookPreview: some View {
        Color.clear // A completely clear view breaks any SwiftUI gestures (such as drag to dismiss).
            .background { QuickLookView(viewModelContext: context).ignoresSafeArea() } // Not the root view to stop QL hijacking the toolbar.
            .overlay(alignment: .topTrailing) { fullScreenButton }
            .overlay { downloadStatusIndicator }
            .toolbar { toolbar }
            .toolbar(toolbarVisibility, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar) // The toolbar's scrollEdgeAppearance isn't aware of the quicklook view 🤷‍♂️
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) { caption }
    }
    
    @ViewBuilder
    private var fullScreenButton: some View {
        if case .media = currentItem {
            Button {
                withAnimation { isFullScreen.toggle() }
            } label: {
                CompoundIcon(isFullScreen ? \.collapse : \.expand, size: .xSmall, relativeTo: .compound.bodyLG)
                    .padding(6)
                    .background(.thinMaterial, in: Circle())
            }
            .tint(.compound.textActionPrimary)
            .padding(.top, 12)
            .padding(.trailing, 14)
        }
    }
    
    @ViewBuilder
    private var downloadStatusIndicator: some View {
        if case let .media(mediaItem) = currentItem, mediaItem.downloadError != nil {
            VStack(spacing: 24) {
                CompoundIcon(\.error, size: .custom(48), relativeTo: .compound.headingLG)
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
    
    @ViewBuilder
    private var caption: some View {
        if case let .media(mediaItem) = currentItem, let caption = mediaItem.caption, !isFullScreen {
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
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .dismiss) } label: {
                Image(systemSymbol: .chevronBackward)
                    .fontWeight(.semibold)
            }
            .tint(.compound.textActionPrimary) // These fix a bug where the light tint is shown when foregrounding the app.
        }
        
        ToolbarItem(placement: .principal) {
            toolbarHeader
        }
        
        if case let .media(mediaItem) = currentItem {
            ToolbarItem(placement: .primaryAction) {
                Button { context.send(viewAction: .showItemDetails(mediaItem)) } label: {
                    CompoundIcon(\.info)
                }
                .tint(.compound.textActionPrimary)
            }
        }
    }
    
    @ViewBuilder
    private var toolbarHeader: some View {
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
        case .loading:
            Text(L10n.commonLoadingMore)
                .font(.compound.bodySMSemibold)
                .foregroundStyle(.compound.textPrimary)
        }
    }
}

// MARK: - QuickLook

private struct QuickLookView: UIViewControllerRepresentable {
    let viewModelContext: TimelineMediaPreviewViewModel.Context

    func makeUIViewController(context: Context) -> QLPreviewController {
        context.coordinator.previewController
    }

    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext)
    }
    
    // MARK: Coordinator
    
    @MainActor class Coordinator {
        let previewController = QLPreviewController()
        
        private let viewModelContext: TimelineMediaPreviewViewModel.Context
        
        private var cancellables: Set<AnyCancellable> = []
        
        init(viewModelContext: TimelineMediaPreviewViewModel.Context) {
            self.viewModelContext = viewModelContext
            
            // Observation of currentPreviewItem doesn't work, so use the index instead.
            previewController.publisher(for: \.currentPreviewItemIndex)
                .sink { [weak self] _ in
                    // This isn't removing duplicates which may try to download and/or write to disk concurrently????
                    self?.loadCurrentItem()
                }
                .store(in: &cancellables)
            
            viewModelContext.viewState.dataSource.previewItemsPaginationPublisher
                .sink { [weak self] in
                    self?.handleUpdatedItems()
                }
                .store(in: &cancellables)
            
            viewModelContext.viewState.fileLoadedPublisher
                .sink { [weak self] itemID in
                    self?.handleFileLoaded(itemID: itemID)
                }
                .store(in: &cancellables)
            
            previewController.dataSource = viewModelContext.viewState.dataSource
            previewController.currentPreviewItemIndex = viewModelContext.viewState.dataSource.initialItemIndex
        }
        
        private func loadCurrentItem() {
            if let previewItem = previewController.currentPreviewItem as? TimelineMediaPreviewItem.Media {
                viewModelContext.send(viewAction: .updateCurrentItem(.media(previewItem)))
            } else if let loadingItem = previewController.currentPreviewItem as? TimelineMediaPreviewItem.Loading {
                switch loadingItem.state {
                case .paginating:
                    viewModelContext.send(viewAction: .updateCurrentItem(.loading(loadingItem)))
                case .timelineStart:
                    Task { await returnToIndex(viewModelContext.viewState.dataSource.firstPreviewItemIndex) }
                case .timelineEnd:
                    Task { await returnToIndex(viewModelContext.viewState.dataSource.lastPreviewItemIndex) }
                }
            } else {
                MXLog.error("Unexpected preview item type: \(type(of: previewController.currentPreviewItem))")
            }
        }
        
        private func returnToIndex(_ index: Int) async {
            // Sleep to fix a bug where the update didn't take effect when the swipe velocity was slow.
            try? await Task.sleep(for: .seconds(0.1))
            
            previewController.currentPreviewItemIndex = index
            viewModelContext.send(viewAction: .timelineEndReached)
        }
        
        private func handleUpdatedItems() {
            if previewController.currentPreviewItem is TimelineMediaPreviewItem.Loading {
                let dataSource = viewModelContext.viewState.dataSource
                if dataSource.previewController(previewController, previewItemAt: previewController.currentPreviewItemIndex) is TimelineMediaPreviewItem.Media {
                    previewController.refreshCurrentPreviewItem() // This will trigger loadCurrentItem automatically.
                }
            }
        }
        
        private func handleFileLoaded(itemID: TimelineItemIdentifier) {
            guard (previewController.currentPreviewItem as? TimelineMediaPreviewItem.Media)?.id == itemID else { return }
            previewController.refreshCurrentPreviewItem()
        }
    }
}

// MARK: - Previews

struct TimelineMediaPreviewScreen_Previews: PreviewProvider {
    @Namespace private static var namespace
    
    static let viewModel = makeViewModel()
    static let downloadingViewModel = makeViewModel(isDownloading: true)
    static let downloadErrorViewModel = makeViewModel(isDownloadError: true)
    
    static var previews: some View {
        TimelineMediaPreviewScreen(context: viewModel.context)
            .previewDisplayName("Normal")
        TimelineMediaPreviewScreen(context: downloadingViewModel.context)
            .previewDisplayName("Downloading")
        TimelineMediaPreviewScreen(context: downloadErrorViewModel.context)
            .previewDisplayName("Download Error")
    }
    
    static func makeViewModel(isDownloading: Bool = false, isDownloadError: Bool = false) -> TimelineMediaPreviewViewModel {
        let item = FileRoomTimelineItem(id: .randomEvent,
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        isThreaded: false,
                                        sender: .init(id: "", displayName: "Sally Sanderson"),
                                        content: .init(filename: "Important document.pdf",
                                                       caption: "A caption goes right here.",
                                                       source: try? .init(url: .mockMXCFile, mimeType: nil),
                                                       fileSize: 3 * 1024 * 1024,
                                                       thumbnailSource: nil,
                                                       contentType: .pdf))
        
        let timelineController = MockRoomTimelineController(timelineKind: .media(.mediaFilesScreen))
        timelineController.timelineItems = [item]
        
        let mediaProvider = MediaProviderMock(configuration: .init())
        
        if isDownloading {
            mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in
                try? await Task.sleep(for: .seconds(3600))
                return .failure(.failedRetrievingFile)
            }
        } else if isDownloadError {
            mediaProvider.loadFileFromSourceFilenameClosure = { _, _ in .failure(.failedRetrievingFile) }
        }
        
        return TimelineMediaPreviewViewModel(context: .init(item: item,
                                                            viewModel: TimelineViewModel.mock(timelineKind: timelineController.timelineKind,
                                                                                              timelineController: timelineController),
                                                            namespace: namespace),
                                             mediaProvider: mediaProvider,
                                             photoLibraryManager: PhotoLibraryManagerMock(.init()),
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             appMediator: AppMediatorMock())
    }
}
