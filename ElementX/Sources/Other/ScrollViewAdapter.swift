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
    enum ScrollDirection {
        case up
        case down
    }
    
    var scrollView: UIScrollView? {
        didSet {
            oldValue?.delegate = nil
            scrollView?.delegate = self
        }
    }
    
    private let didScrollSubject = PassthroughSubject<Void, Never>()
    var didScroll: AnyPublisher<Void, Never> {
        didScrollSubject.eraseToAnyPublisher()
    }
    
    private let isScrollingSubject = CurrentValueSubject<Bool, Never>(false)
    var isScrolling: CurrentValuePublisher<Bool, Never> {
        .init(isScrollingSubject)
    }
    
    private let scrollDirectionSubject: PassthroughSubject<ScrollDirection, Never> = .init()
    var scrollDirection: AnyPublisher<ScrollDirection, Never> {
        scrollDirectionSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScrollSubject.send(())
        updateScrollDirection(scrollView)
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
    
    // MARK: - Private
    
    private func updateDidScroll(_ scrollView: UIScrollView) {
        isScrollingSubject.send(scrollView.isDragging || scrollView.isDecelerating)
    }
    
    private func updateScrollDirection(_ scrollView: UIScrollView) {
        let velocity = scrollView.panGestureRecognizer.velocity(in: nil)

        if velocity.y > Constant.scrollDirectionThreshold {
            scrollDirectionSubject.send(.down)
        } else if velocity.y < -Constant.scrollDirectionThreshold {
            scrollDirectionSubject.send(.up)
        }
    }
    
    private enum Constant {
        static let scrollDirectionThreshold: CGFloat = 200
    }
}
