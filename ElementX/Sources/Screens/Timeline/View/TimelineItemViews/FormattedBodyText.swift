//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct FormattedBodyText: View {
    @Environment(\.layoutDirection) private var layoutDirection
    
    private let attributedString: AttributedString
    private let additionalWhitespacesCount: Int
    private let boostFontSize: Bool
    
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
        
        if boostFontSize, let range = adjustedAttributedString.range(of: string) {
            adjustedAttributedString[range].font = UIFont.systemFont(ofSize: 48.0)
        }
        
        return adjustedAttributedString.formattedComponents
    }
    
    init(attributedString: AttributedString,
         additionalWhitespacesCount: Int = 0,
         boostFontSize: Bool = false) {
        self.attributedString = attributedString
        self.additionalWhitespacesCount = additionalWhitespacesCount
        self.boostFontSize = boostFontSize
    }
    
    init(text: String, additionalWhitespacesCount: Int = 0, boostFontSize: Bool = false) {
        self.init(attributedString: AttributedString(text),
                  additionalWhitespacesCount: additionalWhitespacesCount,
                  boostFontSize: boostFontSize)
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
        body(AttributedStringBuilderV1(cacheKey: "v1", mentionBuilder: MentionBuilder()))
            .previewLayout(.sizeThatFits)
        
        body(AttributedStringBuilderV2(cacheKey: "v2", mentionBuilder: MentionBuilder()))
            .previewLayout(.sizeThatFits)
    }
    
    @ViewBuilder
    // swiftlint:disable:next function_body_length
    static func body(_ attributedStringBuilder: AttributedStringBuilderProtocol) -> some View {
        let htmlStrings = [
            """
            Nothing is as permanent as a temporary solution that works. 
            Experience is the name everyone gives to their mistakes. 
            If debugging is the process of removing bugs, then programming must be the process of putting them in.
            """,
            """
            <h1>H1 Header</h1></br>
            <h2>H2 Header</h2></br>
            <h3>H3 Header</h3></br>
            <h4>H4 Header</h4></br>
            <h5>H5 Header</h5></br>
            <h6>H6 Header</h6>
            """,
            """
            <p>This is a paragraph.</p><p>And this is another one.</p>
            <div>And this is a division.</div>
            New lines are ignored.\n\nLike so.</br>
            But this line comes after a line break.</br>
            """,
            """
            We expect various identifiers to be (partially) detected:</br>
            !room:matrix.org, #room:matrix.org, $event:matrix.org, @user:matrix.org</br>
            matrix://roomid/room:matrix.org, matrix://r/room:matrix.org, matrix://roomid/room:matrix.org/e/event:matrix.org, matrix://roomid/room:matrix.org/u/user:matrix.org</br>
            """,
            """
            Links too:</br><a href=\"https://www.matrix.org/\">Matrix rules! 🤘</a>, matrix.org, www.matrix.org, http://matrix.org
            """,
            """
            <b>Text</b> <i>formatting</i> <u>should</u> <s>work</s> properly.</br>
            <strong>Text</strong> <em>formatting</em> does <del>work!</del>.</br>
            <b>And <i>mixed</i></b> <em><s>formatting</s></em> <del><strong>works</strong></del> <u><b>too!!1!</b></u>.
            <br>
            <sup>Thumbs</sup> if you liked it, <sub>sub</sub> if you loved it!
            """,
            """
            Text before blockquote<blockquote><b>Nothing</b> <i>is</i> as permanent as a <u>temporary<u> solution that <a href=\"https://www.matrix.org/\">works.</blockquote>Text after blockquote
            """,
            """
            <blockquote>First blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Second blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            <blockquote>Third blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
            """,
            """
            <blockquote>A blockquote that is long and goes onto multiple lines </blockquote>
            <p>Then another line of text to reply to the blockquote, also multiline.</p>
            <blockquote>Then a short blockquote.</blockquote><p>Followed by another short sentence.</p>
            """,
            """
            <pre>A preformatted code block<code>struct ContentView: View {
                var body: some View {
                    VStack {
                        Text("Knock, knock!")
                            .padding()
                            .background(Color.yellow, in: RoundedRectangle(cornerRadius: 8))
                        Text("Who's there?")
                    }
                    .padding()
                }
            }</code></pre></br>
            Followed by some plain code blocks</br>
            <code>Hello, world!</code>
            <code><b>Hello</b>, <i>world!</i></code>
            <code><b>Hello</b>, <a href="https://www.matrix.org">world!</a></code>
            """,
            """
            This is an unordered list
            <ul>
            <li>Jones’ <b>Crumpets</b></li>
            <li><i>Crumpetorium</i></li>
            <li>Village <u>Bakery</u></li>
            </ul>
            """,
            """
            This is an ordered list
            <ol>
            <li>Jelly Belly</li>
            <li>Starburst</li>
            <li>Skittles</li>
            </ol>
            """
        ]
        
        ScrollView {
            VStack(alignment: .leading, spacing: 4.0) {
                ForEach(htmlStrings, id: \.self) { htmlString in
                    HStack(alignment: .top, spacing: 0) {
                        Text(htmlString)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(4.0)
                        
                        Divider()
                            .background(.black)
                        
                        if let attributedString = attributedStringBuilder.fromHTML(htmlString) {
                            FormattedBodyText(attributedString: attributedString)
                                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                                .bubbleBackground()
                                .padding(4.0)
                        }
                    }
                    .border(.black)
                }
                
                FormattedBodyText(attributedString: AttributedString("Some plain text wrapped in an AttributedString."))
                    .bubbleBackground()
                
                FormattedBodyText(text: "Some plain text that's not an attributed component.")
                    .bubbleBackground()
                
                FormattedBodyText(text: "❤️", boostFontSize: true)
                    .bubbleBackground()
            }
            .padding()
        }
    }
}
