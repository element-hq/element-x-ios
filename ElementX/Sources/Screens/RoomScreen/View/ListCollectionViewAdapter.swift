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
import UIKit

class ListCollectionViewAdapter: NSObject, UICollectionViewDelegate {
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
    
    private(set) var collectionView: UICollectionView?
        
    let scrollViewDidRestPublisher = PassthroughSubject<Void, Never>()
    let scrollViewTopVisiblePublisher = CurrentValueSubject<Bool, Never>(false)
    let scrollViewBottomVisiblePublisher = CurrentValueSubject<Bool, Never>(false)
    
    override init() {
        topDetectionOffset = 0.0
        bottomDetectionOffset = 0.0
    }
    
    init(collectionView: UICollectionView, topDetectionOffset: CGFloat, bottomDetectionOffset: CGFloat) {
        self.collectionView = collectionView
        self.topDetectionOffset = topDetectionOffset
        self.bottomDetectionOffset = bottomDetectionOffset
        
        super.init()
        
        collectionView.clipsToBounds = true
        collectionView.keyboardDismissMode = .onDrag
        
        registerContentOffsetObserver()
        registerBoundsObserver()
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(notification:)), name: UIResponder.keyboardDidShowNotification, object: nil)

        collectionView.panGestureRecognizer.addTarget(self, action: #selector(handlePanGesture(_:)))
    }
    
    func saveCurrentOffset() {
        guard let collectionView,
              collectionView.numberOfSections > 0 else {
            return
        }
    
        if computeIsBottomVisible() {
            offsetDetails = .bottomOffset
        } else if computeIsTopVisible(), let topIndexPath = collectionView.indexPathsForVisibleItems.first {
            offsetDetails = .topOffset(previousVisibleIndexPath: topIndexPath,
                                       previousItemCount: collectionView.numberOfItems(inSection: 0))
        }
    }
    
    func restoreSavedOffset() {
        defer {
            offsetDetails = nil
        }
        
        guard let collectionView,
              collectionView.numberOfSections > 0 else {
            return
        }
        
        let currentItemCount = collectionView.numberOfItems(inSection: 0)
        
        switch offsetDetails {
        case .bottomOffset:
            collectionView.scrollToItem(at: .init(item: max(0, currentItemCount - 1), section: 0), at: .bottom, animated: false)
        case .topOffset(let indexPath, let previousItemCount):
            let item = indexPath.item + max(0, currentItemCount - previousItemCount)
            if item < currentItemCount {
                collectionView.scrollToItem(at: .init(item: item, section: 0), at: .top, animated: false)
            }
        case .none:
            break
        }
    }
    
    var isTracking: Bool {
        collectionView?.isTracking == true
    }
    
    var isDecelerating: Bool {
        collectionView?.isDecelerating == true
    }
    
    func scrollToBottom(animated: Bool = false) {
        guard let collectionView,
              collectionView.numberOfSections > 0 else {
            return
        }
        
        let currentItemCount = collectionView.numberOfItems(inSection: 0)
        guard currentItemCount > 1 else {
            return
        }
        
        collectionView.scrollToItem(at: .init(item: currentItemCount - 1, section: 0), at: .bottom, animated: animated)
    }
    
    // MARK: - Private
    
    private func registerContentOffsetObserver() {
        // Don't attempt stealing the UICollectionView delegate away from the List.
        // Doing so results in undefined behavior e.g. context menus not working
        contentOffsetObserverToken = collectionView?.observe(\.contentOffset, options: .new) { [weak self] _, _ in
            self?.handleScrollViewScroll()
        }
    }
    
    private func deregisterContentOffsetObserver() {
        contentOffsetObserverToken?.invalidate()
    }
    
    private func registerBoundsObserver() {
        boundsObserverToken = collectionView?.observe(\.frame, options: .new) { [weak self] collectionView, _ in
            self?.previousFrame = collectionView.frame
            self?.handleScrollViewScroll()
        }
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
        guard let collectionView else {
            return
        }
        
        let hasScrolledBecauseOfFrameChange = (previousFrame != collectionView.frame)
        let shouldPinToBottom = scrollViewBottomVisiblePublisher.value && (isAnimatingKeyboardAppearance || hasScrolledBecauseOfFrameChange)
        
        if shouldPinToBottom {
            deregisterContentOffsetObserver()
            scrollToBottom()
            DispatchQueue.main.async {
                self.registerContentOffsetObserver()
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
        
        if !draggingInitiated, collectionView.isDragging {
            draggingInitiated = true
        } else if draggingInitiated, !collectionView.isDragging {
            draggingInitiated = false
            scrollViewDidRestPublisher.send(())
        }
    }
    
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let collectionView,
              sender.state == .ended,
              draggingInitiated,
              !collectionView.isDecelerating else {
            return
        }
        
        draggingInitiated = false
        scrollViewDidRestPublisher.send(())
    }
    
    private func computeIsTopVisible() -> Bool {
        guard let scrollView = collectionView else {
            return false
        }

        return (scrollView.contentOffset.y + scrollView.adjustedContentInset.top) <= topDetectionOffset
    }
    
    private func computeIsBottomVisible() -> Bool {
        guard let scrollView = collectionView else {
            return false
        }

        return (scrollView.contentOffset.y + bottomDetectionOffset) >= (scrollView.contentSize.height - scrollView.frame.size.height)
    }
}
