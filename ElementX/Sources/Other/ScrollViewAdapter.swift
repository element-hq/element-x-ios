//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import UIKit

class ScrollViewAdapter: NSObject, UIScrollViewDelegate {
    var scrollView: UIScrollView? {
        didSet {
            oldValue?.delegate = nil
            scrollView?.delegate = self
        }
    }

    var shouldScrollToTopClosure: ((UIScrollView) -> Bool)?

    private let didScrollSubject = PassthroughSubject<Void, Never>()
    var didScroll: AnyPublisher<Void, Never> {
        didScrollSubject.eraseToAnyPublisher()
    }
    
    private let isScrollingSubject = CurrentValueSubject<Bool, Never>(false)
    var isScrolling: CurrentValuePublisher<Bool, Never> {
        .init(isScrollingSubject)
    }
    
    private let isAtTopEdgeSubject: CurrentValueSubject<Bool, Never> = .init(false)
    var isAtTopEdge: CurrentValuePublisher<Bool, Never> {
        isAtTopEdgeSubject
            .asCurrentValuePublisher()
    }
    
    // MARK: - Scroll direction
    enum ScrollDirection {
        case up, down, none
    }
    
    private var lastContentOffset: CGFloat = 0
    private let scrollDirectionSubject = PassthroughSubject<ScrollDirection, Never>()
    
    var scrollDirection: AnyPublisher<ScrollDirection, Never> {
        scrollDirectionSubject.eraseToAnyPublisher()
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollSubject.send(())
        let insetContentOffset = scrollView.contentOffset.y + scrollView.contentInset.top
        isAtTopEdgeSubject.send(insetContentOffset >= 3)
        
        // Track scroll direction
        updateScrollDirection(with: scrollView)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        updateDidScroll(scrollView)
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        updateDidScroll(scrollView)
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateDidScroll(scrollView)
    }
        
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateDidScroll(scrollView)
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        updateDidScroll(scrollView)
    }

    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        guard let shouldScrollToTopClosure else {
            // Default behaviour
            return true
        }
        return shouldScrollToTopClosure(scrollView)
    }
    
    func scrollToTop() {
        guard let scrollView = scrollView else { return }
        let topOffset = CGPoint(x: 0, y: -100)
        scrollView.setContentOffset(topOffset, animated: true)
    }
    
    // MARK: - Private
    
    private func updateDidScroll(_ scrollView: UIScrollView) {
        isScrollingSubject.send(scrollView.isDragging || scrollView.isDecelerating)
    }
    
    private func updateScrollDirection(with scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let threshold: CGFloat = 10.0

        // Only consider a direction change if we've scrolled more than the threshold
        // since the last time we updated the direction.
        if abs(currentOffset - lastContentOffset) > threshold {
            let contentHeight = scrollView.contentSize.height
            let frameHeight = scrollView.frame.height
            
            // The scrollable area, excluding bounce areas.
            let topBoundary = -scrollView.contentInset.top
            let bottomBoundary = contentHeight - frameHeight + scrollView.contentInset.bottom

            // Don't send direction changes if the content is not scrollable
            // or if we are "bouncing" at the top or bottom.
            if contentHeight > frameHeight, currentOffset > topBoundary, currentOffset < bottomBoundary {
                let direction: ScrollDirection = currentOffset > lastContentOffset ? .down : .up
                scrollDirectionSubject.send(direction)
            }
            
            // Update the offset to measure the next scroll from here.
            lastContentOffset = currentOffset
        }
    }
}
