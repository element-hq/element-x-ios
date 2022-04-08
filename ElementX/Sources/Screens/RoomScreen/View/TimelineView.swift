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
                
                tableViewObserver.scrollToBottom()
                
                // Check if there are enough items. Otherwise ask for more
                attemptBackPagination()
            }
            .onAppear(perform: {
                if timelineItems != context.viewState.items {
                    timelineItems = context.viewState.items
                }
            })
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
    
    private var contentOffsetObserverToken: NSKeyValueObservation?
    
    private var isAtTop: Bool = false
    private var offsetDetails: ContentOffsetDetails?
    private var draggingInitiated = false
    
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
        
        // Don't attempt stealing the UITableView delegate away from the List.
        // Doing so results in undefined behavior e.g. context menus not working
        contentOffsetObserverToken = tableView.observe(\.contentOffset, options: .new, changeHandler: { [weak self] _, _ in
            self?.handleScrollViewScroll()
        })
        
        tableView.panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
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
    
    func scrollToBottom() {
        guard let tableView = tableView,
              tableView.numberOfSections > 0  else {
                  return
        }
        
        let currentItemCount = tableView.numberOfRows(inSection: 0)
        guard currentItemCount > 1 else {
            return
        }
        
        tableView.scrollToRow(at: .init(row: currentItemCount - 1, section: 0), at: .bottom, animated: false)
    }
    
    // MARK: - Private
    
    private func handleScrollViewScroll() {
        guard let tableView = self.tableView else {
            return
        }
        
        let isTopVisible = self.isTopVisible
        if self.isTopVisible && self.isAtTop != isTopVisible {
            self.scrollViewDidReachTop.send(())
        }
        
        self.isAtTop = isTopVisible
        
        if !self.draggingInitiated && tableView.isDragging {
            self.draggingInitiated = true
        } else if self.draggingInitiated && !tableView.isDragging {
            self.draggingInitiated = false
            self.scrollViewDidRest.send(())
        }
    }
    
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let tableView = self.tableView,
              sender.state == .ended,
              draggingInitiated == true,
              !tableView.isDecelerating else {
                  return
        }
        
        self.draggingInitiated = false
        self.scrollViewDidRest.send(())
    }
    
    private var isBottomVisible: Bool {
        guard let scrollView = tableView else {
            return false
        }

        return (scrollView.contentOffset.y) >= (scrollView.contentSize.height - scrollView.frame.size.height)
    }
}
