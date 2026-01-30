//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A custom layout used for quotes and content when using the bubbles timeline style.
///
/// A custom layout is required as the embedded quote bubbles and code blocks should fill the entire
/// width of the message bubble, without causing the width of the bubble to fill all of the available space.
struct TimelineBubbleLayout: Layout {
    struct Cache {
        var sizes = [Int: [ProposedViewSize: CGSize]]()
    }
    
    /// The spacing between the components in the bubble.
    let spacing: CGFloat
    
    /// Layout size for the bubble content. These sizing types are used within
    /// `TimelineBubbleLayout` to create the layout we would like.
    enum Size: LayoutValueKey, Equatable {
        static let defaultValue: Size = .natural
        
        /// Full width mode used for greedy components like blockquotes and code blocks.
        enum BubbleWidthMode {
            /// The view has its natural size and will be used for layout calculations only.
            case layout
            /// The view has a greedy width and will fill the available space within the bubble.
            case rendering
        }
        
        /// The view will fill the available width, with different behaviour depending on the mode.
        /// Views using the `.layout` mode should be hidden and are used only for width calculations.
        /// Views using the `.rendering` mode should be visible and are placed to fill the bubble's calculated width.
        case bubbleWidth(mode: BubbleWidthMode)
        /// The view uses its natural size for both layout calculations and rendering.
        case natural
        
        var shouldLayout: Bool {
            switch self {
            case .natural, .bubbleWidth(mode: .layout): true
            default: false
            }
        }
        
        var shouldRender: Bool {
            switch self {
            case .natural, .bubbleWidth(mode: .rendering): true
            default: false
            }
        }
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
        let layoutSubviews = subviews.filter { $0[Size.self].shouldLayout }

        let subviewSizes = layoutSubviews.map { size(for: $0, subviews: subviews, proposedSize: proposal, cache: &cache) }
        
        let maxWidth = subviewSizes.map(\.width).reduce(0, max)
        let totalHeight = subviewSizes.map(\.height).reduce(0, +)
        let totalSpacing = CGFloat(layoutSubviews.count - 1) * spacing
        
        return CGSize(width: maxWidth, height: totalHeight + totalSpacing)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
        guard !subviews.isEmpty else { return }
        
        // Calculate the width using the regular text along with non-greedy versions of any greedy components.
        let layoutSubviews = subviews.filter { $0[Size.self].shouldLayout }
        let maxWidth = layoutSubviews.map { size(for: $0, subviews: subviews, proposedSize: proposal, cache: &cache).width }.reduce(0, max)
        
        // Place the regular text and greedy components using the calculated width.
        let visibleSubviews = subviews.filter { $0[Size.self].shouldRender }

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

extension View {
    /// Sets the layout size for this view when placed within a `TimelineBubbleLayout`.
    func timelineBubbleLayoutSize(_ size: TimelineBubbleLayout.Size) -> some View {
        layoutValue(key: TimelineBubbleLayout.Size.self, value: size)
    }
}
