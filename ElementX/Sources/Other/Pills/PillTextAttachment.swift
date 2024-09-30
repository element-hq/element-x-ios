//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit

/// Text attachment for pills display.
final class PillTextAttachment: NSTextAttachment {
    convenience init?(attachmentData: PillTextAttachmentData) {
        let encoder = JSONEncoder()
        guard let encodedData = try? encoder.encode(attachmentData) else { return nil }
        self.init(data: encodedData, ofType: InfoPlistReader.main.pillsUTType)
        pillData = attachmentData
    }
    
    private(set) var pillData: PillTextAttachmentData!
    
    override func attachmentBounds(for textContainer: NSTextContainer?, proposedLineFragment lineFrag: CGRect, glyphPosition position: CGPoint, characterIndex charIndex: Int) -> CGRect {
        var rect = super.attachmentBounds(for: textContainer, proposedLineFragment: lineFrag, glyphPosition: position, characterIndex: charIndex)
        
        let fontData = pillData.fontData
        // Align the pill text vertically with the surrounding text.
        rect.origin.y = fontData.descender + (fontData.lineHeight - rect.height) / 2.0
        rect.size.width = min(rect.size.width, lineFrag.width)
        return rect
    }
}
