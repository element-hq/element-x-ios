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
    
    // MARK: - Private
    
    private func updateDidScroll(_ scrollView: UIScrollView) {
        isScrollingSubject.send(scrollView.isDragging || scrollView.isDecelerating)
    }
}
