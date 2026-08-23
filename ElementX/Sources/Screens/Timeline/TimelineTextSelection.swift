//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import UniformTypeIdentifiers

/// "Select text" on a message: its bubble's text views select in place, all selected to start
/// with, with the system handles and edit menu (the views otherwise keep their selection cleared
/// so links and the long press work). Ends when the text view loses focus or another bubble is tapped.
struct TimelineTextSelectionInfo: Equatable {
    let itemID: TimelineItemIdentifier
    /// The message's body: the markdown-ish source for formatted messages, what a plain-text
    /// composer wants pasted.
    let text: String
    /// The message's formatted body, for a rich-text paste.
    let html: String?
    
    /// Puts the whole message on the pasteboard, plain and (when formatted) rich: a paste into a
    /// plain-text composer gets the markdown, one into a rich-text composer keeps the formatting.
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

extension EnvironmentValues {
    /// Set on a bubble's content while its text is being selected; nil otherwise.
    @Entry var timelineTextSelection: TimelineTextSelectionInfo?
}
