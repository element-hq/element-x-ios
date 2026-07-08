//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MediaEventsTimelineScreen: View {
    @Bindable var context: MediaEventsTimelineScreenViewModel.Context
    @State private var sheetHeight = CGFloat.zero
    
    var body: some View {
        mainContent
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            // Doesn't play well with the transformed scrollView
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar { toolbar }
            .environmentObject(context.viewState.activeTimelineContext)
            .environment(\.timelineContext, context.viewState.activeTimelineContext)
            .onChange(of: context.screenMode) { _, _ in
                context.send(viewAction: .changedScreenMode)
            }
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
            .sheet(item: $context.mediaPreviewSheetViewModel) { sheet in
                if case let .media(media) = sheet.state.currentItem {
                    TimelineMediaPreviewDetailsView(item: media,
                                                    context: sheet.context,
                                                    preferredColorScheme: nil,
                                                    sheetHeight: $sheetHeight)
                        .presentationDetents([.height(sheetHeight)])
                }
            }
    }
    
    /// The scale effects do the following:
    /// * flip the scrollView vertically to keep the items
    /// at the bottom and have pagination working properly
    /// * flip the grid vertically to counteract the scroll view
    /// but also horizontally to preserve the correct item order
    /// * flip the items on both axes have them render correctly
    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.shouldShowEmptyState {
            emptyState
        } else {
            scrollView
                // Remove the glass effect of iOS 26+
                // A flipped table view will always trigger it
                // since the nav bar thinks is always at the bottom.
                .backportScrollEdgeEffectHidden()
        }
    }
    
    private var scrollView: some View {
        ScrollView {
            Group {
                switch context.viewState.bindings.screenMode {
                case .media:
                    mediaContent
                case .files:
                    filesContent
                }
                
                header
            }
        }
        .scaleEffect(.init(width: 1, height: -1))
    }
    
    @ViewBuilder
    private var mediaContent: some View {
        let columns = [GridItem(.adaptive(minimum: 80, maximum: 150), spacing: 1)]
        LazyVGrid(columns: columns, alignment: .center, spacing: 1) {
            ForEach(context.viewState.groups) { group in
                Section {
                    ForEach(group.items) { item in
                        Button {
                            tappedItem(item)
                        } label: {
                            viewForTimelineItem(item)
                                .scaleEffect(CGSize(width: -1, height: -1))
                        }
                        .accessibleLongPress(named: L10n.actionOpenContextMenu) {
                            context.send(viewAction: .longPressedItem(item: item))
                        }
                    }
                } footer: {
                    // Use a footer as the header because the scrollView is flipped
                    SeparatorMediaEventsTimelineView(group: group)
                        .scaleEffect(.init(width: -1, height: -1))
                }
            }
        }
        .scaleEffect(.init(width: -1, height: 1))
    }
    
    private var filesContent: some View {
        LazyVStack(alignment: .center, spacing: 16) {
            ForEach(context.viewState.groups) { group in
                Section {
                    ForEach(group.items) { item in
                        VStack(spacing: 20) {
                            Divider()
                                .accessibilityHidden(true)
                            
                            Button {
                                tappedItem(item)
                            } label: {
                                viewForTimelineItem(item)
                                    .scaleEffect(CGSize(width: 1, height: -1))
                            }
                            .accessibilityRepresentation {
                                viewForTimelineItem(item)
                            }
                            .accessibleLongPress(named: L10n.actionOpenContextMenu) {
                                context.send(viewAction: .longPressedItem(item: item))
                            }
                        }
                        .accessibilityElement(children: .combine)
                        .padding(.horizontal, 16)
                    }
                } footer: {
                    // Use a footer as the header because the scrollView is flipped
                    SeparatorMediaEventsTimelineView(group: group)
                        .scaleEffect(.init(width: 1, height: -1))
                }
            }
        }
    }
    
    private var header: some View {
        // Needs to be wrapped in a LazyStack otherwise appearance calls don't trigger
        LazyVStack(spacing: 0) {
            ProgressView()
                .padding()
                .opacity(context.viewState.isBackPaginating ? 1 : 0)
                .scaleEffect(.init(width: 1, height: -1)) // Make sure it spins the right way around 🙃
            
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(.compound.bgCanvasDefault)
                .onAppear {
                    context.send(viewAction: .oldestItemDidAppear)
                }
                .onDisappear {
                    context.send(viewAction: .oldestItemDidDisappear)
                }
        }
    }
    
    @ViewBuilder
    private func viewForTimelineItem(_ item: RoomTimelineItemViewState) -> some View {
        switch item.type {
        case .image(let timelineItem):
            ImageMediaEventsTimelineView(timelineItem: timelineItem)
        case .video(let timelineItem):
            VideoMediaEventsTimelineView(timelineItem: timelineItem)
        case .file(let timelineItem):
            FileMediaEventsTimelineView(timelineItem: timelineItem)
        case .audio(let timelineItem):
            AudioMediaEventsTimelineView(timelineItem: timelineItem)
        case .voice(let timelineItem):
            let defaultPlayerState = AudioPlayerState(id: .timelineItemIdentifier(timelineItem.id), title: L10n.commonVoiceMessage, duration: 0)
            let playerState = context.viewState.activeTimelineContext.viewState.audioPlayerStateProvider?(timelineItem.id) ?? defaultPlayerState
            VoiceMessageMediaEventsTimelineView(timelineItem: timelineItem, playerState: playerState)
        default:
            EmptyView()
        }
    }
    
    private var emptyState: some View {
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar, background: .gradient) {
            VStack(spacing: 16) {
                switch context.screenMode {
                case .media:
                    emptyMedia
                case .files:
                    emptyFiles
                }
            }
            .padding(16)
        } bottomContent: { EmptyView() }
    }
    
    @ViewBuilder
    private var emptyMedia: some View {
        BigIcon(icon: \.image)
        
        Text(L10n.screenMediaBrowserMediaEmptyStateTitle)
            .foregroundColor(.compound.textPrimary)
            .font(.compound.headingMDBold)
            .multilineTextAlignment(.center)
        
        Text(L10n.screenMediaBrowserMediaEmptyStateSubtitle)
            .foregroundColor(.compound.textSecondary)
            .font(.compound.bodyMD)
            .multilineTextAlignment(.center)
    }
    
    @ViewBuilder
    private var emptyFiles: some View {
        BigIcon(icon: \.document)
        
        Text(L10n.screenMediaBrowserFilesEmptyStateTitle)
            .foregroundColor(.compound.textPrimary)
            .font(.compound.headingMDBold)
            .multilineTextAlignment(.center)
        
        Text(L10n.screenMediaBrowserFilesEmptyStateSubtitle)
            .foregroundColor(.compound.textSecondary)
            .font(.compound.bodyMD)
            .multilineTextAlignment(.center)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            if #available(iOS 26, *) {
                screenModePicker
            } else {
                screenModePicker
                    .frame(idealWidth: .greatestFiniteMagnitude)
            }
        }
        
        if #available(iOS 26, *) {
            ToolbarSpacer()
        } else {
            ToolbarItem(placement: .primaryAction) {
                // Reserve the space trailing space to match the back button.
                CompoundIcon(\.search).hidden()
            }
        }
    }
    
    private var screenModePicker: some View {
        Picker("", selection: $context.screenMode) {
            Text(L10n.screenMediaBrowserListModeMedia)
                .padding()
                .tag(MediaEventsTimelineScreenMode.media)
            Text(L10n.screenMediaBrowserListModeFiles)
                .padding()
                .tag(MediaEventsTimelineScreenMode.files)
        }
        .pickerStyle(.segmented)
    }
    
    func tappedItem(_ item: RoomTimelineItemViewState) {
        context.send(viewAction: .tappedItem(item: item))
    }
}

extension TimelineMediaPreviewViewModel: Identifiable {
    var id: UUID {
        instanceID
    }
}

// MARK: - Previews

struct MediaEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let mediaViewModel = makeViewModel(screenMode: .media)
    static let filesViewModel = makeViewModel(screenMode: .files)
    static let emptyMediaViewModel = makeViewModel(empty: true, screenMode: .media)
    static let emptyFilesViewModel = makeViewModel(empty: true, screenMode: .files)
    
    static var previews: some View {
        ElementNavigationStack {
            MediaEventsTimelineScreen(context: mediaViewModel.context)
        }
        .previewDisplayName("Media")
        
        ElementNavigationStack {
            MediaEventsTimelineScreen(context: filesViewModel.context)
        }
        .previewDisplayName("Files")
        
        ElementNavigationStack {
            MediaEventsTimelineScreen(context: emptyMediaViewModel.context)
        }
        .previewDisplayName("Empty Media")
        
        ElementNavigationStack {
            MediaEventsTimelineScreen(context: emptyFilesViewModel.context)
        }
        .previewDisplayName("Empty Files")
    }
    
    private static func makeViewModel(empty: Bool = false,
                                      screenMode: MediaEventsTimelineScreenMode) -> MediaEventsTimelineScreenViewModel {
        MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: makeTimelineViewModel(empty: empty, screenMode: .media),
                                           filesTimelineViewModel: makeTimelineViewModel(empty: empty, screenMode: .files),
                                           initialScreenMode: screenMode,
                                           mediaProvider: MediaProviderMock(.init()),
                                           userIndicatorController: UserIndicatorControllerMock(),
                                           appMediator: AppMediatorMock())
    }
    
    private static func makeTimelineViewModel(empty: Bool, screenMode: MediaEventsTimelineScreenMode) -> TimelineViewModel {
        let timelineController = if empty {
            TimelineControllerMock.emptyMediaGallery
        } else {
            makeTimelineController(screenMode: screenMode)
        }
        
        let appSettings = AppSettings.volatile()
        return TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Preview room")),
                                 timelineController: timelineController,
                                 userSession: UserSessionMock(.init(contentScannerService: contentScannerService)),
                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                 userIndicatorController: UserIndicatorControllerMock(),
                                 appMediator: AppMediatorMock(.init()),
                                 appSettings: appSettings,
                                 analyticsService: AnalyticsServiceMock(.init()),
                                 emojiProvider: EmojiProvider(appSettings: appSettings),
                                 linkMetadataProvider: LinkMetadataProvider(),
                                 timelineControllerFactory: TimelineControllerFactoryMock(.init()))
    }
    
    // MARK: Content scanning
    
    /// A content scanner that reports the dedicated mock sources as being scanned/unsafe and everything else as safe.
    private static let contentScannerService = {
        let contentScannerService = ContentScannerServiceMock()
        contentScannerService.scanResultFromSourceClosure = { source in
            switch source.url {
            case .mockMXCScanning: nil
            case .mockMXCUnsafe: false
            default: true
            }
        }
        contentScannerService.loadScanResultFromSourceClosure = { source in
            switch source.url {
            case .mockMXCScanning:
                // Never resolve so that the scanning state remains visible.
                try? await Task.sleep(for: .seconds(3600))
                return .failure(.failedScanning)
            case .mockMXCUnsafe:
                return .success(false)
            default:
                return .success(true)
            }
        }
        return contentScannerService
    }()
    
    /// The regular gallery items followed by one that is being scanned and an unsafe one.
    private static func makeTimelineController(screenMode: MediaEventsTimelineScreenMode) -> TimelineControllerMock {
        var timelineItems: [RoomTimelineItemProtocol] = (0..<5).reduce([]) { partialResult, _ in
            partialResult + [TimelineFixtures.separator] + TimelineFixtures.mediaChunk
        }
        
        switch screenMode {
        case .media:
            timelineItems.append(contentsOf: [makeImageItem(url: .mockMXCScanning), makeImageItem(url: .mockMXCUnsafe)])
        case .files:
            timelineItems.append(contentsOf: [makeFileItem(url: .mockMXCScanning), makeFileItem(url: .mockMXCUnsafe)])
        }
        
        return TimelineControllerMock(.init(timelineKind: .media(.mediaFilesScreen), timelineItems: timelineItems))
    }
    
    private static func makeImageItem(url: URL) -> ImageRoomTimelineItem {
        guard let mediaSource = try? MediaSourceProxy(url: url, mimeType: "image/jpg") else {
            fatalError("Invalid mock media source URL")
        }
        
        return ImageRoomTimelineItem(id: .randomEvent,
                                     timestamp: .mock,
                                     isOutgoing: false,
                                     isEditable: false,
                                     canBeRepliedTo: true,
                                     sender: .init(id: "@bob:matrix.org"),
                                     content: .init(filename: "image.jpg",
                                                    imageInfo: .init(source: mediaSource, width: 2730, height: 2048, mimeType: "image/jpg", fileSize: nil),
                                                    thumbnailInfo: nil,
                                                    blurhash: "KpE4oyayR5|GbHb];3j@of"))
    }
    
    private static func makeFileItem(url: URL) -> FileRoomTimelineItem {
        guard let mediaSource = try? MediaSourceProxy(url: url, mimeType: nil) else {
            fatalError("Invalid mock media source URL")
        }
        
        return FileRoomTimelineItem(id: .randomEvent,
                                    timestamp: .mock,
                                    isOutgoing: false,
                                    isEditable: false,
                                    canBeRepliedTo: true,
                                    sender: .init(id: "@bob:matrix.org"),
                                    content: .init(filename: "important-document.pdf",
                                                   caption: nil,
                                                   formattedCaption: nil,
                                                   source: mediaSource,
                                                   fileSize: 3 * 1024 * 1024,
                                                   thumbnailSource: nil,
                                                   contentType: nil))
    }
}
