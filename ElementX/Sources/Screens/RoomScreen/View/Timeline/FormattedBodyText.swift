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

import SwiftUI

struct FormattedBodyText: View {
    @Environment(\.timelineStyle) private var timelineStyle
    @Environment(\.layoutDirection) private var layoutDirection

    private let attributedString: AttributedString
    private let additionalWhitespacesCount: Int

    private var attributedComponents: [AttributedStringBuilderComponent] {
        var attributedString = layoutPrefix + attributedString
        attributedString.append(AttributedString(stringLiteral: additionalWhitespacesSuffix))
        return attributedString.formattedComponents
    }
    
    init(attributedString: AttributedString, additionalWhitespacesCount: Int = 0) {
        self.attributedString = attributedString
        self.additionalWhitespacesCount = additionalWhitespacesCount
    }

    // These is needed to create the slightly off inlined timestamp effect
    private var additionalWhitespacesSuffix: String {
        .generateBreakableWhitespaceEnd(whitespaceCount: additionalWhitespacesCount, layoutDirection: layoutDirection)
    }

    // This allows to render the start and only the start of the string with the layout of the UI for the current user
    private var layoutPrefix: AttributedString {
        switch layoutDirection {
        case .leftToRight:
            return "\u{2066}"
        case .rightToLeft:
            return "\u{2067}"
        default:
            return ""
        }
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
        TimelineBubbleLayout(spacing: 8) {
            ForEach(attributedComponents, id: \.self) { component in
                if component.isBlockquote {
                    // The rendered blockquote with a greedy width. The custom layout prevents the
                    // infinite width from increasing the overall width of the view.
                    Text(component.attributedString.mergingAttributes(blockquoteAttributes))
                        .foregroundColor(.compound.textPlaceholder)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12.0)
                        .overlay(alignment: .leading) {
                            // User an overlay here so that the rectangle's infinite height doesn't take priority
                            Rectangle()
                                .frame(width: 2.0)
                                .padding(.leading, 6.0)
                                .foregroundColor(.compound.textPlaceholder)
                        }
                        .layoutPriority(TimelineBubbleLayout.Priority.visibleQuote)
                } else {
                    Text(component.attributedString)
                        .padding(.horizontal, timelineStyle == .bubbles ? 4 : 0)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(.element.primaryContent)
                        .layoutPriority(TimelineBubbleLayout.Priority.regularText)
                }
            }
            
            // Make a second iteration through the components adding fixed width blockquotes
            // which are used for layout calculations but won't be rendered.
            ForEach(attributedComponents, id: \.self) { component in
                if component.isBlockquote {
                    Text(component.attributedString.mergingAttributes(blockquoteAttributes))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 12.0)
                        .layoutPriority(TimelineBubbleLayout.Priority.hiddenQuote)
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
        container.font = .compound.bodyMD
        return container
    }
}

extension FormattedBodyText {
    init(text: String, additionalWhitespacesCount: Int = 0) {
        self.init(attributedString: AttributedString(text), additionalWhitespacesCount: additionalWhitespacesCount)
    }
}

// MARK: - Previews

struct FormattedBodyText_Previews: PreviewProvider {
    static var previews: some View {
        body
        body
            .environment(\.timelineStyle, .plain)
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
