//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import XCTest

final class CollapsibleFlowLayoutTests: XCTestCase {
    func testFlowLayoutWithExpandAndCollapse() {
        let containerSize = CGSize(width: 250, height: 400)
        var flowLayout = CollapsibleReactionLayout(itemSpacing: 5, rowSpacing: 5, rowsBeforeCollapsible: 2)
        
        var placedViews: [CGRect] = []
        let placedViewsCallback = { rect in
            placedViews.append(rect)
        }
        let subviews = createReactionLayoutSubviews(with: Array(repeating: CGSize(width: 100, height: 50), count: 6), placedPositionCallback: placedViewsCallback)
        let subviewsMock = LayoutSubviewsMock(subviews: subviews)
        var a: () = ()
        var size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        // Collapsed target layout has 2 rows of 2 items, so just 1 spacing between items hence 205, 105
        XCTAssertEqual(size, CGSize(width: 205, height: 105))
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        // 4 items are hidden in the collapsed state (put in the centre with zero size)
        var targetPlacements: [CGRect] = [
            CGRect(x: 0, y: 25, width: 100, height: 50),
            CGRect(x: 105, y: 25, width: 100, height: 50),
            CGRect(x: 0, y: 80, width: 100, height: 50),
            CGRect(x: 105, y: 80, width: 100, height: 50),
            CGRect(x: -10000, y: -10000, width: 0, height: 0),
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
            CGRect(x: 0, y: 190, width: 100, height: 50),
            CGRect(x: 105.0, y: 190, width: 100, height: 50)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
    }
    
    func testFlowLayoutWithExpandButtonAndAddMoreIsHidden() {
        let containerSize = CGSize(width: 250, height: 400)
        let flowLayout = CollapsibleReactionLayout(itemSpacing: 5, rowSpacing: 5, rowsBeforeCollapsible: 2)
        
        var placedViews: [CGRect] = []
        let placedViewsCallback = { rect in
            placedViews.append(rect)
        }
        
        let subviews = createReactionLayoutSubviews(with: Array(repeating: CGSize(width: 100, height: 50), count: 3), placedPositionCallback: placedViewsCallback)
        let subviewsMock = LayoutSubviewsMock(subviews: subviews)
        var a: () = ()
        let size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        XCTAssertEqual(size, CGSize(width: 205, height: 105))
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        let targetPlacements: [CGRect] = [
            CGRect(x: 0, y: 25, width: 100, height: 50),
            CGRect(x: 105, y: 25, width: 100, height: 50),
            CGRect(x: 0, y: 80, width: 100, height: 50),
            // Add more button
            CGRect(x: 105.0, y: 80, width: 100, height: 50),
            // Expand/Collapse button is hidden
            CGRect(x: -10000, y: -10000, width: 0, height: 0)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
    }
    
    func testHeightIsCorrectGivenASmallerAddButton() {
        let containerSize = CGSize(width: 250, height: 400)
        let flowLayout = CollapsibleReactionLayout(itemSpacing: 5, rowSpacing: 5, rowsBeforeCollapsible: 2)
        
        var placedViews: [CGRect] = []
        let placedViewsCallback = { rect in
            placedViews.append(rect)
        }
        
        // Add more button with smaller initial height
        let subviews = createReactionLayoutSubviews(with: Array(repeating: CGSize(width: 100, height: 50), count: 2),
                                                    addMoreSize: CGSize(width: 100, height: 20),
                                                    placedPositionCallback: placedViewsCallback)
        let subviewsMock = LayoutSubviewsMock(subviews: subviews)
        var a: () = ()
        let size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        XCTAssertEqual(size, CGSize(width: 205, height: 105))
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        let targetPlacements: [CGRect] = [
            CGRect(x: 0, y: 25, width: 100, height: 50),
            CGRect(x: 105, y: 25, width: 100, height: 50),
            // Add more button with matching height
            CGRect(x: 0, y: 80, width: 100, height: 50),
            // Expand/Collapse button is hidden
            CGRect(x: -10000, y: -10000, width: 0, height: 0)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
    }
    
    func testFlowLayoutEmptyState() {
        let containerSize = CGSize(width: 250, height: 400)
        let flowLayout = CollapsibleReactionLayout(itemSpacing: 5, rowSpacing: 5, rowsBeforeCollapsible: 2)
        
        var placedViews: [CGRect] = []
        let placedViewsCallback = { rect in
            placedViews.append(rect)
        }
        let subviews = createReactionLayoutSubviews(with: [], placedPositionCallback: placedViewsCallback)
        let subviewsMock = LayoutSubviewsMock(subviews: subviews)
        var a: () = ()
        let size = flowLayout.sizeThatFits(proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        XCTAssertEqual(size, CGSize(width: 0, height: 0))
        flowLayout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: ProposedViewSize(containerSize), subviews: subviewsMock, cache: &a)
        
        let targetPlacements: [CGRect] = [
            // both buttons are not displayed
            CGRect(x: -10000, y: -10000, width: 0, height: 0),
            CGRect(x: -10000, y: -10000, width: 0, height: 0)
        ]
        XCTAssertEqual(placedViews, targetPlacements)
    }
    
    func createReactionLayoutSubviews(with sizes: [CGSize],
                                      expandCollapseSize: CGSize = CGSize(width: 100, height: 50),
                                      addMoreSize: CGSize = CGSize(width: 100, height: 50),
                                      placedPositionCallback: @escaping (CGRect) -> Void) -> [LayoutSubviewMock] {
        sizes.map { size in
            LayoutSubviewMock(size: size,
                              layoutValues: [String(describing: ReactionLayoutItemType.self): ReactionLayoutItem.reaction],
                              placedPositionCallback: placedPositionCallback)
        } + [
            LayoutSubviewMock(size: expandCollapseSize,
                              layoutValues: [String(describing: ReactionLayoutItemType.self): ReactionLayoutItem.expandCollapse],
                              placedPositionCallback: placedPositionCallback),
            LayoutSubviewMock(size: addMoreSize,
                              layoutValues: [String(describing: ReactionLayoutItemType.self): ReactionLayoutItem.addMore],
                              placedPositionCallback: placedPositionCallback)
        ]
    }
}
