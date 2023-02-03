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

import Foundation
import SwiftUI

/// Layout priority constants for `FormattedBodyText`. These priorities are abused within
/// `FormattedBodyTextBubbleLayout` to create the layout we would like. They aren't
/// used in the expected way that SwiftUI would normally use layout priorities.
private enum LayoutPriority {
    /// The priority of hidden blockquotes that are only used for layout calculations.
    static let hiddenBlockquote: Double = -1
    /// The priority of visible blockquotes that are placed in the view with a full width.
    static let visibleBlockquote: Double = 0
    /// The priority of regular text that is used for layout calculations and placed in the view.
    static let regularText: Double = 1
}

/// A custom layout used for formatted text components when in the bubbles timeline style.
///
/// A custom layout is required as the embedded blockquotes should fill the entire width of the message
/// bubble, without causing the width of the bubble to fill all of the available space.
struct FormattedBodyTextBubbleLayout: Layout {
    /// The spacing between the components in the bubble.
    let spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard !subviews.isEmpty else { return .zero }
        
        // Calculate the natural size using the regular text and non-greedy blockquote bubbles.
        let layoutSubviews = subviews.filter { $0.priority != LayoutPriority.visibleBlockquote }
        
        let subviewSizes = layoutSubviews.map { $0.sizeThatFits(proposal) }
        let maxWidth = subviewSizes.map(\.width).reduce(0, max)
        let totalHeight = subviewSizes.map(\.height).reduce(0, +)
        let totalSpacing = CGFloat(layoutSubviews.count - 1) * spacing
        
        return CGSize(width: maxWidth, height: totalHeight + totalSpacing)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard !subviews.isEmpty else { return }
        
        // Calculate the width using the regular text and the non-greedy blockquote bubbles.
        let layoutSubviews = subviews.filter { $0.priority != LayoutPriority.visibleBlockquote }
        let maxWidth = layoutSubviews.map { $0.sizeThatFits(proposal).width }.reduce(0, max)
        
        // Place the regular text and greedy blockquote bubbles using the calculated width.
        let visibleSubviews = subviews.filter { $0.priority != LayoutPriority.hiddenBlockquote }
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

struct FormattedBodyText: View {
    @Environment(\.timelineStyle) private var timelineStyle
    
    private let attributedComponents: [AttributedStringBuilderComponent]
    
    init(attributedString: AttributedString) {
        attributedComponents = attributedString.blockquoteCoalescedComponents
    }
    
    var body: some View {
        if timelineStyle == .bubbles {
            bubbleLayout
                .tint(.element.links)
        } else {
            plainLayout
                .tint(.element.links)
        }
    }
    
    /// The attributed components laid out for the bubbles timeline style.
    var bubbleLayout: some View {
        FormattedBodyTextBubbleLayout(spacing: 8) {
            ForEach(attributedComponents, id: \.self) { component in
                if component.isBlockquote {
                    // The rendered blockquote with a greedy width. The custom layout prevents the
                    // infinite width from increasing the overall width of the view.
                    Text(component.attributedString.mergingAttributes(blockquoteAttributes))
                        .blockquoteFormatting(isReply: component.isReply)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.element.background)
                        .cornerRadius(8)
                        .layoutPriority(LayoutPriority.visibleBlockquote)
                } else {
                    Text(component.attributedString)
                        .padding(.horizontal, timelineStyle == .bubbles ? 4 : 0)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.element.primaryContent)
                        .layoutPriority(LayoutPriority.regularText)
                }
            }
            
            // Make a second iteration through the components adding fixed width blockquotes
            // which are used for layout calculations but won't be rendered.
            ForEach(attributedComponents, id: \.self) { component in
                if component.isBlockquote {
                    Text(component.attributedString.mergingAttributes(blockquoteAttributes))
                        .blockquoteFormatting(isReply: component.isReply)
                        .layoutPriority(LayoutPriority.hiddenBlockquote)
                        .hidden()
                }
            }
        }
    }
    
    /// The attributed components laid out for the plain timeline style.
    var plainLayout: some View {
        VStack(alignment: .leading, spacing: 8.0) {
            ForEach(attributedComponents, id: \.self) { component in
                if component.isBlockquote {
                    HStack(spacing: 4.0) {
                        Rectangle()
                            .foregroundColor(Color.red)
                            .frame(width: 4.0)
                        Text(component.attributedString)
                            .foregroundColor(.element.primaryContent)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text(component.attributedString)
                        .padding(.horizontal, timelineStyle == .bubbles ? 4 : 0)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.element.primaryContent)
                }
            }
        }
    }

    private var blockquoteAttributes: AttributeContainer {
        var container = AttributeContainer()
        container.font = .element.subheadline
        return container
    }
}

extension FormattedBodyText {
    init(text: String) {
        self.init(attributedString: AttributedString(text))
    }
}

private extension View {
    func blockquoteFormatting(isReply: Bool) -> some View {
        lineLimit(isReply ? 3 : nil)
            .foregroundColor(.element.tertiaryContent)
            .fixedSize(horizontal: false, vertical: true)
            .padding(EdgeInsets(top: 4, leading: 12, bottom: 4, trailing: 12))
    }
}

// MARK: - Previews

struct FormattedBodyText_Previews: PreviewProvider {
    static var previews: some View {
        body
        body
            .timelineStyle(.plain)
    }
    
    @ViewBuilder
    static var body: some View {
        let htmlStrings = [
            """
            Text before blockquote
            <blockquote>
            <b>bold</b> <i>italic</i>
            </blockquote>Text after blockquote
            """,
            """
            <blockquote>First blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Second blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Third blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            """,
            """
            <code>Hello world</code>
            <p>Text</p>
            <code><b>Hello</b> <i>world</i></code>
            <p>Text</p>
            <code>Hello world</code>
            """
        ]
        
        let attributedStringBuilder = AttributedStringBuilder()
        
        VStack(alignment: .leading, spacing: 24.0) {
            ForEach(htmlStrings, id: \.self) { htmlString in
                if let attributedString = attributedStringBuilder.fromHTML(htmlString) {
                    FormattedBodyText(attributedString: attributedString)
                        .previewBubble()
                }
            }
            FormattedBodyText(text: "Some plain text that's not an attributed component.")
                .previewBubble()
            FormattedBodyText(text: "Some plain text that's not an attributed component. This one is really long.")
                .previewBubble()
        }
        .padding()
    }
}

private struct PreviewBubbleModifier: ViewModifier {
    @Environment(\.timelineStyle) private var timelineStyle
    
    func body(content: Content) -> some View {
        content
            .padding(timelineStyle == .bubbles ? 8 : 0)
            .background(timelineStyle == .bubbles ? Color.element.systemGray6 : nil)
            .cornerRadius(timelineStyle == .bubbles ? 12 : 0)
    }
}

private extension View {
    func previewBubble() -> some View {
        modifier(PreviewBubbleModifier())
    }
}
