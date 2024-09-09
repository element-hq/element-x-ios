//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct FormattedBodyText: View {
    @Environment(\.layoutDirection) private var layoutDirection
    
    private let attributedString: AttributedString
    private let additionalWhitespacesCount: Int
    private let boostEmojiSize: Bool
    
    private let defaultAttributesContainer: AttributeContainer = {
        var container = AttributeContainer()
        // Equivalent to compound's bodyLG
        container.font = UIFont.preferredFont(forTextStyle: .body)
        container.foregroundColor = UIColor.compound.textPrimary
        return container
    }()
        
    private var attributedComponents: [AttributedStringBuilderComponent] {
        var adjustedAttributedString = attributedString + AttributedString(additionalWhitespacesSuffix)
        
        // If this is not a list, force the writing direction by adding the correct unicode character.
        if !String(attributedString.characters).starts(with: "\t") {
            adjustedAttributedString = AttributedString(layoutDirection.isolateLayoutUnicodeString) + adjustedAttributedString
        }
        
        // Required to allow the underlying TextView to use  body font when no font is specifie in the AttributedString.
        adjustedAttributedString.mergeAttributes(defaultAttributesContainer, mergePolicy: .keepCurrent)
        
        let string = String(attributedString.characters)
        
        if boostEmojiSize,
           string.containsOnlyEmoji,
           let range = adjustedAttributedString.range(of: string) {
            adjustedAttributedString[range].font = UIFont.systemFont(ofSize: 48.0)
        }
        
        return adjustedAttributedString.formattedComponents
    }
    
    init(attributedString: AttributedString,
         additionalWhitespacesCount: Int = 0,
         boostEmojiSize: Bool = false) {
        self.attributedString = attributedString
        self.additionalWhitespacesCount = additionalWhitespacesCount
        self.boostEmojiSize = boostEmojiSize
    }
    
    init(text: String, additionalWhitespacesCount: Int = 0, boostEmojiSize: Bool = false) {
        self.init(attributedString: AttributedString(text),
                  additionalWhitespacesCount: additionalWhitespacesCount,
                  boostEmojiSize: boostEmojiSize)
    }
    
    // These is needed to create the slightly off inlined timestamp effect
    private var additionalWhitespacesSuffix: String {
        .generateBreakableWhitespaceEnd(whitespaceCount: additionalWhitespacesCount, layoutDirection: layoutDirection)
    }
    
    var body: some View {
        mainContent
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(attributedString))
    }
    
    @ViewBuilder
    var mainContent: some View {
        layout
            .tint(.compound.textLinkExternal)
    }
    
    /// The attributed components laid out for the bubbles timeline style.
    var layout: some View {
        TimelineBubbleLayout(spacing: 8) {
            ForEach(attributedComponents) { component in
                // Ignore if the string contains only the layout correction
                if String(component.attributedString.characters) == layoutDirection.isolateLayoutUnicodeString {
                    EmptyView()
                } else if component.isBlockquote {
                    // The rendered blockquote with a greedy width. The custom layout prevents the
                    // infinite width from increasing the overall width of the view.
                    MessageText(attributedString: component.attributedString.mergingAttributes(blockquoteAttributes))
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 12.0)
                        .overlay(alignment: .leading) {
                            // User an overlay here so that the rectangle's infinite height doesn't take priority
                            Capsule()
                                .frame(width: 2.0)
                                .padding(.leading, 5.0)
                                .foregroundColor(.compound.textSecondary)
                                .padding(.vertical, 2)
                        }
                        .layoutPriority(TimelineBubbleLayout.Priority.visibleQuote)
                } else {
                    MessageText(attributedString: component.attributedString)
                        .padding(.horizontal, 4)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(TimelineBubbleLayout.Priority.regularText)
                }
            }
            
            // Make a second iteration through the components adding fixed width blockquotes
            // which are used for layout calculations but won't be rendered.
            ForEach(attributedComponents) { component in
                if component.isBlockquote {
                    MessageText(attributedString: component.attributedString.mergingAttributes(blockquoteAttributes))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 12.0)
                        .layoutPriority(TimelineBubbleLayout.Priority.hiddenQuote)
                        .hidden()
                }
            }
        }
    }
    
    private var blockquoteAttributes: AttributeContainer {
        // The paragraph style removes the block style paragraph that the parser adds by default
        // Set directly in the constructor to avoid `Conformance to 'Sendable'` warnings
        var container = AttributeContainer([.paragraphStyle: NSParagraphStyle.default])
        // Sadly setting SwiftUI fonts do not work so we would need UIFont equivalents for compound, this one is bodyMD
        container.font = UIFont.preferredFont(forTextStyle: .subheadline)
        container.foregroundColor = UIColor.compound.textSecondary
        
        return container
    }
}

// MARK: - Previews

struct FormattedBodyText_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        body
    }
    
    @ViewBuilder
    static var body: some View {
        let htmlStrings = [
            """
            Plain text\n
            @bob:matrix.org\n
            #room:matrix.org\n
            !room:matrix.org\n
            https://www.matrix.org\n
            www.matrix.org\n
            matrix.org
            """,
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
            <blockquote>A blockquote that is long and goes onto multiple lines as the first item in the message</blockquote>
            <p>Then another line of text here to reply to the blockquote, which is also a multiline component.</p>
            <blockquote>Short line here.</blockquote>
            <p>And a simple reply here.</p>
            """,
            """
            <code>Hello world</code>
            <p>Text</p>
            <code><b>Hello</b> <i>world</i></code>
            <p>Text</p>
            <code>Hello world</code>
            <p>Text</p>
            <code><a href="https://www.matrix.org">matrix.org</a> https://www.matrix.org</code>
            """,
            "<p>This is a list</p>\n<ul>\n<li>One</li>\n<li>Two</li>\n<li>And number 3</li>\n</ul>\n",
            "<ul><li>First item</li><li>Second item</li><li>Third item</li></ul>",
            "<p>test</p>\n<p>test</p>"
        ]
        
        let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
        
        ScrollView {
            VStack(alignment: .leading, spacing: 24.0) {
                ForEach(htmlStrings, id: \.self) { htmlString in
                    if let attributedString = attributedStringBuilder.fromHTML(htmlString) {
                        FormattedBodyText(attributedString: attributedString)
                            .previewBubble()
                    }
                }
                FormattedBodyText(attributedString: AttributedString("Some plain text wrapped in an AttributedString."))
                    .previewBubble()
                FormattedBodyText(text: "Some plain text that's not an attributed component.")
                    .previewBubble()
                FormattedBodyText(text: "Some plain text that's not an attributed component. This one is really long.")
                    .previewBubble()
                
                FormattedBodyText(text: "❤️", boostEmojiSize: true)
                    .previewBubble()
            }
            .padding()
        }
        .previewLayout(.sizeThatFits)
        .snapshotPreferences(delay: 0.25)
    }
}

private struct PreviewBubbleModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(8)
            .background(Color.compound._bgBubbleOutgoing)
            .cornerRadius(12)
            .environmentObject(TimelineViewModel.mock.context)
    }
}

private extension View {
    func previewBubble() -> some View {
        modifier(PreviewBubbleModifier())
    }
}
