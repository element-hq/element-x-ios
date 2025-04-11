//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ThreadTimelineScreen: View {
    @ObservedObject var context: ThreadTimelineScreenViewModel.Context
    @ObservedObject var timelineContext: TimelineViewModel.Context
        
    var body: some View {
        content
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .interactiveDismissDisabled()
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
            .sheet(item: $timelineContext.manageMemberViewModel) {
                ManageRoomMemberSheetView(context: $0.context)
            }
            .sheet(item: $timelineContext.debugInfo) { TimelineItemDebugView(info: $0) }
    }
    
    @ViewBuilder
    private var content: some View {
        TimelineView()
            .id(timelineContext.viewState.roomID)
            .environmentObject(timelineContext)
            .environment(\.focussedEventID, timelineContext.viewState.timelineState.focussedEvent?.eventID)
    }
}

// MARK: - Previews

struct ThreadTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ThreadTimelineScreenViewModel()
    static let emptyTimelineViewModel: TimelineViewModel = {
        let timelineController = MockTimelineController(timelineKind: .pinned)
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
                                 emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                 timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                 clientProxy: ClientProxyMock(.init()))
    }()
        
    static var previews: some View {
        NavigationStack {
            ThreadTimelineScreen(context: viewModel.context, timelineContext: emptyTimelineViewModel.context)
        }
        .previewDisplayName("Empty")
    }
}
