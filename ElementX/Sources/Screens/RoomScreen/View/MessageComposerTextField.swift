//
//  MessageComposerTextField.swift
//  ElementX
//
//  Created by Stefan Ceriu on 15/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import SwiftUI

struct MessageComposerTextField: View {
    @Binding private var text: String
    @State private var dynamicHeight: CGFloat = 100
    @State private var isEditing = false
    
    private let placeholder: String
    private let maxHeight: CGFloat
    
    private var showingPlaceholder: Bool {
        text.isEmpty
    }

    init(placeholder: String, text: Binding<String>, maxHeight: CGFloat) {
        self.placeholder = placeholder
        _text = text
        self.maxHeight = maxHeight
    }
    
    private var placeholderColor: Color {
        .gray
    }
    
    private var borderColor: Color {
        .element.accent
    }
    
    private var borderWidth: CGFloat {
        isEditing ? 2.0 : 1.0
    }
    
    var body: some View {
        let rect = RoundedRectangle(cornerRadius: 8.0)
        return UITextViewWrapper(text: $text,
                                 calculatedHeight: $dynamicHeight,
                                 isEditing: $isEditing,
                                 maxHeight: maxHeight)
            .frame(minHeight: dynamicHeight, maxHeight: dynamicHeight)
            .padding(4.0)
            .background(placeholderView, alignment: .topLeading)
            .clipShape(rect)
            .overlay(rect.stroke(borderColor, lineWidth: borderWidth))
            .animation(.elementDefault, value: isEditing)
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        if showingPlaceholder {
            Text(placeholder)
                .foregroundColor(placeholderColor)
                .padding(.leading, 8.0)
                .padding(.top, 12.0)
        }
    }
}

private struct UITextViewWrapper: UIViewRepresentable {
    typealias UIViewType = UITextView

    @Binding var text: String
    @Binding var calculatedHeight: CGFloat
    @Binding var isEditing: Bool
    
    let maxHeight: CGFloat

    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator

        textView.isEditable = true
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.isSelectable = true
        textView.isUserInteractionEnabled = true
        textView.backgroundColor = UIColor.clear
        textView.returnKeyType = .default

        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return textView
    }

    func updateUIView(_ view: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        if view.text != text {
            view.text = text
        }

        UITextViewWrapper.recalculateHeight(view: view, result: $calculatedHeight, maxHeight: maxHeight)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    height: $calculatedHeight,
                    isEditing: $isEditing,
                    maxHeight: maxHeight)
    }
    
    fileprivate static func recalculateHeight(view: UIView, result: Binding<CGFloat>, maxHeight: CGFloat) {
        let newSize = view.sizeThatFits(CGSize(width: view.frame.size.width, height: CGFloat.greatestFiniteMagnitude))
        
        let height = min(maxHeight, newSize.height)
        
        if result.wrappedValue != height {
            DispatchQueue.main.async {
                result.wrappedValue = height // !! must be called asynchronously
            }
        }
    }
    
    final class Coordinator: NSObject, UITextViewDelegate {
        var text: Binding<String>
        var calculatedHeight: Binding<CGFloat>
        var isEditing: Binding<Bool>
        
        let maxHeight: CGFloat
        
        init(text: Binding<String>, height: Binding<CGFloat>, isEditing: Binding<Bool>, maxHeight: CGFloat) {
            self.text = text
            calculatedHeight = height
            self.isEditing = isEditing
            self.maxHeight = maxHeight
        }
        
        func textViewDidChange(_ textView: UITextView) {
            text.wrappedValue = textView.text
            UITextViewWrapper.recalculateHeight(view: textView,
                                                result: calculatedHeight,
                                                maxHeight: maxHeight)
        }
        
        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            true
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            isEditing.wrappedValue = true
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            isEditing.wrappedValue = false
        }
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
        
        init(text: String) {
            _text = .init(initialValue: text)
        }
        
        var body: some View {
            MessageComposerTextField(placeholder: "Placeholder", text: $text, maxHeight: 300)
        }
    }
}
