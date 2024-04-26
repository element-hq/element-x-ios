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

struct MessageComposerTextField: View {
    let placeholder: String
    @Binding var text: NSAttributedString
    @Binding var isMultiline: Bool

    let maxHeight: CGFloat
    let enterKeyHandler: EnterKeyHandler
    let pasteHandler: PasteHandler

    var body: some View {
        UITextViewWrapper(text: $text,
                          isMultiline: $isMultiline,
                          maxHeight: maxHeight,
                          enterKeyHandler: enterKeyHandler,
                          pasteHandler: pasteHandler)
            .accessibilityLabel(placeholder)
            .background(placeholderView, alignment: .topLeading)
    }

    @ViewBuilder
    private var placeholderView: some View {
        if text.string.isEmpty {
            Text(placeholder)
                .foregroundColor(.compound.textPlaceholder)
                .accessibilityHidden(true)
        }
    }
}

private struct UITextViewWrapper: UIViewRepresentable {
    @Environment(\.roomContext) private var roomContext

    @Binding var text: NSAttributedString
    @Binding var isMultiline: Bool

    let maxHeight: CGFloat

    let enterKeyHandler: EnterKeyHandler
    let pasteHandler: PasteHandler

    private let font = UIFont.preferredFont(forTextStyle: .body)

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        // Need to use TextKit 1 for mentions
        let textView = ElementTextView(usingTextLayoutManager: false)
        textView.roomContext = roomContext
        
        textView.isMultiline = $isMultiline
        textView.delegate = context.coordinator
        textView.elementDelegate = context.coordinator
        textView.textColor = .compound.textPrimary
        textView.isEditable = true
        textView.font = font
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.clear
        textView.returnKeyType = .default
        textView.textContainer.lineFragmentPadding = 0.0
        textView.textContainerInset = .zero
        textView.keyboardType = .default

        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return textView
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        // Note: Coalescing a width of zero here returns a size for the view with 1 line of text visible.
        let newSize = uiView.sizeThatFits(CGSize(width: proposal.width ?? .zero,
                                                 height: CGFloat.greatestFiniteMagnitude))
        let width = proposal.width ?? newSize.width
        let height = min(maxHeight, newSize.height)

        return CGSize(width: width, height: height)
    }

    func updateUIView(_ textView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        if textView.attributedText != text {
            textView.attributedText = text
            
            // Prevent the textView from randomly using the tint color
            textView.typingAttributes = [.font: font,
                                         .foregroundColor: UIColor(.compound.textPrimary)]
            
            if text.string.isEmpty {
                // text cleared, probably because the written text is sent
                // reload keyboard type
                if textView.isFirstResponder {
                    textView.keyboardType = .twitter
                    textView.reloadInputViews()
                    textView.keyboardType = .default
                    textView.reloadInputViews()
                }
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    maxHeight: maxHeight,
                    enterKeyHandler: enterKeyHandler,
                    pasteHandler: pasteHandler)
    }

    final class Coordinator: NSObject, UITextViewDelegate, ElementTextViewDelegate {
        private var text: Binding<NSAttributedString>

        private let maxHeight: CGFloat

        private let enterKeyHandler: EnterKeyHandler
        private let pasteHandler: PasteHandler

        init(text: Binding<NSAttributedString>,
             maxHeight: CGFloat,
             enterKeyHandler: @escaping EnterKeyHandler,
             pasteHandler: @escaping PasteHandler) {
            self.text = text
            self.maxHeight = maxHeight
            self.enterKeyHandler = enterKeyHandler
            self.pasteHandler = pasteHandler
        }

        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.attributedText
        }

        func textViewDidReceiveEnterKeyPress(_ textView: UITextView) {
            enterKeyHandler()
        }

        func textViewDidReceiveShiftEnterKeyPress(_ textView: UITextView) {
            textView.insertText("\n")
        }

        func textView(_ textView: UITextView, didReceivePasteWith provider: NSItemProvider) {
            pasteHandler(provider)
        }
    }
}

private protocol ElementTextViewDelegate: AnyObject {
    func textViewDidReceiveShiftEnterKeyPress(_ textView: UITextView)
    func textViewDidReceiveEnterKeyPress(_ textView: UITextView)
    func textView(_ textView: UITextView, didReceivePasteWith provider: NSItemProvider)
}

private class ElementTextView: UITextView, PillAttachmentViewProviderDelegate {
    var roomContext: RoomScreenViewModel.Context?
    var isMultiline: Binding<Bool>?
    
    weak var elementDelegate: ElementTextViewDelegate?
    
    private var pillViews = NSHashTable<UIView>.weakObjects()

    override var keyCommands: [UIKeyCommand]? {
        [UIKeyCommand(input: "\r", modifierFlags: .shift, action: #selector(shiftEnterKeyPressed)),
         UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(enterKeyPressed))]
    }

    @objc func shiftEnterKeyPressed(sender: UIKeyCommand) {
        elementDelegate?.textViewDidReceiveShiftEnterKeyPress(self)
    }

    @objc func enterKeyPressed(sender: UIKeyCommand) {
        elementDelegate?.textViewDidReceiveEnterKeyPress(self)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        guard let isMultiline, let font else { return }

        let numberOfLines = frame.height / font.lineHeight
        if numberOfLines > 1.5 {
            if !isMultiline.wrappedValue {
                isMultiline.wrappedValue = true
            }
        } else {
            if isMultiline.wrappedValue {
                isMultiline.wrappedValue = false
            }
        }
    }

    // Pasting support

    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if super.canPerformAction(action, withSender: sender) {
            return true
        }

        guard action == #selector(paste(_:)) else {
            return false
        }

        return UIPasteboard.general.itemProviders.first?.isSupportedForPasteOrDrop ?? false
    }

    override func paste(_ sender: Any?) {
        guard let provider = UIPasteboard.general.itemProviders.first,
              provider.isSupportedForPasteOrDrop else {
            // If the item is not supported for media upload then
            // just try pasting its contents into the textfield
            super.paste(sender)
            return
        }

        elementDelegate?.textView(self, didReceivePasteWith: provider)
    }
    
    // MARK: PillAttachmentViewProviderDelegate
    
    func invalidateTextAttachmentsDisplay() {
        attributedText.enumerateAttribute(.attachment,
                                          in: NSRange(location: 0, length: attributedText.length),
                                          options: []) { value, range, _ in
            guard value != nil else {
                return
            }
            self.layoutManager.invalidateDisplay(forCharacterRange: range)
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

struct MessageComposerTextField_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 16) {
            PreviewWrapper(text: "123")
            PreviewWrapper(text: "")
            PreviewWrapper(text: "A really long message that will wrap to multiple lines on a phone in portrait.")
        }
    }

    struct PreviewWrapper: View {
        @State var text: NSAttributedString
        @State var isMultiline: Bool

        init(text: String) {
            _text = .init(initialValue: .init(string: ""))
            _isMultiline = .init(initialValue: false)
        }

        var body: some View {
            MessageComposerTextField(placeholder: "Placeholder",
                                     text: $text,
                                     isMultiline: $isMultiline,
                                     maxHeight: 300,
                                     enterKeyHandler: { },
                                     pasteHandler: { _ in })
        }
    }
}
