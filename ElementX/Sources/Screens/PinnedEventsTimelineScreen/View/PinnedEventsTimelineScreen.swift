//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct PinnedEventsTimelineScreen: View {
    @ObservedObject var context: PinnedEventsTimelineScreenViewModel.Context
    @ObservedObject var timelineContext: TimelineViewModel.Context
    
    private var title: String {
        let pinnedEventIDs = timelineContext.viewState.pinnedEventIDs
        guard !pinnedEventIDs.isEmpty else {
            return L10n.screenPinnedTimelineScreenTitleEmpty
        }
        return L10n.screenPinnedTimelineScreenTitle(pinnedEventIDs.count)
    }
    
    var body: some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .background(.compound.bgCanvasDefault)
            .interactiveDismissDisabled()
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
    }
    
    @ViewBuilder
    private var content: some View {
        if timelineContext.viewState.pinnedEventIDs.isEmpty {
            VStack(spacing: 16) {
                BigIcon(icon: \.pin)
                Text(L10n.screenPinnedTimelineEmptyStateHeadline)
                    .font(.compound.headingSMSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.screenPinnedTimelineEmptyStateDescription(L10n.actionPin))
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
                Spacer()
            }
            .padding(.top, 48)
            .padding(.horizontal, 16)
        } else {
            TimelineView(timelineContext: timelineContext)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionClose) {
                context.send(viewAction: .close)
            }
        }
    }
}

// MARK: - Previews

struct PinnedEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = PinnedEventsTimelineScreenViewModel(roomProxy: JoinedRoomProxyMock(.init()),
                                                               userIndicatorController: UserIndicatorControllerMock(),
                                                               appSettings: AppSettings(),
                                                               analyticsService: ServiceLocator.shared.analytics)
    
    static let emptyTimelineViewModel: TimelineViewModel = {
        let timelineController = MockTimelineController(timelineKind: .pinned)
        timelineController.timelineItems = []
        return TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Preview room")),
                                 timelineController: timelineController,
                                 userSession: UserSessionMock(.init()),
                                 mediaPlayerProvider: MediaPlayerProviderMock(),
                                 userIndicatorController: UserIndicatorControllerMock(),
                                 appMediator: AppMediatorMock.default,
                                 appSettings: ServiceLocator.shared.settings,
                                 analyticsService: ServiceLocator.shared.analytics,
                                 emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                 linkMetadataProvider: LinkMetadataProvider(),
                                 timelineControllerFactory: TimelineControllerFactoryMock(.init()))
    }()
        
    static var previews: some View {
        NavigationStack {
            PinnedEventsTimelineScreen(context: viewModel.context, timelineContext: emptyTimelineViewModel.context)
        }
        .previewDisplayName("Empty")
    }
}
