//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI

final class MessageTextView: UITextView, PillAttachmentViewProviderDelegate, UIGestureRecognizerDelegate {
    var timelineContext: TimelineViewModel.Context?
    var updateClosure: (() -> Void)?
    private var pillViews = NSHashTable<UIView>.weakObjects()
    
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // We don't need to change the behaviour on MacOS
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            gestureRecognizer.delegate = self
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
    
    /// This prevents the magnifying glass from showing up
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer is UILongPressGestureRecognizer {
            return false
        }
        return true
    }
    
    func invalidateTextAttachmentsDisplay() {
        attributedText.enumerateAttribute(.attachment,
                                          in: NSRange(location: 0, length: attributedText.length),
                                          options: []) { value, range, _ in
            guard value != nil else {
                return
            }
            self.layoutManager.invalidateDisplay(forCharacterRange: range)
            updateClosure?()
        }
    }
    
    func registerPillView(_ pillView: UIView) {
        pillViews.add(pillView)
    }
    
    func flushPills() {
        for view in pillViews.allObjects {
            view.alpha = 0.0
            view.removeFromSuperview()
        }
        pillViews.removeAllObjects()
    }
}

/// An `NSTextAttachment` that takes up its declared `bounds` but draws nothing — used
/// as an invisible spacer so a message bubble's text reserves room for the overlaid
/// timestamp. Without this subclass, an attachment with no image would render TextKit's
/// default "missing image" glyph.
private final class TransparentTextAttachment: NSTextAttachment {
    override func image(forBounds imageBounds: CGRect,
                        textContainer: NSTextContainer?,
                        characterIndex charIndex: Int) -> UIImage? {
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        let size = CGSize(width: max(imageBounds.width, 1), height: max(imageBounds.height, 1))
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in }
    }
}

struct MessageText: UIViewRepresentable {
    @Environment(\.openURL) private var openURLAction
    @Environment(\.timelineContext) private var viewModel
    @Environment(\.layoutDirection) private var layoutDirection
    @State private var computedSizes = [Double: CGSize]()
    
    @State var attributedString: AttributedString {
        didSet {
            computedSizes.removeAll()
        }
    }
    
    /// Reserves an invisible inline area of this size at the very end of the rendered
    /// text. Used so that the message bubble's natural size accommodates the timestamp
    /// overlaid on top of the bubble's bottom-trailing corner. TextKit decides whether
    /// the reserved region fits on the last line (timestamp tucks) or wraps to a new
    /// line (timestamp drops below the text).
    var trailingReservedSize: CGSize = .zero
    
    private func makeAttributedText() -> NSAttributedString? {
        guard let baseText = try? NSAttributedString(attributedString, including: \.elementX) else {
            return nil
        }

        let combined = NSMutableAttributedString(attributedString: baseText)
        if trailingReservedSize.width > 0 {
            let attachment = TransparentTextAttachment()
            attachment.isAccessibilityElement = false
            attachment.bounds = CGRect(origin: .zero,
                                       size: CGSize(width: trailingReservedSize.width,
                                                    height: max(trailingReservedSize.height, 1)))

            // When the last paragraph's natural text direction doesn't match the layout
            // direction, the inline attachment would land on the wrong side and overlap the
            // overlaid timestamp. Force it onto its own line so the bubble just grows taller.
            if !lastParagraphDirectionMatchesLayout(in: combined) {
                combined.append(NSAttributedString(string: "\n"))
            }

            combined.append(NSAttributedString(attachment: attachment))
        }

        return combined
    }

    private func lastParagraphDirectionMatchesLayout(in attributedText: NSAttributedString) -> Bool {
        let string = attributedText.string as NSString
        guard string.length > 0 else { return true }

        let lastParagraphRange = string.paragraphRange(for: NSRange(location: string.length - 1, length: 0))
        let lastParagraph = string.substring(with: lastParagraphRange)

        let textIsRTL = lastParagraph.firstStrongCharacterIsRTL
        return textIsRTL == (layoutDirection == .rightToLeft)
    }
    
    func makeUIView(context: Context) -> MessageTextView {
        // Need to use TextKit 1 for mentions
        let textView = MessageTextView(usingTextLayoutManager: false)
        textView.timelineContext = viewModel
        textView.updateClosure = { [weak textView] in
            guard let textView else { return }
            do {
                attributedString = try AttributedString(textView.attributedText, including: \.elementX)
            } catch {
                MXLog.error("Failed to update attributedString: \(error)]")
                return
            }
        }
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true
        
        // Required to allow tapping links
        // We disable selection at delegate level
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        
        // Otherwise links can be dragged and dropped when long pressed
        textView.textDragInteraction?.isEnabled = false
        
        textView.contentInset = .zero
        textView.contentInsetAdjustmentBehavior = .never
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.layoutManager.usesFontLeading = false
        textView.backgroundColor = .clear
        if let attributedText = makeAttributedText() {
            textView.attributedText = attributedText
        }
        textView.delegate = context.coordinator
        return textView
    }
    
    func updateUIView(_ uiView: MessageTextView, context: Context) {
        if let newAttributedText = makeAttributedText(),
           uiView.attributedText != newAttributedText {
            uiView.flushPills()
            uiView.attributedText = newAttributedText
            computedSizes.removeAll()
        }
        context.coordinator.openURLAction = openURLAction
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MessageTextView, context: Context) -> CGSize? {
        let proposalWidth = proposal.width ?? UIView.layoutFittingExpandedSize.width
        
        if let size = computedSizes[proposalWidth] {
            return size
        }
        
        let size = uiView.sizeThatFits(CGSize(width: proposalWidth, height: UIView.layoutFittingCompressedSize.height))
        DispatchQueue.main.async {
            computedSizes[proposalWidth] = size
        }
        return size
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(openURLAction: openURLAction)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var openURLAction: OpenURLAction
        
        init(openURLAction: OpenURLAction) {
            self.openURLAction = openURLAction
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !ProcessInfo.processInfo.isiOSAppOnMac else {
                return
            }
            textView.selectedTextRange = nil
        }
        
        func textView(_ textView: UITextView, primaryActionFor textItem: UITextItem, defaultAction: UIAction) -> UIAction? {
            if case .link(let url) = textItem.content {
                return .init(title: defaultAction.title,
                             image: defaultAction.image,
                             discoverabilityTitle: defaultAction.discoverabilityTitle,
                             attributes: defaultAction.attributes,
                             state: defaultAction.state) { [weak self] _ in
                    self?.openURLAction.callAsFunction(url)
                }
            }
            return defaultAction
        }
        
        func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            switch textItem.content {
            case let .link(url):
                guard !url.requiresConfirmation else {
                    return nil
                }
                // We don't want to show a URL preview for permalinks
                let isPermalink = parseMatrixEntityFrom(uri: url.absoluteString) != nil
                return .init(preview: isPermalink ? nil : .default, menu: defaultMenu)
            default:
                return nil
            }
        }
    }
}

// MARK: - Previews

struct MessageText_Previews: PreviewProvider, TestablePreview {
    private static let defaultFontContainer: AttributeContainer = {
        var container = AttributeContainer()
        container.font = UIFont.preferredFont(forTextStyle: .body)
        return container
    }()
    
    private static let attributedString = AttributedString("Hello World! Hello world! Hello world! Hello world! Hello World! Hellooooooooooooooooooooooo Woooooooooooooooooooooorld", attributes: defaultFontContainer)
    
    private static let attributedStringWithAttachment: AttributedString = {
        let testData = PillTextAttachmentData(type: .user(userID: "@alice:example.com"), font: .preferredFont(forTextStyle: .body))
        guard let attachment = PillTextAttachment(attachmentData: testData) else {
            return AttributedString()
        }
        
        var attributedString = "Hello test test test " + AttributedString(NSAttributedString(attachment: attachment)) + " World!"
        attributedString
            .mergeAttributes(defaultFontContainer)
        return attributedString
    }()
    
    private static let htmlStringWithQuote =
        """
        <blockquote>A blockquote that is long and goes onto multiple lines as the first item in the message</blockquote><p>Then another line of text here to reply to the blockquote, which is also a multiline component.</p>
        """
    
    private static let htmlStringWithList = "<p>This is a list</p>\n<ul><li>One</li>\n<li>Two</li>\n<li>And number 3</li>\n</ul>\n"
    
    private static let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
    
    static var attachmentPreview: some View {
        MessageText(attributedString: attributedStringWithAttachment)
            .border(Color.purple)
            .environmentObject(TimelineViewModel.mock.context)
    }
    
    static var previews: some View {
        MessageText(attributedString: attributedString)
            .border(Color.purple)
            .previewDisplayName("Custom Text")
        // For comparison
        Text(attributedString)
            .border(Color.purple)
            .previewDisplayName("SwiftUI Default Text")
        attachmentPreview
            .previewDisplayName("Custom Attachment")
        if let attributedString = attributedStringBuilder.fromHTML(htmlStringWithQuote) {
            MessageText(attributedString: attributedString)
                .border(Color.purple)
                .previewDisplayName("With block quote")
        }
        if let attributedString = attributedStringBuilder.fromHTML(htmlStringWithList) {
            MessageText(attributedString: attributedString)
                .border(Color.purple)
                .previewDisplayName("With list")
        }
    }
}
