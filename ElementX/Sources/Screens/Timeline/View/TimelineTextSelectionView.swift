//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import UniformTypeIdentifiers

/// A message's text with the system selection controls (the bubble's own text view keeps its
/// selection cleared so links and the long press work), all of it selected to start with.
///
/// Copying the whole message puts both representations on the pasteboard: the body (markdown
/// for a formatted message) as plain text, and the formatted body as HTML and RTF, so a paste
/// into a plain-text composer gets the markdown and one into a rich-text composer keeps the
/// formatting. A partial selection copies its plain text.
struct TimelineTextSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    
    let info: TimelineTextSelectionInfo
    
    var body: some View {
        ElementNavigationStack {
            SelectableTextView(info: info)
                .padding(.horizontal, 16)
                .background(.compound.bgCanvasDefault)
                .navigationBarTitleDisplayMode(.inline)
                .navigationTitle(UntranslatedL10n.actionSelectText)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.actionDone) { dismiss() }
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button(L10n.actionCopy) { info.copyToPasteboard() }
                    }
                }
        }
        .presentationDetents([.medium, .large])
    }
}

extension TimelineTextSelectionInfo {
    /// Puts the whole message on the pasteboard, plain and (when formatted) rich.
    func copyToPasteboard() {
        var item: [String: Any] = [UTType.plainText.identifier: text]
        if let html {
            item[UTType.html.identifier] = html
            if let data = html.data(using: .utf8),
               let attributed = try? NSAttributedString(data: data,
                                                        options: [.documentType: NSAttributedString.DocumentType.html,
                                                                  .characterEncoding: String.Encoding.utf8.rawValue],
                                                        documentAttributes: nil),
               let rtf = try? attributed.data(from: NSRange(location: 0, length: attributed.length),
                                              documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]) {
                item[UTType.rtf.identifier] = rtf
            }
        }
        UIPasteboard.general.items = [item]
    }
}

private struct SelectableTextView: UIViewRepresentable {
    let info: TimelineTextSelectionInfo
    
    func makeUIView(context: Context) -> MessageSelectionTextView {
        let textView = MessageSelectionTextView()
        textView.info = info
        textView.isEditable = false
        textView.isSelectable = true
        textView.text = info.text
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textColor = .compound.textPrimary
        textView.backgroundColor = .clear
        textView.textContainerInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        textView.textContainer.lineFragmentPadding = 0
        textView.dataDetectorTypes = [.link, .phoneNumber]
        // Everything selected, with the handles and edit menu up, so Copy is one tap away and
        // narrowing the selection is a drag away.
        DispatchQueue.main.async {
            textView.becomeFirstResponder()
            textView.selectAll(nil)
        }
        return textView
    }
    
    func updateUIView(_ textView: MessageSelectionTextView, context: Context) {
        textView.info = info
        if textView.text != info.text {
            textView.text = info.text
        }
    }
}

/// Copying the whole text from the selection menu copies both representations too.
private final class MessageSelectionTextView: UITextView {
    var info: TimelineTextSelectionInfo?
    
    override func copy(_ sender: Any?) {
        if let info, selectedRange.location == 0, selectedRange.length == (text as NSString).length {
            info.copyToPasteboard()
        } else {
            super.copy(sender)
        }
    }
}

struct TimelineTextSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        TimelineTextSelectionView(info: .init(text: "Some **text** to select, copy or look up.", html: "Some <b>text</b> to select, copy or look up."))
    }
}
