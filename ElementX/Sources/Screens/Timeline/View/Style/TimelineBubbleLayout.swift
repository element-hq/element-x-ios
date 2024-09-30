//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// A custom layout used for quotes and content when using the bubbles timeline style.
///
/// A custom layout is required as the embedded quote bubbles should fill the entire width of
/// the message bubble, without causing the width of the bubble to fill all of the available space.
struct TimelineBubbleLayout: Layout {
    struct Cache {
        var sizes = [Int: [ProposedViewSize: CGSize]]()
    }
    
    /// The spacing between the components in the bubble.
    let spacing: CGFloat
    
    /// Layout priority constants for the bubble content. These priorities are abused within
    /// `TimelineBubbleLayout` to create the layout we would like. They aren't
    /// used in the expected way that SwiftUI would normally use layout priorities.
    enum Priority {
        /// The priority of hidden quote bubbles that are only used for layout calculations.
        static let hiddenQuote: Double = -1
        /// The priority of visible quote bubbles that are placed in the view with a full width.
        static let visibleQuote: Double = 0
        /// The priority of regular text that is used for layout calculations and placed in the view.
        static let regularText: Double = 1
    }
    
    func makeCache(subviews: Subviews) -> Cache {
        Cache()
    }
    
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        // A subview changed, reset everything
        cache = Cache()
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        // Calculate the natural size using the regular text and non-greedy quote bubbles.
        let layoutSubviews = subviews.filter { $0.priority != Priority.visibleQuote }

        let subviewSizes = layoutSubviews.map { size(for: $0, subviews: subviews, proposedSize: proposal, cache: &cache) }
        
        let maxWidth = subviewSizes.map(\.width).reduce(0, max)
        let totalHeight = subviewSizes.map(\.height).reduce(0, +)
        let totalSpacing = CGFloat(layoutSubviews.count - 1) * spacing
        
        return CGSize(width: maxWidth, height: totalHeight + totalSpacing)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        guard !subviews.isEmpty else { return }
        
        // Calculate the width using the regular text and the non-greedy quote bubbles.
        let layoutSubviews = subviews.filter { $0.priority != Priority.visibleQuote }
        let maxWidth = layoutSubviews.map { size(for: $0, subviews: subviews, proposedSize: proposal, cache: &cache).width }.reduce(0, max)
        
        // Place the regular text and greedy quote bubbles using the calculated width.
        let visibleSubviews = subviews.filter { $0.priority != Priority.hiddenQuote }

        let subviewSizes = visibleSubviews.map { size(for: $0, subviews: subviews, proposedSize: ProposedViewSize(width: maxWidth, height: proposal.height), cache: &cache) }
        
        var y = bounds.minY
        for index in visibleSubviews.indices {
            let height = subviewSizes[index].height
            visibleSubviews[index].place(at: CGPoint(x: bounds.minX, y: y),
                                         anchor: .topLeading,
                                         proposal: ProposedViewSize(width: maxWidth, height: height))
            y += height + spacing
        }
    }
    
    // MARK: - Private
    
    private func size(for subview: LayoutSubview, subviews: LayoutSubviews, proposedSize: ProposedViewSize, cache: inout Cache) -> CGSize {
        guard let index = subviews.firstIndex(of: subview) else {
            fatalError()
        }
        
        if cache.sizes[index] == nil {
            cache.sizes[index] = [:]
        }
        
        if let cachedSize = cache.sizes[index]?[proposedSize] {
            return cachedSize
        }
        
        let size = subview.sizeThatFits(proposedSize)
        
        cache.sizes[index]?[proposedSize] = size
        return size
    }
}
