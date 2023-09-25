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

import Combine
import SwiftUI

final class MessageTextView: UITextView {
    var roomID: String?
    var updateClosure: (() -> Void)?

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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        invalidateTextAttachmentsDisplay()
    }
}

struct MessageText: UIViewRepresentable {
    @Environment(\.openURL) private var openURLAction: OpenURLAction
    @State var attributedString: AttributedString
    let roomID: String

    func makeUIView(context: Context) -> MessageTextView {
        let textView = MessageTextView(usingTextLayoutManager: false)
        textView.roomID = roomID
        textView.updateClosure = {
            attributedString = AttributedString(textView.attributedText)
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
        textView.attributedText = NSAttributedString(attributedString)
        textView.delegate = context.coordinator
        return textView
    }

    func updateUIView(_ uiView: MessageTextView, context: Context) {
        uiView.attributedText = NSAttributedString(attributedString)
        context.coordinator.openURLAction = openURLAction
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MessageTextView, context: Context) -> CGSize? {
        uiView.sizeThatFits(CGSize(width: proposal.width ?? UIView.layoutFittingExpandedSize.width, height: UIView.layoutFittingCompressedSize.height))
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
            textView.selectedTextRange = nil
        }
        
        func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
            if interaction == .invokeDefaultAction {
                openURLAction.callAsFunction(URL)
            }
            return false
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
        let testData = PillTextAttachmentData(type: .user(userId: "@alice:example.com"))
        guard let attachment = PillTextAttachment(attachmentData: testData) else {
            return AttributedString()
        }
        
        var attributedString = "Hello test test test" + AttributedString(NSAttributedString(attachment: attachment)) + " World!"
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

    private static let attributedStringBuilder = AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL)
    
    @ViewBuilder
    static var attachmentPreview: some View {
        MessageText(attributedString: attributedStringWithAttachment, roomID: "")
            .border(Color.purple)
            .previewDisplayName("Custom Attachment")
    }

    static var previews: some View {
        MessageText(attributedString: attributedString, roomID: "")
            .border(Color.purple)
            .previewDisplayName("Custom Text")
        // For comparison
        Text(attributedString)
            .border(Color.purple)
            .previewDisplayName("SwiftUI Default Text")
        attachmentPreview
        if let attributedString = attributedStringBuilder.fromHTML(htmlStringWithQuote) {
            MessageText(attributedString: attributedString, roomID: "")
                .border(Color.purple)
                .previewDisplayName("With block quote")
        }
        if let attributedString = attributedStringBuilder.fromHTML(htmlStringWithList) {
            MessageText(attributedString: attributedString, roomID: "")
                .border(Color.purple)
                .previewDisplayName("With list")
        }
    }
}
