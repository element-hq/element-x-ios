// 
// Copyright 2021 New Vector Ltd
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
import Introspect
import Combine

struct RoomScreen: View {
    
    @State private var tableViewObserver: TableViewObserver = TableViewObserver()
    @State private var timelineItems: [RoomTimelineViewProvider] = []
    @State private var hasPendingChanges = false
    @State private var text: String = ""
    
    @ObservedObject var context: RoomScreenViewModel.Context
    
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
                
                // No idea why previews don't work otherwise
                ForEach(isPreview ? context.viewState.items : timelineItems) { timelineItem in
                    timelineItem
                        .listRowSeparator(.hidden)
                        .onAppear {
                            context.send(viewAction: .itemAppeared(id: timelineItem.id))
                        }
                        .onDisappear {
                            context.send(viewAction: .itemDisappeared(id: timelineItem.id))
                        }
                }
            }
            .listStyle(.plain)
            .navigationTitle(context.viewState.roomTitle)
            .environment(\.defaultMinListRowHeight, 0.0)
            .navigationBarTitleDisplayMode(.inline)
            .introspectTableView { tableView in
                if tableView == tableViewObserver.tableView {
                    return
                }
                
                tableViewObserver = TableViewObserver(tableView: tableView)
                
                // Check if there are enough items. Otherwise ask for more
                attemptBackPagination()
            }
            .onReceive(tableViewObserver.scrollViewDidReachTop, perform: {
                if context.viewState.isBackPaginating {
                    return
                }
                
                attemptBackPagination()
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
            .onReceive(tableViewObserver.scrollViewDidRest, perform: {
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
    
    private func attemptBackPagination() {
        if context.viewState.isBackPaginating {
            return
        }
        
        if tableViewObserver.isTopVisible == false {
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

private class TableViewObserver: NSObject, UITableViewDelegate {
    
    private enum ContentOffsetDetails {
        case topOffset(previousVisibleIndexPath: IndexPath, previousItemCount: Int)
        case bottomOffset
    }
    
    private let topTriggerHeight = 50.0
    private var isAtTop: Bool = false
    private var offsetDetails: ContentOffsetDetails?
    
    private(set) var tableView: UITableView?
    
    let scrollViewDidRest = PassthroughSubject<Void, Never>()
    let scrollViewDidReachTop = PassthroughSubject<Void, Never>()
    
    override init() {
        
    }
    
    init(tableView: UITableView) {
        self.tableView = tableView
        super.init()
        
        tableView.delegate = self
    }
    
    func saveCurrentOffset() {
        guard let tableView = tableView,
              tableView.numberOfSections > 0 else {
            return
        }
    
        if isBottomVisible {
            offsetDetails = .bottomOffset
        } else if isTopVisible {
            if let topIndexPath = tableView.indexPathsForVisibleRows?.first {
                offsetDetails = .topOffset(previousVisibleIndexPath: topIndexPath,
                                           previousItemCount: tableView.numberOfRows(inSection: 0))
            }
        }
    }
    
    func restoreSavedOffset() {
        defer {
            offsetDetails = nil
        }
        
        guard let tableView = tableView,
              tableView.numberOfSections > 0  else {
                  return
        }
        
        let currentItemCount = tableView.numberOfRows(inSection: 0)
        
        switch offsetDetails {
        case .bottomOffset:
            tableView.scrollToRow(at: .init(row: max(0, currentItemCount - 1), section: 0), at: .bottom, animated: false)
        case .topOffset(let indexPath, let previousItemCount):
            let row = indexPath.row + max(0, (currentItemCount - previousItemCount))
            if row < currentItemCount {
                tableView.scrollToRow(at: .init(row: row, section: 0), at: .top, animated: false)
            }
        case .none:
            break
        }
    }
    
    var isTracking: Bool {
        self.tableView?.isTracking == true
    }
    
    var isDecelerating: Bool {
        self.tableView?.isDecelerating == true
    }
    
    var isTopVisible: Bool {
        guard let scrollView = tableView else {
            return false
        }

        return (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) <= topTriggerHeight
    }
    
    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let isTopVisible = isTopVisible
        if isTopVisible && isAtTop != isTopVisible {
            scrollViewDidReachTop.send(())
        }
        
        isAtTop = isTopVisible
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scrollViewDidRest.send(())
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerating: Bool) {
        if decelerating == false {
            scrollViewDidRest.send(())
        }
    }
    
    // MARK: - Private
    
    private var isBottomVisible: Bool {
        guard let scrollView = tableView else {
            return false
        }

        return (scrollView.contentOffset.y) >= (scrollView.contentSize.height - scrollView.frame.size.height)
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RoomScreenViewModel(roomProxy: MockRoomProxy(displayName: "Test"),
                                            timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory())
        
        RoomScreen(context: viewModel.context)
    }
}
