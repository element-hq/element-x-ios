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
    
    func scrollToTop(needForceOffset: Bool = false) {
        guard let scrollView = scrollView else { return }
        let yOffset = needForceOffset ? -100 : 0
        let topOffset = CGPoint(x: 0, y: yOffset)
        scrollView.setContentOffset(topOffset, animated: true)
    }
    
    // MARK: - Private
    
    private func updateDidScroll(_ scrollView: UIScrollView) {
        isScrollingSubject.send(scrollView.isDragging || scrollView.isDecelerating)
    }
}

// Add this extension to your ScrollViewAdapter
extension ScrollViewAdapter {
    enum ScrollDirection {
        case up, down, none
    }
    
    private static var lastOffsetKey: UInt8 = 0
    private static var scrollDirectionSubjectKey: UInt8 = 1
    
    private var lastOffset: CGFloat {
        get {
            objc_getAssociatedObject(self, &Self.lastOffsetKey) as? CGFloat ?? 0
        }
        set {
            objc_setAssociatedObject(self, &Self.lastOffsetKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private var scrollDirectionSubject: PassthroughSubject<ScrollDirection, Never> {
        if let subject = objc_getAssociatedObject(self, &Self.scrollDirectionSubjectKey) as? PassthroughSubject<ScrollDirection, Never> {
            return subject
        }
        let subject = PassthroughSubject<ScrollDirection, Never>()
        objc_setAssociatedObject(self, &Self.scrollDirectionSubjectKey, subject, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return subject
    }
    
    var scrollDirection: AnyPublisher<ScrollDirection, Never> {
        scrollDirectionSubject.eraseToAnyPublisher()
    }
    
    func updateScrollDirection(with scrollView: UIScrollView) {
        let currentOffset = scrollView.contentOffset.y
        let threshold: CGFloat = 5 // Minimum scroll distance to trigger direction change
        
        if abs(currentOffset - lastOffset) > threshold {
            let direction: ScrollDirection = currentOffset > lastOffset ? .down : .up
            scrollDirectionSubject.send(direction)
            lastOffset = currentOffset
        }
    }
}
