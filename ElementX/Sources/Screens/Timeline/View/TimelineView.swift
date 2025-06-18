//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import WysiwygComposer

struct TimelineView: View {
    @ObservedObject var timelineContext: TimelineViewModel.Context
    @State private var dragOver = false
    
    var body: some View {
        TimelineViewRepresentable()
            .id(timelineContext.viewState.roomID)
            // It is tempting to inject these environment values last to avoid also injecting them into the sheets,
            // and that approach works great on iOS. But it doesn't work on macOS (as of 15.5) where the app goes 💥
            .environmentObject(timelineContext)
            .environment(\.timelineContext, timelineContext)
            .environment(\.focussedEventID, timelineContext.viewState.timelineState.focussedEvent?.eventID)
            .alert(item: $timelineContext.alertInfo)
            .sheet(item: $timelineContext.manageMemberViewModel) {
                ManageRoomMemberSheetView(context: $0.context)
            }
            .sheet(item: $timelineContext.debugInfo) { TimelineItemDebugView(info: $0) }
            .sheet(item: $timelineContext.actionMenuInfo) { info in
                let actions = TimelineItemMenuActionProvider(timelineItem: info.item,
                                                             canCurrentUserSendMessage: timelineContext.viewState.canCurrentUserSendMessage,
                                                             canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                                             canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                                             canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                                             pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                                             isDM: timelineContext.viewState.isDirectOneToOneRoom,
                                                             isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                                             areThreadsEnabled: timelineContext.viewState.areThreadsEnabled,
                                                             timelineKind: timelineContext.viewState.timelineKind,
                                                             emojiProvider: timelineContext.viewState.emojiProvider)
                    .makeActions()
                if let actions {
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(timelineContext)
                }
            }
            .sheet(item: $timelineContext.reactionSummaryInfo) {
                ReactionsSummaryView(reactions: $0.reactions,
                                     members: timelineContext.viewState.members,
                                     mediaProvider: timelineContext.mediaProvider,
                                     selectedReactionKey: $0.selectedKey)
                    .edgesIgnoringSafeArea([.bottom])
            }
            .sheet(item: $timelineContext.readReceiptsSummaryInfo) {
                ReadReceiptsSummaryView(orderedReadReceipts: $0.orderedReceipts)
                    .environmentObject(timelineContext)
            }
            .onDrop(of: ["public.item", "public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                guard let provider = providers.first,
                      provider.isSupportedForPasteOrDrop else {
                    return false
                }
                
                timelineContext.send(viewAction: .handlePasteOrDrop(provider: provider))
                return true
            }
    }
}

/// A table view wrapper that displays the timeline of a room.
struct TimelineViewRepresentable: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModelContext: TimelineViewModel.Context
    @Environment(\.openURL) var openURL

    func makeUIViewController(context: Context) -> TimelineTableViewController {
        let tableViewController = TimelineTableViewController(coordinator: context.coordinator,
                                                              isScrolledToBottom: $viewModelContext.isScrolledToBottom,
                                                              scrollToBottomPublisher: viewModelContext.viewState.timelineState.scrollToBottomPublisher)
        // Needs to be dispatched on main asynchronously otherwise we get a runtime warning
        DispatchQueue.main.async {
            viewModelContext.send(viewAction: .setOpenURLAction(openURL))
        }
        return tableViewController
    }
    
    func updateUIViewController(_ uiViewController: TimelineTableViewController, context: Context) {
        context.coordinator.update(tableViewController: uiViewController)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModelContext: viewModelContext)
    }
    
    // MARK: - Coordinator
    
    @MainActor
    class Coordinator {
        let context: TimelineViewModel.Context
        
        init(viewModelContext: TimelineViewModel.Context) {
            context = viewModelContext
        }
        
        /// Updates the specified table view's properties from the current view state.
        func update(tableViewController: TimelineTableViewController) {
            if tableViewController.isSwitchingTimelines != context.viewState.timelineState.isSwitchingTimelines {
                // Must come before timelineItemsDictionary in order to disable animations.
                tableViewController.isSwitchingTimelines = context.viewState.timelineState.isSwitchingTimelines
            }
            if tableViewController.timelineItemsDictionary != context.viewState.timelineState.itemsDictionary {
                tableViewController.timelineItemsDictionary = context.viewState.timelineState.itemsDictionary
            }
            if tableViewController.paginationState != context.viewState.timelineState.paginationState {
                tableViewController.paginationState = context.viewState.timelineState.paginationState
            }
            if tableViewController.isLive != context.viewState.timelineState.isLive {
                tableViewController.isLive = context.viewState.timelineState.isLive
            }
            if tableViewController.focussedEvent != context.viewState.timelineState.focussedEvent {
                tableViewController.focussedEvent = context.viewState.timelineState.focussedEvent
            }
            if tableViewController.hideTimelineMedia != context.viewState.hideTimelineMedia {
                tableViewController.hideTimelineMedia = context.viewState.hideTimelineMedia
            }
            
            if tableViewController.typingMembers.members != context.viewState.typingMembers {
                tableViewController.setTypingMembers(context.viewState.typingMembers)
            }
        }
        
        func send(viewAction: TimelineViewAction) {
            context.send(viewAction: viewAction)
        }
    }
}

// MARK: - Previews

struct TimelineView_Previews: PreviewProvider, TestablePreview {
    static let roomProxyMock = JoinedRoomProxyMock(.init(id: "stable_id",
                                                         name: "Preview room"))
    static let roomViewModel = RoomScreenViewModel.mock(roomProxyMock: roomProxyMock)
    static let timelineViewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                                     timelineController: MockTimelineController(),
                                                     mediaProvider: MediaProviderMock(configuration: .init()),
                                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     appMediator: AppMediatorMock.default,
                                                     appSettings: ServiceLocator.shared.settings,
                                                     analyticsService: ServiceLocator.shared.analytics,
                                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                     clientProxy: ClientProxyMock(.init()))

    static var previews: some View {
        NavigationStack {
            RoomScreen(context: roomViewModel.context,
                       timelineContext: timelineViewModel.context,
                       composerToolbar: ComposerToolbar.mock())
        }
    }
}
