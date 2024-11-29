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
    @ObservedObject var timelineContext: TimelineViewModel.Context
        
    @State private var topTimelineItemIdentifier: TimelineItemIdentifier?
    
    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .navigationTitle("Media and files") // TODO: fix this title too
    }
    
    @ViewBuilder
    private var content: some View {
        ScrollView {
            if timelineContext.viewState.timelineViewState.paginationState.backward == .paginating {
                ProgressView()
            }
                
            let columns = [GridItem(.adaptive(minimum: 80, maximum: 150), spacing: 1)]
            LazyVGrid(columns: columns, alignment: .center, spacing: 1) {
                ForEach(timelineContext.viewState.timelineViewState.itemViewStates) { item in
                    Color.clear // Let the image aspect fill in place
                        .aspectRatio(1, contentMode: .fill)
                        .overlay {
                            viewForTimelineItem(item)
                                .id(item.identifier)
                        }
                        .clipped()
                }
            }
            .scrollTargetLayout()
        }
        .scrollPosition(id: $topTimelineItemIdentifier, anchor: .topLeading)
        .scrollAnchor
        .onChange(of: topTimelineItemIdentifier) { _, newValue in
            // Filter out date separators when checking the top identifier
            let firstIdentifier = timelineContext.viewState.timelineViewState.itemViewStates.first(where: { item in
                switch item.type {
                case .separator:
                    false
                default:
                    true
                }
            })?.identifier
            
            if newValue == firstIdentifier {
                timelineContext.send(viewAction: .paginateBackwards)
            }
        }
    }
    
    @ViewBuilder func viewForTimelineItem(_ item: RoomTimelineItemViewState) -> some View {
        switch item.type {
        case .image(let timelineItem):
            LoadableImage(mediaSource: timelineItem.content.thumbnailInfo?.source ?? timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.thumbnailInfo?.size ?? timelineItem.content.imageInfo.size,
                          mediaProvider: timelineContext.mediaProvider) {
                placeholder
            }
            .mediaItemAspectRatio(imageInfo: timelineItem.content.thumbnailInfo ?? timelineItem.content.imageInfo)
        case .video(let timelineItem):
            if let thumbnailSource = timelineItem.content.thumbnailInfo?.source {
                LoadableImage(mediaSource: thumbnailSource,
                              mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                              blurhash: timelineItem.content.blurhash,
                              size: timelineItem.content.thumbnailInfo?.size,
                              mediaProvider: timelineContext.mediaProvider) { imageView in
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
    
    var playIcon: some View {
        Image(systemName: "play.circle.fill")
            .resizable()
            .frame(width: 50, height: 50)
            .background(.ultraThinMaterial, in: Circle())
            .foregroundColor(.white)
    }
    
    var placeholder: some View {
        Rectangle()
            .foregroundColor(.compound._bgBubbleIncoming)
            .opacity(0.3)
    }
}

extension View {
    @ViewBuilder
    var scrollAnchor: some View {
        if #available(iOS 18.0, *) {
            defaultScrollAnchor(.bottom, for: .sizeChanges)
                .defaultScrollAnchor(.bottom, for: .alignment)
                .defaultScrollAnchor(.bottom, for: .initialOffset)
        } else {
            defaultScrollAnchor(.bottom)
        }
    }
    
    /// Constrains the max height of a media item in the timeline, whilst preserving its aspect ratio.
    @ViewBuilder
    func mediaItemAspectRatio(imageInfo: ImageInfoProxy?) -> some View {
        aspectRatio(imageInfo?.aspectRatio, contentMode: .fill)
    }
}

// MARK: - Previews

struct MediaEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = MediaEventsTimelineScreenViewModel(analyticsService: ServiceLocator.shared.analytics)
    static let emptyTimelineViewModel: TimelineViewModel = {
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
        
    static var previews: some View {
        NavigationStack {
            MediaEventsTimelineScreen(context: viewModel.context, timelineContext: emptyTimelineViewModel.context)
        }
    }
}
