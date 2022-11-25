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
        
    var isScrolling = PassthroughSubject<Bool, Never>()
        
    private func update() {
        guard let scrollView else { return }
        isScrolling.send(scrollView.isDragging || scrollView.isDecelerating)
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        update()
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        update()
    }
    
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        update()
    }
        
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        update()
    }
    
    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        update()
    }
}
