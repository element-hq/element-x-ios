//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI
import WysiwygComposer

/// A table view wrapper that displays the timeline of a room.
struct TimelineView: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModelContext: TimelineViewModel.Context
    @Environment(\.openURL) var openURL

    func makeUIViewController(context: Context) -> TimelineTableViewController {
        let tableViewController = TimelineTableViewController(coordinator: context.coordinator,
                                                              isScrolledToBottom: $viewModelContext.isScrolledToBottom,
                                                              scrollToBottomPublisher: viewModelContext.viewState.timelineViewState.scrollToBottomPublisher)
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
            if tableViewController.isSwitchingTimelines != context.viewState.timelineViewState.isSwitchingTimelines {
                // Must come before timelineItemsDictionary in order to disable animations.
                tableViewController.isSwitchingTimelines = context.viewState.timelineViewState.isSwitchingTimelines
            }
            if tableViewController.timelineItemsDictionary != context.viewState.timelineViewState.itemsDictionary {
                tableViewController.timelineItemsDictionary = context.viewState.timelineViewState.itemsDictionary
            }
            if tableViewController.paginationState != context.viewState.timelineViewState.paginationState {
                tableViewController.paginationState = context.viewState.timelineViewState.paginationState
            }
            if tableViewController.isLive != context.viewState.timelineViewState.isLive {
                tableViewController.isLive = context.viewState.timelineViewState.isLive
            }
            if tableViewController.focussedEvent != context.viewState.timelineViewState.focussedEvent {
                tableViewController.focussedEvent = context.viewState.timelineViewState.focussedEvent
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
                                                     timelineController: MockRoomTimelineController(),
                                                     mediaProvider: MockMediaProvider(),
                                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     appMediator: AppMediatorMock.default,
                                                     appSettings: ServiceLocator.shared.settings,
                                                     analyticsService: ServiceLocator.shared.analytics)

    static var previews: some View {
        NavigationStack {
            RoomScreen(roomViewModel: roomViewModel,
                       timelineViewModel: timelineViewModel,
                       composerToolbar: ComposerToolbar.mock())
        }
    }
}
