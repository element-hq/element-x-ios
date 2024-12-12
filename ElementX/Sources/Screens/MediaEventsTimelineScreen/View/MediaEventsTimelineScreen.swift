//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct MediaEventsTimelineScreen: View {
    @ObservedObject var context: MediaEventsTimelineScreenViewModel.Context
    
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
            .timelineMediaQuickLook(viewModel: $context.mediaPreviewViewModel)
            .environmentObject(context.viewState.activeTimelineContextProvider())
            .environment(\.timelineContext, context.viewState.activeTimelineContextProvider())
    }
    
    // The scale effects do the following:
    // * flip the scrollView vertically to keep the items
    // at the bottom and have pagination working properly
    // * flip the grid vertically to counteract the scroll view
    // but also horizontally to preserve the corect item order
    // * flip the items on both axes have them render correctly
    private var mainContent: some View {
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
        .onChange(of: context.screenMode) { _, _ in
            context.send(viewAction: .changedScreenMode)
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
                            context.send(viewAction: .tappedItem(item))
                        } label: {
                            Color.clear // Let the image aspect fill in place
                                .aspectRatio(1, contentMode: .fill)
                                .overlay {
                                    viewForTimelineItem(item)
                                }
                                .clipped()
                                .scaleEffect(.init(width: -1, height: -1))
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
    
    @ViewBuilder
    private var filesContent: some View {
        LazyVStack(alignment: .center, spacing: 16) {
            ForEach(context.viewState.groups) { group in
                Section {
                    ForEach(group.items) { item in
                        VStack(spacing: 20) {
                            Divider()
                            
                            Button {
                                context.send(viewAction: .tappedItem(item))
                            } label: {
                                viewForTimelineItem(item)
                                    .scaleEffect(.init(width: 1, height: -1))
                            }
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
    func viewForTimelineItem(_ item: RoomTimelineItemViewState) -> some View {
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
}

// MARK: - Previews

struct MediaEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let timelineViewModel: TimelineViewModel = {
        let timelineController = MockRoomTimelineController(timelineKind: .media(.mediaFilesScreen))
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
    }()
    
    static let mediaViewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: timelineViewModel,
                                                                   filesTimelineViewModel: timelineViewModel,
                                                                   mediaProvider: MediaProviderMock(configuration: .init()),
                                                                   screenMode: .media,
                                                                   userIndicatorController: UserIndicatorControllerMock())
    
    static let filesViewModel = MediaEventsTimelineScreenViewModel(mediaTimelineViewModel: timelineViewModel,
                                                                   filesTimelineViewModel: timelineViewModel,
                                                                   mediaProvider: MediaProviderMock(configuration: .init()),
                                                                   screenMode: .files,
                                                                   userIndicatorController: UserIndicatorControllerMock())
    
    static var previews: some View {
        NavigationStack {
            MediaEventsTimelineScreen(context: mediaViewModel.context)
        }
        .previewDisplayName("Media")
        
        NavigationStack {
            MediaEventsTimelineScreen(context: filesViewModel.context)
        }
        .previewDisplayName("Files")
    }
}
