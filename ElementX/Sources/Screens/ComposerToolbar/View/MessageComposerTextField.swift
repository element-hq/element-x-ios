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

typealias EnterKeyHandler = () -> Void
typealias PasteHandler = (NSItemProvider) -> Void

struct MessageComposerTextField: View {
    let placeholder: String
    @Binding var text: String
    var focused: FocusState<Bool>.Binding
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
            .focused(focused)
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        if text.isEmpty {
            Text(placeholder)
                .foregroundColor(.compound.textPlaceholder)
                .accessibilityHidden(true)
        }
    }
}

private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var isMultiline: Bool
    
    let maxHeight: CGFloat

    let enterKeyHandler: EnterKeyHandler
    let pasteHandler: PasteHandler
    
    private let font = UIFont.preferredFont(forTextStyle: .body)
    
    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textView = ElementTextView()
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
        if textView.text != text {
            textView.text = text

            if text.isEmpty {
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
        private var text: Binding<String>
        
        private let maxHeight: CGFloat
        
        private let enterKeyHandler: EnterKeyHandler
        private let pasteHandler: PasteHandler
        
        init(text: Binding<String>,
             maxHeight: CGFloat,
             enterKeyHandler: @escaping EnterKeyHandler,
             pasteHandler: @escaping PasteHandler) {
            self.text = text
            self.maxHeight = maxHeight
            self.enterKeyHandler = enterKeyHandler
            self.pasteHandler = pasteHandler
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
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

private class ElementTextView: UITextView {
    weak var elementDelegate: ElementTextViewDelegate?
    
    var isMultiline: Binding<Bool>?
    
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
}

struct MessageComposerTextField_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            PreviewWrapper(text: "123")
            PreviewWrapper(text: "")
            PreviewWrapper(text: "A really long message that will wrap to multiple lines on a phone in portrait.")
        }
    }
    
    struct PreviewWrapper: View {
        @State var text: String
        @State var isMultiline: Bool
        
        init(text: String) {
            _text = .init(initialValue: text)
            _isMultiline = .init(initialValue: false)
        }
        
        var body: some View {
            MessageComposerTextField(placeholder: "Placeholder",
                                     text: $text,
                                     focused: FocusState().projectedValue,
                                     isMultiline: $isMultiline,
                                     maxHeight: 300,
                                     enterKeyHandler: { },
                                     pasteHandler: { _ in })
        }
    }
}
