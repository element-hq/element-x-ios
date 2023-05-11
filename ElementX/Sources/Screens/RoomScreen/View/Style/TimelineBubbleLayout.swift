//
// Copyright 2023 New Vector Ltd
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

import SwiftUI

/// A custom layout used for quotes and content when using the bubbles timeline style.
///
/// A custom layout is required as the embedded quote bubbles should fill the entire width of
/// the message bubble, without causing the width of the bubble to fill all of the available space.
struct TimelineBubbleLayout: Layout {
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
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        // Calculate the natural size using the regular text and non-greedy quote bubbles.
        let layoutSubviews = subviews.filter { $0.priority != Priority.visibleQuote }
        
        let subviewSizes = layoutSubviews.map { $0.sizeThatFits(proposal) }
        let maxWidth = subviewSizes.map(\.width).reduce(0, max)
        let totalHeight = subviewSizes.map(\.height).reduce(0, +)
        let totalSpacing = CGFloat(layoutSubviews.count - 1) * spacing
        
        return CGSize(width: maxWidth, height: totalHeight + totalSpacing)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        // Calculate the width using the regular text and the non-greedy quote bubbles.
        let layoutSubviews = subviews.filter { $0.priority != Priority.visibleQuote }
        let maxWidth = layoutSubviews.map { $0.sizeThatFits(proposal).width }.reduce(0, max)
        
        // Place the regular text and greedy quote bubbles using the calculated width.
        let visibleSubviews = subviews.filter { $0.priority != Priority.hiddenQuote }
        let subviewSizes = visibleSubviews.map { $0.sizeThatFits(ProposedViewSize(width: maxWidth, height: proposal.height)) }
        
        var y = bounds.minY
        for index in visibleSubviews.indices {
            let height = subviewSizes[index].height
            visibleSubviews[index].place(at: CGPoint(x: bounds.minX, y: y),
                                         anchor: .topLeading,
                                         proposal: ProposedViewSize(width: maxWidth, height: height))
            y += height + spacing
        }
    }
}

extension View {
    func timelineQuoteBubbleFormatting() -> some View {
        foregroundColor(.compound.textPlaceholder)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }
}
