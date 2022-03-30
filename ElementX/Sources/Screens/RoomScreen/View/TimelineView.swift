//
//  TimelineView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 30/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

import Introspect

struct TimelineView: View {
    
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
                        .environment(\.openURL, OpenURLAction { url in
                            context.send(viewAction: .linkClicked(url: url))
                            return .systemAction
                        })
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 0.0)
            .introspectTableView { tableView in
                if tableView == tableViewObserver.tableView {
                    return
                }
                
                tableViewObserver = TableViewObserver(tableView: tableView,
                                                      topDetectionOffset: (tableView.bounds.size.height / 3.0))
                
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
    
    private let topDetectionOffset: CGFloat
    private var isAtTop: Bool = false
    private var offsetDetails: ContentOffsetDetails?
    
    private(set) var tableView: UITableView?
    
    let scrollViewDidRest = PassthroughSubject<Void, Never>()
    let scrollViewDidReachTop = PassthroughSubject<Void, Never>()
    
    override init() {
        self.topDetectionOffset = 0.0
    }
    
    init(tableView: UITableView, topDetectionOffset: CGFloat) {
        self.tableView = tableView
        self.topDetectionOffset = topDetectionOffset
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

        return (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) <= topDetectionOffset
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
