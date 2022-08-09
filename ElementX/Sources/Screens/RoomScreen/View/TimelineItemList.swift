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

import Combine
import Introspect
import SwiftUI

struct TimelineItemList: View {
    @State private var tableViewObserver = ListTableViewAdapter()
    @State private var timelineItems: [RoomTimelineViewProvider] = []
    @State private var hasPendingChanges = false
    @ObservedObject private var settings = ElementSettings.shared
    
    @ObservedObject var context: RoomScreenViewModel.Context
    
    let bottomVisiblePublisher: PassthroughSubject<Bool, Never>
    let scrollToBottomPublisher: PassthroughSubject<Void, Never>
    
    var body: some View {
        // The observer behaves differently when not in an reader
        ScrollViewReader { _ in
            List {
                HStack {
                    Spacer()
                    ProgressView()
                        .opacity(context.viewState.isBackPaginating ? 1.0 : 0.0)
                        .animation(.default, value: context.viewState.isBackPaginating)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                
                // No idea why previews don't work otherwise
                ForEach(isPreview ? context.viewState.items : timelineItems) { timelineItem in
                    timelineItem
                        .contextMenu(menuItems: {
                            context.viewState.contextMenuBuilder?(timelineItem.id)
                        })
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(settings.timelineStyle.listRowInsets)
                        .onAppear {
                            context.send(viewAction: .itemAppeared(id: timelineItem.id))
                        }
                        .onDisappear {
                            context.send(viewAction: .itemDisappeared(id: timelineItem.id))
                        }
                        .environment(\.openURL, OpenURLAction { url in
                            context.send(viewAction: .linkClicked(url: url))
                            return .systemAction
                        })
                }
            }
            .listStyle(.plain)
            .timelineStyle(settings.timelineStyle)
            .environment(\.defaultMinListRowHeight, 0.0)
            .introspectTableView { tableView in
                if tableView == tableViewObserver.tableView {
                    return
                }
                
                tableViewObserver = ListTableViewAdapter(tableView: tableView,
                                                         topDetectionOffset: tableView.bounds.size.height / 3.0,
                                                         bottomDetectionOffset: 10.0)
                
                tableViewObserver.scrollToBottom()
                
                // Check if there are enough items. Otherwise ask for more
                attemptBackPagination()
            }
            .onAppear(perform: {
                if timelineItems != context.viewState.items {
                    timelineItems = context.viewState.items
                }
            })
            .onReceive(scrollToBottomPublisher, perform: {
                tableViewObserver.scrollToBottom(animated: true)
            })
            .onReceive(tableViewObserver.scrollViewTopVisiblePublisher, perform: { isTopVisible in
                if !isTopVisible || context.viewState.isBackPaginating {
                    return
                }
                
                attemptBackPagination()
            })
            .onReceive(tableViewObserver.scrollViewBottomVisiblePublisher, perform: { isBottomVisible in
                bottomVisiblePublisher.send(isBottomVisible)
            })
            .onChange(of: context.viewState.items) { _ in
                // Don't update the list while moving
                if tableViewObserver.isDecelerating || tableViewObserver.isTracking {
                    hasPendingChanges = true
                    return
                }
                
                tableViewObserver.saveCurrentOffset()
                timelineItems = context.viewState.items
            }
            .onReceive(tableViewObserver.scrollViewDidRestPublisher, perform: {
                if hasPendingChanges == false {
                    return
                }
                
                tableViewObserver.saveCurrentOffset()
                timelineItems = context.viewState.items
                hasPendingChanges = false
            })
            .onChange(of: timelineItems, perform: { _ in
                tableViewObserver.restoreSavedOffset()
                
                // Check if there are enough items. Otherwise ask for more
                attemptBackPagination()
            })
        }
    }
    
    func scrollToBottom(animated: Bool = false) {
        tableViewObserver.scrollToBottom(animated: animated)
    }
    
    private func attemptBackPagination() {
        if context.viewState.isBackPaginating {
            return
        }
        
        if tableViewObserver.scrollViewTopVisiblePublisher.value == false {
            return
        }
        
        context.send(viewAction: .loadPreviousPage)
    }
    
    private var isPreview: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
        #else
        return false
        #endif
    }
}

struct TimelineItemList_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            roomName: nil)
        
        TimelineItemList(context: viewModel.context, bottomVisiblePublisher: PassthroughSubject(), scrollToBottomPublisher: PassthroughSubject())
    }
}
