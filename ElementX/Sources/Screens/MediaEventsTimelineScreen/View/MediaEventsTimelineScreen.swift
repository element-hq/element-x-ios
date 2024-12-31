//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MediaEventsTimelineScreen: View {
    @ObservedObject var context: MediaEventsTimelineScreenViewModel.Context
    
    @Namespace private var zoomTransition
    
    var body: some View {
        mainContent
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            // Doesn't play well with the transformed scrollView
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
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
            }
            .environmentObject(context.viewState.activeTimelineContextProvider())
            .environment(\.timelineContext, context.viewState.activeTimelineContextProvider())
            .onChange(of: context.screenMode) { _, _ in
                context.send(viewAction: .changedScreenMode)
            }
    }
    
    // The scale effects do the following:
    // * flip the scrollView vertically to keep the items
    // at the bottom and have pagination working properly
    // * flip the grid vertically to counteract the scroll view
    // but also horizontally to preserve the correct item order
    // * flip the items on both axes have them render correctly
    @ViewBuilder
    private var mainContent: some View {
        if context.viewState.shouldShowEmptyState {
            emptyState
        } else {
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
                                .scaleEffect(scale(for: item, isGridLayout: true))
                        }
                        .zoomTransitionSource(id: item.identifier, in: zoomTransition)
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
    
    @ViewBuilder
    private var filesContent: some View {
        LazyVStack(alignment: .center, spacing: 16) {
            ForEach(context.viewState.groups) { group in
                Section {
                    ForEach(group.items) { item in
                        VStack(spacing: 20) {
                            Divider()
                            
                            Button {
                                tappedItem(item)
                            } label: {
                                viewForTimelineItem(item)
                                    .scaleEffect(scale(for: item, isGridLayout: false))
                            }
                            .zoomTransitionSource(id: item.identifier, in: zoomTransition)
                        }
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
            let playerState = context.viewState.activeTimelineContextProvider().viewState.audioPlayerStateProvider?(timelineItem.id) ?? defaultPlayerState
            VoiceMessageMediaEventsTimelineView(timelineItem: timelineItem, playerState: playerState)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
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
    
    private var emptyMedia: some View {
        Group {
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
    }
    
    private var emptyFiles: some View {
        Group {
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
    }
    
    func tappedItem(_ item: RoomTimelineItemViewState) {
        context.send(viewAction: .tappedItem(item: item, namespace: zoomTransition))
    }
    
    func scale(for item: RoomTimelineItemViewState, isGridLayout: Bool) -> CGSize {
        if item.identifier == context.viewState.currentPreviewItemID, #available(iOS 18.0, *) {
            // Remove the flip when presenting a preview so that the zoom transition is the right way up 🙃
            CGSize(width: 1, height: 1)
        } else {
            CGSize(width: isGridLayout ? -1 : 1, height: -1)
        }
    }
}

// MARK: - Previews

struct MediaEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let mediaViewModel = makeViewModel(screenMode: .media)
    static let filesViewModel = makeViewModel(screenMode: .files)
    static let emptyMediaViewModel = makeViewModel(empty: true, screenMode: .media)
    static let emptyFilesViewModel = makeViewModel(empty: true, screenMode: .files)
    
    static var previews: some View {
        NavigationStack {
            MediaEventsTimelineScreen(context: mediaViewModel.context)
        }
        .previewDisplayName("Media")
        
        NavigationStack {
            MediaEventsTimelineScreen(context: filesViewModel.context)
        }
        .previewDisplayName("Files")
        
        NavigationStack {
            MediaEventsTimelineScreen(context: emptyMediaViewModel.context)
        }
        .previewDisplayName("Empty Media")
        
        NavigationStack {
            MediaEventsTimelineScreen(context: emptyFilesViewModel.context)
        }
        .previewDisplayName("Empty Files")
    }
    
    private static func makeViewModel(empty: Bool = false,
                                      screenMode: MediaEventsTimelineScreenMode) -> MediaEventsTimelineScreenViewModel {
        MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: makeTimelineViewModel(empty: empty),
                                           filesTimelineViewModel: makeTimelineViewModel(empty: empty),
                                           initialViewState: .init(bindings: .init(screenMode: screenMode)),
                                           mediaProvider: MediaProviderMock(configuration: .init()),
                                           userIndicatorController: UserIndicatorControllerMock())
    }
    
    private static func makeTimelineViewModel(empty: Bool) -> TimelineViewModel {
        let timelineController = if empty {
            MockRoomTimelineController.emptyMediaGallery
        } else {
            MockRoomTimelineController.mediaGallery
        }
        
        return TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Preview room")),
                                 timelineController: timelineController,
                                 mediaProvider: MediaProviderMock(configuration: .init()),
                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                 voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                 userIndicatorController: UserIndicatorControllerMock(),
                                 appMediator: AppMediatorMock.default,
                                 appSettings: ServiceLocator.shared.settings,
                                 analyticsService: ServiceLocator.shared.analytics,
                                 emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))
    }
}
