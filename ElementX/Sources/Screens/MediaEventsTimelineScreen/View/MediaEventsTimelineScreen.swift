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
        content
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
    }
    
    // The scale effects do the following:
    // * flip the scrollView vertically to keep the items
    // at the bottom and have pagination working properly
    // * flip the grid vertically to counteract the scroll view
    // but also horizontally to preserve the corect item order
    // * flip the items on both axes have them render correctly
    @ViewBuilder
    private var content: some View {
        ScrollView {
            Group {
                let columns = [GridItem(.adaptive(minimum: 80, maximum: 150), spacing: 1)]
                LazyVGrid(columns: columns, alignment: .center, spacing: 1) {
                    ForEach(context.viewState.groups) { group in
                        Section(footer: sectionFooterForGroup(group)) {
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
                        }
                    }
                }
                .scaleEffect(.init(width: -1, height: 1))
                
                header
            }
        }
        .scaleEffect(.init(width: 1, height: -1))
        .onChange(of: context.screenMode) { _, _ in
            context.send(viewAction: .changedScreenMode)
        }
    }
    
    private var header: some View {
        // Needs to be wrapped in a LazyStack otherwise appearance calls don't trigger
        LazyVStack(spacing: 0) {
            ProgressView()
                .padding()
                .opacity(context.viewState.isBackPaginating ? 1 : 0)
            
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
    func sectionFooterForGroup(_ group: MediaEventsTimelineGroup) -> some View {
        Text(group.title)
            .font(.compound.bodySM)
            .foregroundColor(.compound.textPrimary)
            .frame(alignment: .center)
            .scaleEffect(.init(width: -1, height: -1))
            .padding(.vertical, 16)
    }
    
    @ViewBuilder
    func viewForTimelineItem(_ item: RoomTimelineItemViewState) -> some View {
        switch item.type {
        case .image(let timelineItem):
            #warning("Make this work for gifs")
            LoadableImage(mediaSource: timelineItem.content.thumbnailInfo?.source ?? timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailInfo?.size ?? timelineItem.content.imageInfo.size,
                          mediaProvider: context.mediaProvider) {
                placeholder
            }
            .mediaItemAspectRatio(imageInfo: timelineItem.content.thumbnailInfo ?? timelineItem.content.imageInfo)
        case .video(let timelineItem):
            if let thumbnailSource = timelineItem.content.thumbnailInfo?.source {
                LoadableImage(mediaSource: thumbnailSource,
                              mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                              blurhash: timelineItem.content.blurhash,
                              size: timelineItem.content.thumbnailInfo?.size,
                              mediaProvider: context.mediaProvider) { imageView in
                    imageView
                        .overlay { playIcon }
                } placeholder: {
                    placeholder
                }
                .mediaItemAspectRatio(imageInfo: timelineItem.content.thumbnailInfo)
            } else {
                playIcon
            }
        default:
            EmptyView()
        }
    }
    
    private var playIcon: some View {
        Image(systemName: "play.circle.fill")
            .resizable()
            .frame(width: 50, height: 50)
            .background(.ultraThinMaterial, in: Circle())
            .foregroundColor(.white)
    }
    
    private var placeholder: some View {
        Rectangle()
            .foregroundColor(.compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

extension View {
    /// Constrains the max height of a media item in the timeline, whilst preserving its aspect ratio.
    @ViewBuilder
    func mediaItemAspectRatio(imageInfo: ImageInfoProxy?) -> some View {
        aspectRatio(imageInfo?.aspectRatio, contentMode: .fill)
    }
}

// MARK: - Previews

struct MediaEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let timelineViewModel: TimelineViewModel = {
        let timelineController = MockRoomTimelineController(timelineKind: .media)
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
                .previewDisplayName("Media")
        }
        
        NavigationStack {
            MediaEventsTimelineScreen(context: filesViewModel.context)
                .previewDisplayName("Files")
        }
    }
}
