//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI

final class MessageTextView: UITextView, PillAttachmentViewProviderDelegate {
    var timelineContext: TimelineViewModel.Context?
    var updateClosure: (() -> Void)?
    private var pillViews = NSHashTable<UIView>.weakObjects()
    
    // This prevents the magnifying glass from showing up
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        gestureRecognizer as? UILongPressGestureRecognizer == nil
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

struct MessageText: UIViewRepresentable {
    @Environment(\.openURL) private var openURLAction
    @Environment(\.timelineContext) private var viewModel
    @State private var computedSizes = [Double: CGSize]()
    
    @State var attributedString: AttributedString {
        didSet {
            computedSizes.removeAll()
        }
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
                MXLog.error("[MessageText] Failed to update attributedString: \(error)]")
                return
            }
        }
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.adjustsFontForContentSizeCategory = true

        // Required to allow tapping links
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
        if let attributedText = try? NSAttributedString(attributedString, including: \.elementX) {
            textView.attributedText = attributedText
        }
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: MessageTextView, context: Context) {
        if let newAttributedText = try? NSAttributedString(attributedString, including: \.elementX),
           uiView.attributedText != newAttributedText {
            uiView.flushPills()
            uiView.attributedText = newAttributedText
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
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            switch interaction {
            case .invokeDefaultAction:
                openURLAction.callAsFunction(URL)
                return false
            case .preview:
                // We don't want to show a URL preview for permalinks
                return parseMatrixEntityFrom(uri: URL.absoluteString) == nil
            default:
                return true
            }
        }
        
        @available(iOS 17.0, *)
        func textView(_ textView: UITextView, menuConfigurationFor textItem: UITextItem, defaultMenu: UIMenu) -> UITextItem.MenuConfiguration? {
            switch textItem.content {
            case let .link(url):
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
        <blockquote>A blockquote that is long and goes onto multiple lines as the first item in the message</blockquote>
        <p>Then another line of text here to reply to the blockquote, which is also a multiline component.</p>
        """
    
    private static let htmlStringWithList = "<p>This is a list</p>\n<ul>\n<li>One</li>\n<li>Two</li>\n<li>And number 3</li>\n</ul>\n"

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
