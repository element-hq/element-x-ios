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

typealias OnEnterKeyHandler = () -> Void

struct MessageComposerTextField: View {
    let placeholder: String
    @Binding var text: String
    @Binding var focused: Bool
    @Binding var isMultiline: Bool
    
    let maxHeight: CGFloat
    let onEnterKeyHandler: OnEnterKeyHandler
    
    private var showingPlaceholder: Bool {
        text.isEmpty
    }
    
    private var placeholderColor: Color {
        .element.secondaryContent
    }
    
    var body: some View {
        UITextViewWrapper(text: $text,
                          focused: $focused,
                          isMultiline: $isMultiline,
                          maxHeight: maxHeight,
                          onEnterKeyHandler: onEnterKeyHandler)
            .background(placeholderView, alignment: .topLeading)
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        if showingPlaceholder {
            Text(placeholder)
                .foregroundColor(placeholderColor)
        }
    }
}

private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var focused: Bool
    @Binding var isMultiline: Bool
    
    let maxHeight: CGFloat

    let onEnterKeyHandler: OnEnterKeyHandler
    
    private let font = UIFont.preferredFont(forTextStyle: .body)
    
    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textView = TextViewWithKeyDetection()
        textView.delegate = context.coordinator
        textView.keyDelegate = context.coordinator
        textView.textColor = .element.primaryContent
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
        
        let numberOfLines = height / font.lineHeight
        if numberOfLines > 1.5 {
            if !isMultiline {
                DispatchQueue.main.async { isMultiline = true }
            }
        } else {
            if isMultiline {
                DispatchQueue.main.async { isMultiline = false }
            }
        }
        
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
        
        DispatchQueue.main.async { // Avoid cycle detected through attribute warnings
            if focused, textView.window != nil, !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    focused: $focused,
                    isMultiline: $isMultiline,
                    maxHeight: maxHeight,
                    onEnterKeyHandler: onEnterKeyHandler)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate, TextViewWithKeyDetectionDelegate {
        private var text: Binding<String>
        private var focused: Binding<Bool>
//        private var isMultiline: Binding<Bool>
        
        private let maxHeight: CGFloat
        
        private let onEnterKeyHandler: OnEnterKeyHandler
        
        init(text: Binding<String>,
             focused: Binding<Bool>,
             isMultiline: Binding<Bool>,
             maxHeight: CGFloat,
             onEnterKeyHandler: @escaping OnEnterKeyHandler) {
            self.text = text
            self.focused = focused
            self.maxHeight = maxHeight
            self.onEnterKeyHandler = onEnterKeyHandler
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            focused.wrappedValue = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            focused.wrappedValue = false
        }
        
        func enterKeyWasPressed(textView: UITextView) {
            onEnterKeyHandler()
        }
        
        func shiftEnterKeyPressed(textView: UITextView) {
            textView.insertText("\n")
        }
    }
}

private protocol TextViewWithKeyDetectionDelegate: AnyObject {
    func enterKeyWasPressed(textView: UITextView)
    func shiftEnterKeyPressed(textView: UITextView)
}

private class TextViewWithKeyDetection: UITextView {
    weak var keyDelegate: TextViewWithKeyDetectionDelegate?
    
    override var keyCommands: [UIKeyCommand]? {
        [UIKeyCommand(input: "\r", modifierFlags: .shift, action: #selector(shiftEnterKeyPressed)),
         UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(enterKeyPressed))]
    }
    
    @objc func shiftEnterKeyPressed(sender: UIKeyCommand) {
        keyDelegate?.shiftEnterKeyPressed(textView: self)
    }
    
    @objc func enterKeyPressed(sender: UIKeyCommand) {
        keyDelegate?.enterKeyWasPressed(textView: self)
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
        @State var focused: Bool
        @State var isMultiline: Bool
        
        init(text: String) {
            _text = .init(initialValue: text)
            _focused = .init(initialValue: false)
            _isMultiline = .init(initialValue: false)
        }
        
        var body: some View {
            MessageComposerTextField(placeholder: "Placeholder",
                                     text: $text,
                                     focused: $focused,
                                     isMultiline: $isMultiline,
                                     maxHeight: 300,
                                     onEnterKeyHandler: { })
        }
    }
}
