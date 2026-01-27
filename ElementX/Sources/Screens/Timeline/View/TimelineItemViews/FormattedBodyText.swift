//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
    
    /// These is needed to create the slightly off inlined timestamp effect
    private var additionalWhitespacesSuffix: String {
        .generateBreakableWhitespaceEnd(whitespaceCount: additionalWhitespacesCount, layoutDirection: layoutDirection)
    }
    
    var body: some View {
        mainContent
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(attributedString))
    }
    
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
                } else {
                    switch component.type {
                    case .blockquote:
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
                    case .codeBlock:
                        ScrollView(.horizontal) {
                            MessageText(attributedString: component.attributedString)
                                .padding([.horizontal, .top], 4)
                                .padding(.bottom, 8)
                        }
                        .background(.compound._bgCodeBlock)
                        .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
                        .scrollIndicatorsFlash(onAppear: true)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .layoutPriority(TimelineBubbleLayout.Priority.visibleQuote)
                        .contextMenu {
                            Button(L10n.actionCopy) {
                                UIPasteboard.general.string = component.attributedString.string
                            }
                        }
                    case .plainText:
                        MessageText(attributedString: component.attributedString)
                            .padding(.horizontal, 4)
                            .fixedSize(horizontal: false, vertical: true)
                            .layoutPriority(TimelineBubbleLayout.Priority.regularText)
                    }
                }
            }
            
            // Make a second iteration through the components adding fixed width blockquotes
            // which are used for layout calculations but won't be rendered.
            ForEach(attributedComponents) { component in
                switch component.type {
                case .blockquote:
                    MessageText(attributedString: component.attributedString.mergingAttributes(blockquoteAttributes))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.leading, 12.0)
                        .layoutPriority(TimelineBubbleLayout.Priority.hiddenQuote)
                        .hidden()
                case .codeBlock:
                    // ScrollView contents
                    MessageText(attributedString: component.attributedString)
                        .padding([.horizontal, .top], 4)
                        .padding(.bottom, 8)
                        // ScrollView modifiers
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 4)
                        .layoutPriority(TimelineBubbleLayout.Priority.hiddenQuote)
                        .hidden()
                case .plainText:
                    EmptyView()
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
        body(AttributedStringBuilder(cacheKey: "FormattedBodyText", mentionBuilder: MentionBuilder()))
            .previewLayout(.sizeThatFits)
    }
    
    @ViewBuilder
    static func body(_ attributedStringBuilder: AttributedStringBuilderProtocol) -> some View {
        let htmlStrings = HTMLFixtures.allCases.map(\.rawValue)
        
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
