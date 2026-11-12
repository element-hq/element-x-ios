//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// An inline custom emoticon (`<img data-mx-emoticon>`), drawn as a square image the height of the surrounding text.
/// The view is provided by ``EmoticonAttachmentViewProvider``, registered for `InfoPlistReader.emoticonsUTType` on launch.
final nonisolated class EmoticonTextAttachment: NSTextAttachment {
    private(set) var url: URL!
    private var descender: CGFloat = 0
    private var lineHeight: CGFloat = 0
    
    /// - Parameter fallbackText: The emoticon's alt text (e.g. `:wave:`), read out by VoiceOver.
    convenience init(url: URL, fallbackText: String, font: UIFont) {
        // The type must be declared in the Info.plist, UIKit drops undeclared ones and the view provider is never used.
        self.init(data: Data(url.absoluteString.utf8), ofType: InfoPlistReader.main.emoticonsUTType)
        self.url = url
        accessibilityLabel = fallbackText
        descender = font.descender
        lineHeight = font.lineHeight
    }
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        CGRect(x: 0, y: descender, width: lineHeight, height: lineHeight)
    }
}
