//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import WysiwygComposer

/// A table view wrapper that displays the timeline of a room.
struct TimelineView: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModelContext: RoomScreenViewModel.Context
    
    func makeUIViewController(context: Context) -> TimelineTableViewController {
        let tableViewController = TimelineTableViewController(coordinator: context.coordinator,
                                                              isScrolledToBottom: $viewModelContext.isScrolledToBottom,
                                                              scrollToBottomPublisher: viewModelContext.viewState.timelineViewState.scrollToBottomPublisher)
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
        let context: RoomScreenViewModel.Context
        
        init(viewModelContext: RoomScreenViewModel.Context) {
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
        
        func send(viewAction: RoomScreenViewAction) {
            context.send(viewAction: viewAction)
        }
    }
}

// MARK: - Previews

struct TimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomScreenViewModel(roomProxy: RoomProxyMock(.init(id: "stable_id",
                                                                              name: "Preview room")),
                                               timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               mediaPlayerProvider: MediaPlayerProviderMock(),
                                               voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               networkMonitor: ServiceLocator.shared.networkMonitor, appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings,
                                               analyticsService: ServiceLocator.shared.analytics)

    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context, composerToolbar: ComposerToolbar.mock())
        }
    }
}
