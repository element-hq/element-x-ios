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
    
    private var isSelectionActive: Bool {
        timelineContext.viewState.selection.isActive
    }
    
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
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if isSelectionActive {
                    TimelineSelectionActionBar(context: timelineContext)
                }
            }
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
        if isSelectionActive {
            TimelineSelectionToolbar {
                timelineContext.send(viewAction: .clearSelection)
            }
        } else {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.actionClose) {
                    context.send(viewAction: .close)
                }
            }
        }
    }
}

// MARK: - Previews

struct PinnedEventsTimelineScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = PinnedEventsTimelineScreenViewModel(roomProxy: JoinedRoomProxyMock(.init()),
                                                               userIndicatorController: UserIndicatorControllerMock(),
                                                               appSettings: .volatile(),
                                                               analyticsService: AnalyticsServiceMock(.init()))
    
    static let emptyTimelineViewModel = makeTimelineViewModel(timelineItems: [])
    static let selectingTimelineViewModel = makeTimelineViewModel(timelineItems: TimelineFixtures.default, isSelecting: true)
    
    static var previews: some View {
        ElementNavigationStack {
            PinnedEventsTimelineScreen(context: viewModel.context, timelineContext: emptyTimelineViewModel.context)
        }
        .previewDisplayName("Empty")
        
        ElementNavigationStack {
            PinnedEventsTimelineScreen(context: viewModel.context, timelineContext: selectingTimelineViewModel.context)
        }
        .previewDisplayName("Selecting")
        .snapshotPreferences(expect: selectingTimelineViewModel.context.$viewState.map(\.selection.isActive))
    }
    
    static func makeTimelineViewModel(timelineItems: [RoomTimelineItemProtocol], isSelecting: Bool = false) -> TimelineViewModel {
        let eventIDs = timelineItems.compactMap { ($0 as? EventBasedTimelineItemProtocol)?.id.eventID }
        let timelineController = TimelineControllerMock(.init(timelineKind: .pinned, timelineItems: timelineItems))
        
        let appSettings = AppSettings.volatile()
        appSettings.messageMultiSelectEnabled = isSelecting
        
        let timelineViewModel = TimelineViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Preview room", pinnedEventIDs: Set(eventIDs))),
                                                  timelineController: timelineController,
                                                  userSession: UserSessionMock(.init()),
                                                  mediaPlayerProvider: MediaPlayerProviderMock(),
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appMediator: AppMediatorMock(.init()),
                                                  appSettings: appSettings,
                                                  analyticsService: AnalyticsServiceMock(.init()),
                                                  emojiProvider: EmojiProvider(appSettings: appSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        if isSelecting {
            timelineViewModel.state.selection.selectedEventIDs = Set(eventIDs.prefix(2))
        }
        
        return timelineViewModel
    }
}
