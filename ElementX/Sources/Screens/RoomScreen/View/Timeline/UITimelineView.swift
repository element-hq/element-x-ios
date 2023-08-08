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
struct UITimelineView: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModelContext: RoomScreenViewModel.Context
    @Environment(\.timelineStyle) private var timelineStyle
    
    func makeUIViewController(context: Context) -> TimelineTableViewController {
        let tableViewController = TimelineTableViewController(coordinator: context.coordinator,
                                                              timelineStyle: timelineStyle,
                                                              isScrolledToBottom: $viewModelContext.isScrolledToBottom,
                                                              scrollToBottomPublisher: viewModelContext.viewState.timelineViewState.scrollToBottomPublisher)
        return tableViewController
    }
    
    func updateUIViewController(_ uiViewController: TimelineTableViewController, context: Context) {
        context.coordinator.update(tableViewController: uiViewController, timelineStyle: timelineStyle)
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
            
            if viewModelContext.viewState.timelineViewState.itemViewStates.isEmpty {
                viewModelContext.send(viewAction: .paginateBackwards)
            }
        }
        
        /// Updates the specified table view's properties from the current view state.
        func update(tableViewController: TimelineTableViewController, timelineStyle: TimelineStyle) {
            if tableViewController.timelineStyle != timelineStyle {
                tableViewController.timelineStyle = timelineStyle
            }
            if tableViewController.timelineItemsDictionary != context.viewState.timelineViewState.itemsDictionary {
                tableViewController.timelineItemsDictionary = context.viewState.timelineViewState.itemsDictionary
            }
            if tableViewController.canBackPaginate != context.viewState.timelineViewState.canBackPaginate {
                tableViewController.canBackPaginate = context.viewState.timelineViewState.canBackPaginate
            }
            if tableViewController.isBackPaginating != context.viewState.timelineViewState.isBackPaginating {
                tableViewController.isBackPaginating = context.viewState.timelineViewState.isBackPaginating
            }
            
            // Doesn't have an equatable conformance :(
            tableViewController.contextMenuActionProvider = context.viewState.timelineItemMenuActionProvider
        }
        
        func send(viewAction: RoomScreenViewAction) {
            context.send(viewAction: viewAction)
        }
    }
}

// MARK: - Previews

struct UITimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")),
                                               appSettings: ServiceLocator.shared.settings,
                                               analytics: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController)

    static let wysiwygViewModel = WysiwygComposerViewModel()
    static let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel)
    static let composerToolbar = ComposerToolbar(context: composerViewModel.context,
                                                 wysiwygViewModel: wysiwygViewModel,
                                                 keyCommandHandler: { _ in false })
    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context, composerToolbar: composerToolbar)
        }
    }
}
