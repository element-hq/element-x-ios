//
//  ListTableViewAdapter.swift
//  ElementX
//
//  Created by Stefan Ceriu on 15/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import UIKit

class ListTableViewAdapter: NSObject, UITableViewDelegate {
    
    private enum ContentOffsetDetails {
        case topOffset(previousVisibleIndexPath: IndexPath, previousItemCount: Int)
        case bottomOffset
    }
    
    private let topDetectionOffset: CGFloat
    private let bottomDetectionOffset: CGFloat
    
    private var contentOffsetObserverToken: NSKeyValueObservation?
    private var boundsObserverToken: NSKeyValueObservation?
    
    private var offsetDetails: ContentOffsetDetails?
    private var draggingInitiated = false
    private var isAnimatingKeyboardAppearance = false
    private var previousFrame: CGRect = .zero
    
    private(set) var tableView: UITableView?
        
    let scrollViewDidRestPublisher = PassthroughSubject<Void, Never>()
    let scrollViewTopVisiblePublisher = CurrentValueSubject<Bool, Never>(false)
    let scrollViewBottomVisiblePublisher = CurrentValueSubject<Bool, Never>(false)
    
    override init() {
        topDetectionOffset = 0.0
        bottomDetectionOffset = 0.0
    }
    
    init(tableView: UITableView, topDetectionOffset: CGFloat, bottomDetectionOffset: CGFloat) {
        self.tableView = tableView
        self.topDetectionOffset = topDetectionOffset
        self.bottomDetectionOffset = bottomDetectionOffset
        
        super.init()
        
        tableView.clipsToBounds = true
        tableView.keyboardDismissMode = .onDrag
        
        registerContentOfffsetObserver()
        registerBoundsObserver()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        tableView.panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
    }
    
    func saveCurrentOffset() {
        guard let tableView = tableView,
              tableView.numberOfSections > 0 else {
            return
        }
    
        if computeIsBottomVisible() {
            offsetDetails = .bottomOffset
        } else if computeIsTopVisible() {
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
              tableView.numberOfSections > 0 else {
            return
        }
        
        let currentItemCount = tableView.numberOfRows(inSection: 0)
        
        switch offsetDetails {
        case .bottomOffset:
            tableView.scrollToRow(at: .init(row: max(0, currentItemCount - 1), section: 0), at: .bottom, animated: false)
        case .topOffset(let indexPath, let previousItemCount):
            let row = indexPath.row + max(0, currentItemCount - previousItemCount)
            if row < currentItemCount {
                tableView.scrollToRow(at: .init(row: row, section: 0), at: .top, animated: false)
            }
        case .none:
            break
        }
    }
    
    var isTracking: Bool {
        tableView?.isTracking == true
    }
    
    var isDecelerating: Bool {
        tableView?.isDecelerating == true
    }
    
    func scrollToBottom(animated: Bool = false) {
        guard let tableView = tableView,
              tableView.numberOfSections > 0 else {
            return
        }
        
        let currentItemCount = tableView.numberOfRows(inSection: 0)
        guard currentItemCount > 1 else {
            return
        }
        
        tableView.scrollToRow(at: .init(row: currentItemCount - 1, section: 0), at: .bottom, animated: animated)
    }
    
    // MARK: - Private
    
    private func registerContentOfffsetObserver() {
        // Don't attempt stealing the UITableView delegate away from the List.
        // Doing so results in undefined behavior e.g. context menus not working
        contentOffsetObserverToken = tableView?.observe(\.contentOffset, options: .new, changeHandler: { [weak self] _, _ in
            self?.handleScrollViewScroll()
        })
    }
    
    private func deregisterContentOffsetObserver() {
        contentOffsetObserverToken?.invalidate()
    }
    
    private func registerBoundsObserver() {
        boundsObserverToken = tableView?.observe(\.frame, options: .new, changeHandler: { [weak self] tableView, _ in
            self?.previousFrame = tableView.frame
            self?.handleScrollViewScroll()
        })
    }
    
    private func deregisterBoundsObserver() {
        boundsObserverToken?.invalidate()
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        isAnimatingKeyboardAppearance = true
    }
    
    @objc private func keyboardDidShow(notification: NSNotification) {
        isAnimatingKeyboardAppearance = false
    }
    
    private func handleScrollViewScroll() {
        guard let tableView = tableView else {
            return
        }
        
        let hasScrolledBecauseOfFrameChange = (previousFrame != tableView.frame)
        let shouldPinToBottom = scrollViewBottomVisiblePublisher.value && (isAnimatingKeyboardAppearance || hasScrolledBecauseOfFrameChange)
        
        if shouldPinToBottom {
            deregisterContentOffsetObserver()
            scrollToBottom()
            DispatchQueue.main.async {
                self.registerContentOfffsetObserver()
            }
            return
        }
        
        let isTopVisible = computeIsTopVisible()
        if isTopVisible != scrollViewTopVisiblePublisher.value {
            scrollViewTopVisiblePublisher.send(isTopVisible)
        }
        
        let isBottomVisible = computeIsBottomVisible()
        if isBottomVisible != scrollViewBottomVisiblePublisher.value {
            scrollViewBottomVisiblePublisher.send(isBottomVisible)
        }
        
        if !draggingInitiated, tableView.isDragging {
            draggingInitiated = true
        } else if draggingInitiated, !tableView.isDragging {
            draggingInitiated = false
            scrollViewDidRestPublisher.send(())
        }
    }
    
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let tableView = tableView,
              sender.state == .ended,
              draggingInitiated == true,
              !tableView.isDecelerating else {
            return
        }
        
        draggingInitiated = false
        scrollViewDidRestPublisher.send(())
    }
    
    private func computeIsTopVisible() -> Bool {
        guard let scrollView = tableView else {
            return false
        }

        return (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) <= topDetectionOffset
    }
    
    private func computeIsBottomVisible() -> Bool {
        guard let scrollView = tableView else {
            return false
        }

        return (scrollView.contentOffset.y + bottomDetectionOffset) >= (scrollView.contentSize.height - scrollView.frame.size.height)
    }
}
