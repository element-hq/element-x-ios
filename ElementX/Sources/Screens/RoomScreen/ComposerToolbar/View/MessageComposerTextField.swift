//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MessageComposerTextField: View {
    let placeholder: String
    @Binding var text: NSAttributedString
    @Binding var presendCallback: (() -> Void)?
    @Binding var selectedRange: NSRange
    
    let maxHeight: CGFloat
    let keyHandler: GenericKeyHandler
    let pasteHandler: PasteHandler
    
    var body: some View {
        UITextViewWrapper(text: $text,
                          presendCallback: $presendCallback,
                          selectedRange: $selectedRange,
                          maxHeight: maxHeight,
                          keyHandler: keyHandler,
                          pasteHandler: pasteHandler)
            .accessibilityLabel(placeholder)
            .background(placeholderView, alignment: .topLeading)
            .background { keyboardShortcuts }
    }
    
    @ViewBuilder
    private var placeholderView: some View {
        if text.string.isEmpty {
            Text(placeholder)
                .font(Font(UIFont.preferredFont(forTextStyle: .body)))
                .foregroundColor(.compound.textSecondary)
                .accessibilityHidden(true)
        }
    }
    
    private var keyboardShortcuts: some View {
        Button("") {
            keyHandler(.keyboardEscape)
        }
        // Need this to enable escape on the textView and forward the presses
        .keyboardShortcut(.escape, modifiers: [])
    }
}

private struct UITextViewWrapper: UIViewRepresentable {
    @Environment(\.timelineContext) private var timelineContext
    
    @Binding var text: NSAttributedString
    @Binding var presendCallback: (() -> Void)?
    @Binding var selectedRange: NSRange
    
    let maxHeight: CGFloat
    
    let keyHandler: GenericKeyHandler
    let pasteHandler: PasteHandler
    
    private let font = UIFont.preferredFont(forTextStyle: .body)
    
    func makeUIView(context: UIViewRepresentableContext<UITextViewWrapper>) -> UITextView {
        // Need to use TextKit 1 for mentions
        let textView = ElementTextView(timelineContext: timelineContext,
                                       presendCallback: $presendCallback)

        textView.maxFittingHeight = maxHeight
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
        
        // AutoCorrection doesn't work properly when running on the Mac
        // https://github.com/element-hq/element-x-ios/issues/1786
        if ProcessInfo.processInfo.isiOSAppOnMac {
            textView.autocorrectionType = .no
        }
        
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        return textView
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        if let width = proposal.width, width == 0 || width == .infinity {
            // Stacks probe with 0 and infinity to learn the flexibility; only the width
            // is used from those answers, so don't re-measure the text for them.
            return CGSize(width: width, height: context.coordinator.lastFittedHeight ?? min(maxHeight, uiView.bounds.height))
        }
        
        if let width = proposal.width, abs(width - uiView.bounds.width) < 0.5 {
            // Same width as laid out: use UIKit's own content size and don't touch the layout.
            // Re-measuring with `uiView.sizeThatFits` resizes the text container, which
            // momentarily shrinks `contentSize` and clamps `contentOffset`, and forcing the
            // layout manager here moves UIKit's content-size update ahead of its caret update;
            // either way the caret was drawn on the wrong line for a few frames per keystroke
            // in a scrolled composer. A programmatic text set lays out in `updateUIView`.
            let height = min(maxHeight, ceil(uiView.contentSize.height))
            context.coordinator.lastFittedHeight = height
            return CGSize(width: width, height: height)
        }
        
        // Note: Coalescing a width of zero here returns a size for the view with 1 line of text visible.
        let newSize = uiView.sizeThatFits(CGSize(width: proposal.width ?? .zero, height: maxHeight))
        let width = proposal.width ?? newSize.width
        let height = min(maxHeight, newSize.height)
        context.coordinator.lastFittedHeight = height
        
        return CGSize(width: width, height: height)
    }
    
    func updateUIView(_ textView: UITextView, context: UIViewRepresentableContext<UITextViewWrapper>) {
        // Prevent the textView from inheriting attributes from mention pills
        textView.typingAttributes = [.font: font,
                                     .foregroundColor: UIColor.compound.textPrimary]
        
        if textView.attributedText != text {
            // Remember the selection if only the attributes have changed.
            let selection = textView.attributedText.string == text.string ? textView.selectedTextRange : nil
            
            // Fixes pill views not loading on the first attempt on iOS 18
            // because the textContainers's superview comes in as nil
            // https://github.com/element-hq/element-x-ios/issues/3369
            _ = textView.layoutManager
            
            let attributesOnly = textView.attributedText.string == text.string
            MXLog.info("CARETPROBE updateUIView re-applies attributedText (\(attributesOnly ? "attributes only" : "string differs")) off \(textView.contentOffset.y) sel \(textView.selectedRange.location) len \(text.length)")
            
            textView.attributedText = text
            
            // Re-apply the default font when setting text for e.g. edits.
            textView.font = font
            textView.textColor = .compound.textPrimary
            
            // Lay the new text out now so `sizeThatFits` sees the right content size.
            textView.layoutIfNeeded()
            
            if text.string.isEmpty {
                // text cleared, probably because the written text is sent
                // reload keyboard type
                if textView.isFirstResponder {
                    textView.keyboardType = .twitter
                    textView.reloadInputViews()
                    textView.keyboardType = .default
                    textView.reloadInputViews()
                }
            } else if let selection {
                // Fixes a bug where pressing Return in the middle of two paragraphs
                // moves the caret back to the bottom of the composer.
                // https://github.com/element-hq/element-x-ios/issues/3104
                textView.selectedTextRange = selection
            } else {
                // Re-setting the selected range is important when inserting pills
                // but we need to not do that when entering edit mode, where the
                // cursor needs to stay at the end of the text
                // https://github.com/element-hq/element-x-ios/issues/3830
                if textView.selectedRange.location != text.length {
                    textView.selectedRange = selectedRange
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text,
                    selectedRange: $selectedRange,
                    maxHeight: maxHeight,
                    keyHandler: keyHandler,
                    pasteHandler: pasteHandler)
    }
    
    final class Coordinator: NSObject, UITextViewDelegate, ElementTextViewDelegate {
        private var text: Binding<NSAttributedString>
        private var selectedRange: Binding<NSRange>
        
        /// The height last returned by `sizeThatFits`, reused for the stacks' width probes.
        var lastFittedHeight: CGFloat?
        private let maxHeight: CGFloat
        
        private let keyHandler: GenericKeyHandler
        private let pasteHandler: PasteHandler
        
        init(text: Binding<NSAttributedString>,
             selectedRange: Binding<NSRange>,
             maxHeight: CGFloat,
             keyHandler: @escaping GenericKeyHandler,
             pasteHandler: @escaping PasteHandler) {
            self.text = text
            self.selectedRange = selectedRange
            self.maxHeight = maxHeight
            self.keyHandler = keyHandler
            self.pasteHandler = pasteHandler
        }
        
        func textViewDidChange(_ textView: UITextView) {
            // Animated while the field can still grow or shrink, so a line appearing or
            // going tweens the layout (the timeline rides along smoothly) instead of popping.
            // At the height cap nothing moves, and the scrolled text view is where animated
            // transactions have interfered with caret placement, so update plainly there.
            if textView.bounds.height < maxHeight - 0.5 {
                withAnimation(.easeOut(duration: 0.1)) {
                    text.wrappedValue = textView.attributedText
                }
            } else {
                text.wrappedValue = textView.attributedText
            }
        }
        
        func textViewDidReceiveKeyPress(_ textView: UITextView, key: UIKeyboardHIDUsage) {
            keyHandler(key)
        }
        
        func textViewDidReceiveShiftEnterKeyPress(_ textView: UITextView) {
            textView.insertText("\n")
        }
        
        func textView(_ textView: UITextView, didReceivePasteWith providers: [NSItemProvider]) {
            pasteHandler(providers)
        }
        
        func textViewDidChangeSelection(_ textView: UITextView) {
            DispatchQueue.main.async {
                if self.selectedRange.wrappedValue != textView.selectedRange {
                    self.selectedRange.wrappedValue = textView.selectedRange
                }
            }
        }
    }
}

private protocol ElementTextViewDelegate: AnyObject {
    func textViewDidReceiveShiftEnterKeyPress(_ textView: UITextView)
    func textViewDidReceiveKeyPress(_ textView: UITextView, key: UIKeyboardHIDUsage)
    func textView(_ textView: UITextView, didReceivePasteWith providers: [NSItemProvider])
}

private class ElementTextView: UITextView, PillAttachmentViewProviderDelegate {
    private(set) var timelineContext: TimelineViewModel.Context?
    private var pillViews = NSHashTable<UIView>.weakObjects()

    weak var elementDelegate: ElementTextViewDelegate?

    /// The height the wrapper grows the view to before it starts scrolling.
    var maxFittingHeight: CGFloat = .greatestFiniteMagnitude

    /// While the composer's height tween runs, the bounds briefly lag the content
    /// and the caret auto-scroll kicks in, making the text jump ahead of the
    /// animating field. Whenever the content fully fits under ``maxFittingHeight``
    /// the correct offset is always zero, so drop those scrolls; real scrolling
    /// (content taller than the height cap, or the user dragging) is untouched.
    override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
        if !isTracking, !isDecelerating, contentSize.height <= maxFittingHeight {
            if contentOffset != .zero {
                MXLog.info("CARETPROBE setContentOffset \(contentOffset) forced zero (content \(contentSize.height) <= \(maxFittingHeight))")
            }
            super.setContentOffset(.zero, animated: false)
            return
        }
        if contentOffset != self.contentOffset {
            MXLog.info("CARETPROBE setContentOffset \(contentOffset) animated \(animated) (content \(contentSize.height) bounds \(bounds.height))")
        }
        super.setContentOffset(contentOffset, animated: animated)
    }
    
    // MARK: - Caret probe (temporary, round 39): logs caretRect vs the cursor view per frame while editing.
    
    private var caretProbe: CADisplayLink?
    private var lastCaretProbe = ""
    private var caretProbeTicks = 0
    private var caretProbeMismatchTicks = 0
    
    override func becomeFirstResponder() -> Bool {
        let became = super.becomeFirstResponder()
        if became, caretProbe == nil {
            caretProbe = CADisplayLink(target: self, selector: #selector(caretProbeTick))
            caretProbe?.add(to: .main, forMode: .common)
        }
        return became
    }
    
    override func resignFirstResponder() -> Bool {
        caretProbe?.invalidate()
        caretProbe = nil
        return super.resignFirstResponder()
    }
    
    @objc private func caretProbeTick() {
        guard let window, let end = selectedTextRange?.end else { return }
        caretProbeTicks += 1
        let caret = convert(caretRect(for: end), to: window)
        var cursor = "none"
        var mismatch = false
        if let cursorView = subviews.first(where: { NSStringFromClass(type(of: $0)) == "UIStandardTextCursorView" }) {
            let frame = convert((cursorView.layer.presentation() ?? cursorView.layer).frame, to: window)
            cursor = String(format: "%.1f,%.1f h%.1f", frame.minX, frame.minY, frame.height)
            mismatch = abs(frame.minY - caret.minY) > 1 || abs(frame.minX - caret.minX) > 2
        }
        caretProbeMismatchTicks = mismatch ? caretProbeMismatchTicks + 1 : 0
        let line = String(format: "caret %.1f,%.1f h%.1f | cursor %@ | off %.1f bounds %.1f content %.1f len %d",
                          caret.minX, caret.minY, caret.height, cursor, contentOffset.y, bounds.height, contentSize.height, attributedText.length)
        // Log on change, and every tick while the cursor disagrees with the caret (capped) so durations are visible.
        if line != lastCaretProbe || (mismatch && caretProbeMismatchTicks <= 12) {
            lastCaretProbe = line
            MXLog.info("CARETPROBE t\(caretProbeTicks) \(mismatch ? "MISMATCH\(caretProbeMismatchTicks) " : "")\(line)")
        }
    }
    
    init(timelineContext: TimelineViewModel.Context?,
         presendCallback: Binding<(() -> Void)?>) {
        self.timelineContext = timelineContext
        
        super.init(frame: .zero, textContainer: nil)
        
        // Avoid `Publishing changes from within view update` warnings
        DispatchQueue.main.async {
            presendCallback.wrappedValue = { [weak self] in
                self?.acceptCurrentSuggestion()
            }
        }
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override var keyCommands: [UIKeyCommand]? {
        [UIKeyCommand(input: "\r", modifierFlags: .shift, action: #selector(shiftEnterKeyPressed)),
         UIKeyCommand(input: "\r", modifierFlags: [], action: #selector(enterKeyPressed))]
    }
    
    // periphery:ignore:parameters sender - required for objc selector
    @objc func shiftEnterKeyPressed(sender: UIKeyCommand) {
        elementDelegate?.textViewDidReceiveShiftEnterKeyPress(self)
    }
    
    // periphery:ignore:parameters sender - required for objc selector
    @objc func enterKeyPressed(sender: UIKeyCommand) {
        elementDelegate?.textViewDidReceiveKeyPress(self, key: .keyboardReturnOrEnter)
    }
    
    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        guard let key = presses.first?.key else {
            super.pressesBegan(presses, with: event)
            return
        }
        
        if key.keyCode == .keyboardUpArrow, selectedRange.location == 0 {
            elementDelegate?.textViewDidReceiveKeyPress(self, key: key.keyCode)
            return
        }
        
        if key.keyCode == .keyboardEscape {
            elementDelegate?.textViewDidReceiveKeyPress(self, key: key.keyCode)
            return
        }
        
        super.pressesBegan(presses, with: event)
    }
    
    // Pasting support
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if super.canPerformAction(action, withSender: sender) {
            return true
        }
        
        guard action == #selector(paste(_:)) else {
            return false
        }
        
        return !UIPasteboard.general.itemProviders.contains { !$0.isSupportedForPasteOrDrop }
    }
    
    override func paste(_ sender: Any?) {
        // When pasting a link over a selection, wrap the selection in a markdown link.
        if selectedRange.length > 0, let link = UIPasteboard.general.pastedLink {
            let selectedText = (attributedText.string as NSString).substring(with: selectedRange)
            insertText("[\(selectedText)](\(link))")
            return
        }
        
        let providers = UIPasteboard.general.itemProviders
        
        // Use the default behavior if there are any unsupported providers
        guard !providers.contains(where: { !$0.isSupportedForPasteOrDrop }) else {
            super.paste(sender)
            return
        }
        
        elementDelegate?.textView(self, didReceivePasteWith: providers)
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
    
    // MARK: - Private
    
    private func acceptCurrentSuggestion() {
        guard isFirstResponder else {
            return
        }
        
        inputDelegate?.selectionWillChange(self)
        inputDelegate?.selectionDidChange(self)
    }
}

private extension UIPasteboard {
    /// The pasteboard's string contents when they consist of a single link and nothing else.
    var pastedLink: String? {
        guard let string = string?.trimmingCharacters(in: .whitespacesAndNewlines), !string.isEmpty,
              let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else {
            return nil
        }
        
        let range = NSRange(string.startIndex..., in: string)
        let matches = detector.matches(in: string, range: range)
        
        guard matches.count == 1, matches[0].range == range else {
            return nil
        }
        
        return string
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
        
        init(text: String) {
            self.text = .init(string: text, attributes: [.font: UIFont.preferredFont(forTextStyle: .body),
                                                         .foregroundColor: UIColor.compound.textPrimary])
        }
        
        var body: some View {
            MessageComposerTextField(placeholder: "Placeholder",
                                     text: $text,
                                     presendCallback: .constant(nil),
                                     selectedRange: .constant(NSRange(location: 0, length: 0)),
                                     maxHeight: 300,
                                     keyHandler: { _ in },
                                     pasteHandler: { _ in })
        }
    }
}
