//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
                                                             timelineKind: timelineContext.viewState.timelineKind,
                                                             emojiProvider: timelineContext.viewState.emojiProvider)
                    .makeActions()
                if let actions {
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(timelineContext)
                }
            }
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
            TimelineView()
                .id(timelineContext.viewState.roomID)
                .environmentObject(timelineContext)
                .environment(\.focussedEventID, timelineContext.viewState.timelineState.focussedEvent?.eventID)
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
    static let viewModel = PinnedEventsTimelineScreenViewModel(analyticsService: ServiceLocator.shared.analytics)
    static let emptyTimelineViewModel: TimelineViewModel = {
        let timelineController = MockRoomTimelineController(timelineKind: .pinned)
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
            PinnedEventsTimelineScreen(context: viewModel.context, timelineContext: emptyTimelineViewModel.context)
        }
        .previewDisplayName("Empty")
    }
}
