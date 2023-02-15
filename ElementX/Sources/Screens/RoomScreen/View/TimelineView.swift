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

/// A table view wrapper that displays the timeline of a room.
struct TimelineView: UIViewControllerRepresentable {
    @EnvironmentObject private var viewModelContext: RoomScreenViewModel.Context
    @Environment(\.timelineStyle) private var timelineStyle
    
    func makeUIViewController(context: Context) -> TimelineTableViewController {
        let tableViewController = TimelineTableViewController(coordinator: context.coordinator,
                                                              timelineStyle: timelineStyle,
                                                              scrollToBottomButtonVisible: $viewModelContext.scrollToBottomButtonVisible,
                                                              scrollToBottomPublisher: viewModelContext.viewState.scrollToBottomPublisher)
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
            
            if viewModelContext.viewState.items.isEmpty {
                viewModelContext.send(viewAction: .paginateBackwards)
            }
        }
        
        /// Updates the specified table view's properties from the current view state.
        func update(tableViewController: TimelineTableViewController, timelineStyle: TimelineStyle) {
            if tableViewController.timelineStyle != timelineStyle {
                tableViewController.timelineStyle = timelineStyle
            }
            if tableViewController.timelineItems != context.viewState.items {
                tableViewController.timelineItems = context.viewState.items
            }
            if tableViewController.canBackPaginate != context.viewState.canBackPaginate {
                tableViewController.canBackPaginate = context.viewState.canBackPaginate
            }
            if tableViewController.isBackPaginating != context.viewState.isBackPaginating {
                tableViewController.isBackPaginating = context.viewState.isBackPaginating
            }
            if tableViewController.composerMode != context.viewState.composerMode {
                tableViewController.composerMode = context.viewState.composerMode
            }
            
            // Doesn't have an equatable conformance :(
            tableViewController.contextMenuActionProvider = context.viewState.contextMenuActionProvider
        }
        
        func send(viewAction: RoomScreenViewAction) {
            context.send(viewAction: viewAction)
        }
    }
}

// MARK: - Previews

struct TimelineTableView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               roomName: "Preview room")
    
    static var previews: some View {
        NavigationView {
            RoomScreen(context: viewModel.context)
        }
    }
}
