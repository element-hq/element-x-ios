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
        
    var body: some View {
        content
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .interactiveDismissDisabled()
            .interactiveQuickLook(item: $timelineContext.mediaPreviewItem)
            .sheet(item: $timelineContext.debugInfo) { TimelineItemDebugView(info: $0) }
            .sheet(item: $timelineContext.actionMenuInfo) { info in
                let actions = TimelineItemMenuActionProvider(timelineItem: info.item,
                                                             canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                                             canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                                             canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                                             pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                                             isDM: timelineContext.viewState.isEncryptedOneToOneRoom,
                                                             isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                                             isCreateMediaCaptionsEnabled: timelineContext.viewState.isCreateMediaCaptionsEnabled,
                                                             isPinnedEventsTimeline: timelineContext.viewState.isPinnedEventsTimeline,
                                                             emojiProvider: timelineContext.viewState.emojiProvider)
                    .makeActions()
                if let actions {
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(timelineContext)
                }
            }
            .task {
                timelineContext.send(viewAction: .paginateBackwards)
            }
    }
    
    @ViewBuilder
    private var content: some View {
        let collumns = Array(repeating: GridItem(.flexible(minimum: 50)), count: 5)
        
        ScrollView {
            LazyVGrid(columns: collumns) {
                ForEach(timelineContext.viewState.timelineViewState.itemViewStates) { item in
//                    viewForTimelineItem(item)
                    Rectangle()
                        .frame(height: 50)
                }
            }
        }
        .defaultScrollAnchor(.bottom)
    }
    
    @ViewBuilder func viewForTimelineItem(_ item: RoomTimelineItemViewState) -> some View {
        switch item.type {
        case .image(let timelineItem):
            LoadableImage(mediaSource: timelineItem.content.imageInfo.source,
                          mediaType: .timelineItem(uniqueID: timelineItem.id.uniqueID.id),
                          blurhash: timelineItem.content.blurhash,
                          size: timelineItem.content.imageInfo.size,
                          mediaProvider: timelineContext.mediaProvider) {
                Rectangle()
                    .foregroundColor(.compound._bgBubbleOutgoing)
                    .opacity(0.3)
            }
            .frame(height: 50)
            .aspectRatio(contentMode: .fill)
        default:
            EmptyView()
        }
    }
}

// MARK: - Previews

struct MediaEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = MediaEventsTimelineScreenViewModel(analyticsService: ServiceLocator.shared.analytics)
    static let emptyTimelineViewModel: TimelineViewModel = {
        let timelineController = MockRoomTimelineController(timelineKind: .media)
        timelineController.timelineItems = []
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
