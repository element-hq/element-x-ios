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
    @Binding private var text: String
    @Binding private var focused: Bool
    
    @State private var dynamicHeight: CGFloat = 100
    
    private let placeholder: String
    private let maxHeight: CGFloat
    private let onEnterKeyHandler: OnEnterKeyHandler
    
    private var showingPlaceholder: Bool {
        text.isEmpty
    }
    
    init(placeholder: String,
         text: Binding<String>,
         focused: Binding<Bool>,
         maxHeight: CGFloat,
         onEnterKeyHandler: @escaping OnEnterKeyHandler) {
        self.placeholder = placeholder
        _text = text
        _focused = focused
        self.maxHeight = maxHeight
        self.onEnterKeyHandler = onEnterKeyHandler
    }
    
    private var placeholderColor: Color {
        .element.secondaryContent
    }
    
    var body: some View {
        UITextViewWrapper(text: $text,
                          calculatedHeight: $dynamicHeight,
                          focused: $focused,
                          maxHeight: maxHeight,
                          onEnterKeyHandler: onEnterKeyHandler)
            .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
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
    @Binding var calculatedHeight: CGFloat
    @Binding var focused: Bool
    
    let maxHeight: CGFloat

    let onEnterKeyHandler: OnEnterKeyHandler
    
    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textView = TextViewWithKeyDetection()
        textView.delegate = context.coordinator
        textView.keyDelegate = context.coordinator
        textView.textColor = .element.primaryContent
        textView.isEditable = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
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
        
        UITextViewWrapper.recalculateHeight(view: textView, result: $calculatedHeight, maxHeight: maxHeight)
        
        DispatchQueue.main.async { // Avoid cycle detected through attribute warnings
            if focused, textView.window != nil, !textView.isFirstResponder {
                textView.becomeFirstResponder()
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    height: $calculatedHeight,
                    focused: $focused,
                    maxHeight: maxHeight,
                    onEnterKeyHandler: onEnterKeyHandler)
    }
    
    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>, maxHeight: CGFloat) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let height = min(maxHeight, newSize.height)
        
        if result.wrappedValue != height {
            DispatchQueue.main.async {
                result.wrappedValue = height // Must be called asynchronously
            }
        }
    }
    
    final class Coordinator: NSObject, UITextViewDelegate, TextViewWithKeyDetectionDelegate {
        private var text: Binding<String>
        private var calculatedHeight: Binding<CGFloat>
        private var focused: Binding<Bool>
        
        private let maxHeight: CGFloat
        
        private let onEnterKeyHandler: OnEnterKeyHandler
        
        init(text: Binding<String>, height: Binding<CGFloat>, focused: Binding<Bool>, maxHeight: CGFloat, onEnterKeyHandler: @escaping OnEnterKeyHandler) {
            self.text = text
            calculatedHeight = height
            self.focused = focused
            self.maxHeight = maxHeight
            self.onEnterKeyHandler = onEnterKeyHandler
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
            UITextViewWrapper.recalculateHeight(view: textView,
                                                result: calculatedHeight,
                                                maxHeight: maxHeight)
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
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        VStack {
            PreviewWrapper(text: "123")
            PreviewWrapper(text: "")
        }
    }
    
    struct PreviewWrapper: View {
        @State var text: String
        @State var focused: Bool
        
        init(text: String) {
            _text = .init(initialValue: text)
            _focused = .init(initialValue: false)
        }
        
        var body: some View {
            MessageComposerTextField(placeholder: "Placeholder", text: $text, focused: $focused, maxHeight: 300, onEnterKeyHandler: { })
        }
    }
}
