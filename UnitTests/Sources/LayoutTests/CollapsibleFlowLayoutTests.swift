//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import ElementX
import SwiftUI
import XCTest

final class CollapsibleFlowLayoutTests: XCTestCase {
    func testFlowLayoutWithExpandAndCollapse() {
        let containerSize = CGSize(width: 250, height: 400)
        var flowLayout = CollapsibleFlowLayout(itemSpacing: 5, lineSpacing: 5, linesBeforeCollapsible: 2)
        
        var placedViews: [CGRect] = []
        let placedViewsCallback = { rect in
            placedViews.append(rect)
        }
        let subViews: [LayoutSubviewMock] = [
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            // The expand/collapse button
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback)
        ]
        let subviewsMock = LayoutSubviewsMock(subviews: subViews)
        var a: () = ()
        var size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        // Collapsed target layout has 2 rows of 2 items, so just 1 spacing between items hence 205, 105
        XCTAssertEqual(size, CGSize(width: 205, height: 105))
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        // 3 items are hidden in the collapsed state (put in the centre with zero size)
        var targetPlacements: [CGRect] = [
            CGRect(x: 0, y: 25, width: 100, height: 50),
            CGRect(x: 105, y: 25, width: 100, height: 50),
            CGRect(x: 0, y: 80, width: 100, height: 50),
            CGRect(x: 105, y: 80, width: 100, height: 50),
            CGRect(x: -10000, y: -10000, width: 0, height: 0),
            CGRect(x: -10000, y: -10000, width: 0, height: 0),
            CGRect(x: -10000, y: -10000, width: 0, height: 0)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
        
        flowLayout.collapsed = false
        placedViews = []
        
        size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        // Expanded target layout has 4 rows and no more than 2 items per row
        XCTAssertEqual(size, CGSize(width: 205, height: 215))
        
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        targetPlacements = [
            CGRect(x: 0, y: 25, width: 100, height: 50),
            CGRect(x: 105, y: 25, width: 100, height: 50),
            CGRect(x: 0, y: 80, width: 100, height: 50),
            CGRect(x: 105, y: 80, width: 100, height: 50),
            CGRect(x: 0, y: 135, width: 100, height: 50),
            CGRect(x: 105, y: 135, width: 100, height: 50),
            CGRect(x: 0, y: 190, width: 100, height: 50)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
    }
    
    func testFlowLayoutWithExpandButtonIsHidden() {
        let containerSize = CGSize(width: 250, height: 400)
        let flowLayout = CollapsibleFlowLayout(itemSpacing: 5, lineSpacing: 5, linesBeforeCollapsible: 2)
        
        var placedViews: [CGRect] = []
        let placedViewsCallback = { rect in
            placedViews.append(rect)
        }
        let subViews: [LayoutSubviewMock] = [
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback),
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback)
        ]
        let subviewsMock = LayoutSubviewsMock(subviews: subViews)
        var a: () = ()
        let size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        XCTAssertEqual(size, CGSize(width: 205, height: 105))
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        let targetPlacements: [CGRect] = [
            CGRect(x: 0, y: 25, width: 100, height: 50),
            CGRect(x: 105, y: 25, width: 100, height: 50),
            CGRect(x: 0, y: 80, width: 100, height: 50),
            // Button is hidden
            CGRect(x: -10000, y: -10000, width: 0, height: 0)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
    }
    
    func testFlowLayoutEmptyState() {
        let containerSize = CGSize(width: 250, height: 400)
        let flowLayout = CollapsibleFlowLayout(itemSpacing: 5, lineSpacing: 5, linesBeforeCollapsible: 2)
        
        var placedViews: [CGRect] = []
        let placedViewsCallback = { rect in
            placedViews.append(rect)
        }
        let subViews: [LayoutSubviewMock] = [
            // No subviews to layout just the expand/collapse button
            LayoutSubviewMock(size: CGSize(width: 100, height: 50), placedPositionCallback: placedViewsCallback)
        ]
        let subviewsMock = LayoutSubviewsMock(subviews: subViews)
        var a: () = ()
        let size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        XCTAssertEqual(size, CGSize(width: 0, height: 0))
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        let targetPlacements: [CGRect] = [
            CGRect(x: -10000, y: -10000, width: 0, height: 0)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
    }
}
