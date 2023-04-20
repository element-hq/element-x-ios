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
    
    let didScroll = PassthroughSubject<Void, Never>()
    let isScrolling = CurrentValueSubject<Bool, Never>(false)
    
    // MARK: - UIScrollViewDelegate
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll.send(())
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
        isScrolling.send(scrollView.isDragging || scrollView.isDecelerating)
    }
}
