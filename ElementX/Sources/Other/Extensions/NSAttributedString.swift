//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

nonisolated extension NSAttributedString {
    /// A copy of the string with ``NSMutableAttributedString/applyParagraphWritingDirections()`` applied.
    func applyingParagraphWritingDirections() -> NSAttributedString {
        let attributedString = NSMutableAttributedString(attributedString: self)
        attributedString.applyParagraphWritingDirections()
        return attributedString
    }
}

nonisolated extension NSMutableAttributedString {
    /// Gives each paragraph the direction of its first strong character. Otherwise TextKit aligns every
    /// paragraph using the app's language, leaving e.g. Persian text left aligned when the app is in English.
    /// Paragraphs without a strong character (only emojis, digits etc.) follow the paragraph before them.
    func applyParagraphWritingDirections() {
        var paragraphDirections = [(range: NSRange, direction: NSWritingDirection)]()
        // Leading paragraphs without a strong character follow the first one that has.
        var previousDirection = string.firstStrongCharacterDirection
        
        (string as NSString).enumerateSubstrings(in: NSRange(location: 0, length: length), options: .byParagraphs) { paragraph, _, enclosingRange, _ in
            guard let direction = paragraph?.firstStrongCharacterDirection ?? previousDirection else {
                return
            }
            paragraphDirections.append((enclosingRange, direction))
            previousDirection = direction
        }
        
        beginEditing()
        for (paragraphRange, direction) in paragraphDirections {
            // Copy any existing styles (e.g. list indentation) rather than replacing them.
            enumerateAttribute(.paragraphStyle, in: paragraphRange) { value, range, _ in
                let paragraphStyle = (value as? NSParagraphStyle)?.mutableCopy() as? NSMutableParagraphStyle ?? NSMutableParagraphStyle()
                paragraphStyle.baseWritingDirection = direction
                addAttribute(.paragraphStyle, value: paragraphStyle, range: range)
            }
        }
        endEditing()
    }
}
