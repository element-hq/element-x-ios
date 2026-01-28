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
        layout
            .tint(.compound.textLinkExternal)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(attributedString))
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
                        BlockquoteView(attributedString: component.attributedString, mode: .rendering)
                            .timelineBubbleLayoutSize(.bubbleWidth(mode: .rendering))
                    case .codeBlock:
                        CodeBlockView(attributedString: component.attributedString, mode: .rendering)
                            .timelineBubbleLayoutSize(.bubbleWidth(mode: .rendering))
                            .contextMenu {
                                Button(L10n.actionCopy) {
                                    UIPasteboard.general.string = component.attributedString.string
                                }
                            }
                    case .plainText:
                        MessageText(attributedString: component.attributedString)
                            .padding(.horizontal, 4)
                            .fixedSize(horizontal: false, vertical: true)
                            .timelineBubbleLayoutSize(.natural)
                    }
                }
            }
            
            // Make a second iteration through the components adding naturally sized versions of the
            // block quotes and code blocks which are used for layout calculations but won't be rendered.
            ForEach(attributedComponents) { component in
                switch component.type {
                case .blockquote:
                    BlockquoteView(attributedString: component.attributedString, mode: .layout)
                        .timelineBubbleLayoutSize(.bubbleWidth(mode: .layout))
                        .hidden()
                case .codeBlock:
                    CodeBlockView(attributedString: component.attributedString, mode: .layout)
                        .timelineBubbleLayoutSize(.bubbleWidth(mode: .layout))
                        .hidden()
                case .plainText:
                    EmptyView()
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    /// The view used to render a blockquote component. It can be configured in one of 2 modes:
    /// - `.layout`: The view is given it's natural size to be used for layout calculations.
    /// - `.rendering`: The view has a greedy width that, in combination with the custom layout,
    /// will fill any available space, whilst remaining constrained by the bubble's calculated width.
    struct BlockquoteView: View {
        let attributedString: AttributedString
        let mode: TimelineBubbleLayout.Size.BubbleWidthMode
        
        var body: some View {
            MessageText(attributedString: attributedString.mergingAttributes(blockquoteAttributes))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: mode == .rendering ? .infinity : nil, alignment: .leading)
                .padding(.leading, 12.0)
                .overlay(alignment: .leading) {
                    // Use an overlay here so that the rectangle's infinite height doesn't take priority
                    if mode == .rendering {
                        Capsule()
                            .frame(width: 2.0)
                            .padding(.leading, 5.0)
                            .foregroundColor(.compound.textSecondary)
                            .padding(.vertical, 2)
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
    
    /// The view used to render a code block component. It can be configured in one of 2 modes:
    /// - `.layout`: The view is given it's natural size to be used for layout calculations.
    /// - `.rendering`: The view has a greedy width that, in combination with the custom layout,
    /// will fill any available space, whilst remaining constrained by the bubble's calculated width.
    private struct CodeBlockView: View {
        let attributedString: AttributedString
        let mode: TimelineBubbleLayout.Size.BubbleWidthMode
        
        @State private var maxWidth: CGFloat = .zero
        
        var body: some View {
            ScrollView(.horizontal) {
                MessageText(attributedString: attributedString)
                    .padding([.horizontal, .top], 4)
                    .padding(.bottom, 8)
                    .onGeometryChange(for: CGFloat.self) { $0.size.width } action: { maxWidth = $0 }
            }
            .frame(maxWidth: mode == .layout ? maxWidth : nil)
            .background(.compound._bgCodeBlock)
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .scrollIndicatorsFlash(onAppear: true)
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Previews

struct FormattedBodyText_Previews: PreviewProvider, TestablePreview {
    static let attributedStringBuilder = AttributedStringBuilder(cacheKey: "FormattedBodyText", mentionBuilder: MentionBuilder())
    static var previews: some View {
        htmlFixtures
        
        basicText
            .previewLayout(.sizeThatFits)
            .previewDisplayName("basicText")
        
        singleColumnComponents
            .previewLayout(.sizeThatFits)
            .previewDisplayName("singleColumnComponents")
    }
    
    static var basicText: some View {
        VStack(alignment: .leading, spacing: 4.0) {
            FormattedBodyText(attributedString: AttributedString("Some plain text wrapped in an AttributedString."))
                .bubbleBackground()
            
            FormattedBodyText(text: "Some plain text that's not an attributed component.")
                .bubbleBackground()
            
            FormattedBodyText(text: "❤️", boostFontSize: true)
                .bubbleBackground()
        }
        .padding()
    }
    
    /// A preview to help ensure that none of the component types we support result
    /// in a bubble's width becoming wider than the natural width of its contents.
    @ViewBuilder
    static var singleColumnComponents: some View {
        let html = """
        <blockquote>A</blockquote>
        <pre><code>B</code></pre>
        <p>C</p>
        """
        
        if let attributedString = attributedStringBuilder.fromHTML(html) {
            FormattedBodyText(attributedString: attributedString)
                .bubbleBackground()
                .padding(4.0)
        }
    }
    
    @ViewBuilder
    static var htmlFixtures: some View {
        let htmlFixtures = HTMLFixtures.allCases
        
        ForEach(htmlFixtures, id: \.rawValue) { htmlFixture in
            HStack(alignment: .top, spacing: 0) {
                let htmlString = htmlFixture.rawValue
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
            .fixedSize(horizontal: false, vertical: true)
            .border(.black)
            .padding()
            .previewLayout(.sizeThatFits)
            .previewDisplayName("\(htmlFixture)")
        }
    }
}
