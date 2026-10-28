//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import Testing

struct A2UIFlowLayoutTests {
    @Test
    func childrenWrapWhenTheyDontFit() {
        var placements = [CGRect]()
        let subviews = makeSubviews(sizes: Array(repeating: CGSize(width: 100, height: 40), count: 3)) { placements.append($0) }
        let layout = A2UIFlowLayout(justify: .start, align: .start)
        var cache: () = ()
        
        let proposal = ProposedViewSize(width: 250, height: nil)
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        
        // Two children and a gap fit on the first line, the third wraps. The row hugs its content.
        #expect(size == CGSize(width: 208, height: 88))
        
        layout.placeSubviews(in: CGRect(origin: .zero, size: CGSize(width: 250, height: size.height)), proposal: proposal, subviews: subviews, cache: &cache)
        #expect(placements == [CGRect(x: 0, y: 0, width: 100, height: 40),
                               CGRect(x: 108, y: 0, width: 100, height: 40),
                               CGRect(x: 0, y: 48, width: 100, height: 40)])
    }
    
    @Test
    func justifyCenterSharesSpareWidthPerLine() {
        var placements = [CGRect]()
        let subviews = makeSubviews(sizes: Array(repeating: CGSize(width: 100, height: 40), count: 3)) { placements.append($0) }
        let layout = A2UIFlowLayout(justify: .center, align: .start)
        var cache: () = ()
        
        let proposal = ProposedViewSize(width: 250, height: nil)
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        
        // Centred content needs the whole width to be centred within.
        #expect(size == CGSize(width: 250, height: 88))
        
        layout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: proposal, subviews: subviews, cache: &cache)
        #expect(placements == [CGRect(x: 21, y: 0, width: 100, height: 40),
                               CGRect(x: 129, y: 0, width: 100, height: 40),
                               CGRect(x: 75, y: 48, width: 100, height: 40)])
    }
    
    @Test
    func weightedChildTakesTheSpareWidth() {
        var placements = [CGRect]()
        let subviews = makeSubviews(sizes: [CGSize(width: 24, height: 24), CGSize(width: 50, height: 20), CGSize(width: 80, height: 36)],
                                    weights: [0, 1, 0]) { placements.append($0) }
        let layout = A2UIFlowLayout(justify: .start, align: .center)
        var cache: () = ()
        
        let proposal = ProposedViewSize(width: 300, height: nil)
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        #expect(size == CGSize(width: 300, height: 36))
        
        layout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: proposal, subviews: subviews, cache: &cache)
        
        // The text grows by the 130 points left over on the line and everything is centred vertically.
        #expect(placements == [CGRect(x: 0, y: 6, width: 24, height: 24),
                               CGRect(x: 32, y: 8, width: 180, height: 20),
                               CGRect(x: 220, y: 0, width: 80, height: 36)])
    }
    
    @Test
    func alignStretchProposesTheLineHeight() {
        var placements = [CGRect]()
        let subviews = makeSubviews(sizes: [CGSize(width: 100, height: 40), CGSize(width: 100, height: 20)]) { placements.append($0) }
        let layout = A2UIFlowLayout(justify: .start, align: .stretch)
        var cache: () = ()
        
        let proposal = ProposedViewSize(width: 300, height: nil)
        let size = layout.sizeThatFits(proposal: proposal, subviews: subviews, cache: &cache)
        
        // Align only affects the cross axis: widths stay natural, but the shorter child is proposed the line's height.
        #expect(size == CGSize(width: 208, height: 40))
        
        layout.placeSubviews(in: CGRect(origin: .zero, size: size), proposal: proposal, subviews: subviews, cache: &cache)
        #expect(placements == [CGRect(x: 0, y: 0, width: 100, height: 40),
                               CGRect(x: 108, y: 0, width: 100, height: 40)])
    }
    
    @Test
    func unboundedWidthKeepsEverythingOnOneLine() {
        let subviews = makeSubviews(sizes: Array(repeating: CGSize(width: 100, height: 40), count: 3)) { _ in }
        let layout = A2UIFlowLayout(justify: .center, align: .start)
        var cache: () = ()
        
        let size = layout.sizeThatFits(proposal: .unspecified, subviews: subviews, cache: &cache)
        #expect(size == CGSize(width: 316, height: 40))
    }
    
    // MARK: - Helpers
    
    private func makeSubviews(sizes: [CGSize], weights: [Double]? = nil, placedPositionCallback: @escaping (CGRect) -> Void) -> LayoutSubviewsMock {
        let subviews = sizes.enumerated().map { index, size in
            // Typed up front, otherwise the literal becomes an Int inside the `Any` dictionary and the key lookup fails.
            let weight: Double = weights?[index] ?? 0
            return LayoutSubviewMock(size: size,
                                     layoutValues: [String(describing: A2UIWeightLayoutKey.self): weight],
                                     placedPositionCallback: placedPositionCallback)
        }
        return LayoutSubviewsMock(subviews: subviews)
    }
}
