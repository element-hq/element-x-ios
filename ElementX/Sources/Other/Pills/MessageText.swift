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
    
    /// Set while the message is in "Select text": the selection is kept (not cleared by the
    /// delegate), the view is first responder with everything selected, and the text view's own
    /// long press (loupe, handles) is allowed.
    var activeTextSelection: TimelineTextSelectionInfo?
    var isSelectingText: Bool { activeTextSelection != nil }
    
    func beginTextSelection(_ selection: TimelineTextSelectionInfo) {
        activeTextSelection = selection
        // No dragging the selection out as a floating item (it got stuck on-screen).
        textDragInteraction?.isEnabled = false
        DispatchQueue.main.async { [weak self] in
            guard let self, isSelectingText else { return }
            becomeFirstResponder()
            selectAll(nil)
            // The edit menu (Copy…) straight away, over the selection, rather than after a tap on it.
            let rect = selectionRects(for: selectedTextRange ?? UITextRange()).map(\.rect).reduce(CGRect.null) { $0.union($1) }
            let point = rect.isNull ? CGPoint(x: bounds.midX, y: bounds.midY) : CGPoint(x: rect.midX, y: rect.minY)
            (interactions.first { $0 is UIEditMenuInteraction } as? UIEditMenuInteraction)?
                .presentEditMenu(with: UIEditMenuConfiguration(identifier: nil, sourcePoint: point))
        }
    }
    
    /// The message's text without the invisible spacer appended at the end for the timestamp
    /// overlay (a newline + transparent attachment), which selecting "all" would otherwise include
    /// as a blank trailing line.
    var contentRange: NSRange {
        let string = attributedText.string as NSString
        var length = string.length
        if length > 0, string.character(at: length - 1) == 0xFFFC { // Object replacement (the attachment).
            length -= 1
            if length > 0, string.character(at: length - 1) == 0x0A {
                length -= 1
            }
        }
        return NSRange(location: 0, length: length)
    }
    
    override func selectAll(_ sender: Any?) {
        selectedRange = contentRange
    }

    /// The geometry chokepoint the selection interaction drives handle drags through:
    /// a point over the spacer answers with the content's end, so dragging the trailing
    /// handle can't select the spacer (the setter/delegate clamps miss these drags, the
    /// interaction applies its own tracked range).
    override func closestPosition(to point: CGPoint) -> UITextPosition? {
        guard let closest = super.closestPosition(to: point) else { return nil }
        guard let contentEnd = position(from: beginningOfDocument, offset: contentRange.length),
              offset(from: contentEnd, to: closest) > 0 else {
            return closest
        }
        return contentEnd
    }

    /// Touches on the invisible timestamp spacer never belong to the text: outside
    /// "Select text" they fall through to the bubble, so the spacer behaves like bubble
    /// background (long press menu, double tap to react, scroll) instead of lifting
    /// drag previews or flashing selections.
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        guard !isSelectingText, !ProcessInfo.processInfo.isiOSAppOnMac else {
            return super.point(inside: point, with: event)
        }
        let content = contentRange
        let fullLength = (attributedText.string as NSString).length
        guard fullLength > content.length else {
            return super.point(inside: point, with: event)
        }
        let spacerRange = NSRange(location: content.length, length: fullLength - content.length)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: spacerRange, actualCharacterRange: nil)
        var rect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        rect.origin.x += textContainerInset.left
        rect.origin.y += textContainerInset.top
        if rect.contains(point) {
            return false
        }
        return super.point(inside: point, with: event)
    }
    
    /// The spacer is never selectable (and so never copyable): any selection - dragged
    /// handles included - is clamped to the real content. Both setters are overridden as
    /// interactive selection goes through `selectedTextRange` and programmatic mutations
    /// through `selectedRange`, and neither reliably funnels into the other.
    override var selectedRange: NSRange {
        get { super.selectedRange }
        set {
            let limit = contentRange.length
            let location = min(newValue.location, limit)
            super.selectedRange = NSRange(location: location, length: min(newValue.length, limit - location))
        }
    }
    
    override var selectedTextRange: UITextRange? {
        get { super.selectedTextRange }
        set {
            guard let newValue,
                  let contentEnd = position(from: beginningOfDocument, offset: contentRange.length),
                  offset(from: contentEnd, to: newValue.end) > 0 else {
                super.selectedTextRange = newValue
                return
            }
            let start = offset(from: newValue.start, to: contentEnd) > 0 ? newValue.start : contentEnd
            super.selectedTextRange = textRange(from: start, to: contentEnd) ?? newValue
        }
    }
    
    func endTextSelection() {
        guard isSelectingText else { return }
        activeTextSelection = nil
        selectedTextRange = nil
        if isFirstResponder {
            super.resignFirstResponder()
        }
    }
    
    /// Losing focus to something else (the composer, say) ends the selection.
    override func resignFirstResponder() -> Bool {
        let resigned = super.resignFirstResponder()
        if resigned, isSelectingText {
            activeTextSelection = nil
            selectedTextRange = nil
            timelineContext?.send(viewAction: .endTextSelection)
        }
        return resigned
    }
    
    /// Copying the whole text copies the message in both representations (see `TimelineTextSelectionInfo`).
    override func copy(_ sender: Any?) {
        if let activeTextSelection, selectedRange.location == 0, selectedRange.length >= contentRange.length {
            activeTextSelection.copyToPasteboard()
        } else {
            super.copy(sender)
        }
    }
    
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // We don't need to change the behaviour on MacOS
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            gestureRecognizer.delegate = self
        }
        super.addGestureRecognizer(gestureRecognizer)
    }
    
    /// Outside "Select text" the view never takes focus: the system's own double-tap word
    /// selection otherwise grabs first responder and leaves a stuck selection with drag
    /// handles (of the timestamp spacer, when the tap lands past the text).
    override var canBecomeFirstResponder: Bool {
        let can = isSelectingText || ProcessInfo.processInfo.isiOSAppOnMac
        if !can {
            MXLog.info("MessageTextView: refusing first responder outside text selection")
        }
        return can
    }
    
    /// This prevents the magnifying glass from showing up, and (while selecting) the long-press
    /// drag that lifts a floating copy of the text and never dismisses.
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
private final nonisolated class TransparentTextAttachment: NSTextAttachment {
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
    @Environment(\.timelineTextSelection) private var textSelection
    @Environment(\.layoutDirection) private var layoutDirection
    
    /// Cache key for `sizeThatFits`. Keyed on the reserved trailing size as well as the proposed
    /// width to account for any changes on the send info label that happen after the first rendering.
    private struct SizeCacheKey: Hashable {
        // periphery:ignore - used via the synthesized Hashable conformance
        let width: Double
        // periphery:ignore - used via the synthesized Hashable conformance
        let reservedSize: CGSize
    }
    
    @State private var computedSizes = [SizeCacheKey: CGSize]()
    
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
            
            // Inherit the font from the preceding character so the appended runs
            // (newline and attachment) carry the same line metrics as the surrounding
            // text — otherwise a small default font on those characters can shrink the
            // line height and clip e.g. a font-boosted lone emoji.
            let trailingFont = baseText.length > 0
                ? baseText.attribute(.font, at: baseText.length - 1, effectiveRange: nil)
                : nil
            
            // When the last paragraph's natural text direction doesn't match the layout
            // direction, the inline attachment would land on the wrong side and overlap the
            // overlaid timestamp. Force it onto its own line so the bubble just grows taller.
            if !lastParagraphDirectionMatchesLayout(in: combined) {
                let newlineString = NSMutableAttributedString(string: "\n")
                if let trailingFont {
                    newlineString.addAttribute(.font,
                                               value: trailingFont,
                                               range: NSRange(location: 0, length: newlineString.length))
                }
                combined.append(newlineString)
            }
            
            let attachmentString = NSMutableAttributedString(attachment: attachment)
            if let trailingFont {
                attachmentString.addAttribute(.font,
                                              value: trailingFont,
                                              range: NSRange(location: 0, length: attachmentString.length))
            }
            combined.append(attachmentString)
        }
        
        return combined
    }
    
    private func lastParagraphDirectionMatchesLayout(in attributedText: NSAttributedString) -> Bool {
        let string = attributedText.string as NSString
        guard string.length > 0 else { return true }
        
        // Isolate the last paragraph because its direction is what decides
        // which side the trailing attachment ends up on.
        let lastParagraphRange = string.paragraphRange(for: NSRange(location: string.length - 1, length: 0))
        let lastParagraph = string.substring(with: lastParagraphRange)
        
        let textIsRTL = lastParagraph.firstStrongCharacterIsRTL
        let layoutIsRTL = layoutDirection == .rightToLeft
        return textIsRTL == layoutIsRTL
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
        // Otherwise items dropped onto a bubble land on the text view instead of
        // bubbling up to the timeline's drop handler.
        if let textDropInteraction = textView.textDropInteraction {
            textView.removeInteraction(textDropInteraction)
        }
        
        // The selection handles' knobs extend beyond the zero-inset bounds and get
        // clipped (until a drag re-hosts them in an unclipped container): don't clip.
        textView.clipsToBounds = false
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
            // Setting new text can rebuild the interaction stack: keep drag lifts dead.
            uiView.textDragInteraction?.isEnabled = false
        }
        context.coordinator.openURLAction = openURLAction
        
        if let textSelection, !uiView.isSelectingText {
            uiView.beginTextSelection(textSelection)
        } else if textSelection == nil, uiView.isSelectingText {
            uiView.endTextSelection()
        }
    }
    
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MessageTextView, context: Context) -> CGSize? {
        let proposalWidth = proposal.width ?? UIView.layoutFittingExpandedSize.width
        let key = SizeCacheKey(width: proposalWidth, reservedSize: trailingReservedSize)
        
        if let size = computedSizes[key] {
            return size
        }
        
        let size = uiView.sizeThatFits(CGSize(width: proposalWidth, height: UIView.layoutFittingCompressedSize.height))
        DispatchQueue.main.async {
            computedSizes[key] = size
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
            MXLog.info("MessageTextView: selection changed to \(textView.selectedRange), selecting=\((textView as? MessageTextView)?.isSelectingText == true)")
            if let messageTextView = textView as? MessageTextView, messageTextView.isSelectingText {
                // Dragged selection handles set the selection through the text-interaction
                // controller, not the public setters: clamp here too so the spacer can't be
                // selected. Reassigning routes through the clamping setter (and no-ops the
                // re-entrant delegate call once in bounds).
                if NSMaxRange(textView.selectedRange) > messageTextView.contentRange.length {
                    messageTextView.selectedRange = textView.selectedRange
                }
                return
            }
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
