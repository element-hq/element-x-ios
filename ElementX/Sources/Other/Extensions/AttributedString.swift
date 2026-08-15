//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated extension AttributedString {
    /// faster than doing `String(characters)`: https://forums.swift.org/t/attributedstring-to-string/61667
    var string: String {
        String(characters[...])
    }
    
    var formattedComponents: [AttributedStringBuilderComponent] {
        var components = [AttributedStringBuilderComponent]()
        
        for run in runs[\.blockquote, \.codeBlock] {
            let isBlockquote = run.0 != nil
            let isCodeBlock = run.1 != nil
            var attributedString = AttributedString(self[run.2])
            
            // Remove trailing new lines if any
            if attributedString.characters.last?.isNewline ?? false,
               let range = attributedString.range(of: "\n", options: .backwards, locale: nil) {
                attributedString.removeSubrange(range)
            }
            
            let componentType: AttributedStringBuilderComponent.ComponentType = switch (isBlockquote, isCodeBlock) {
            case (true, _):
                .blockquote
            case (false, true):
                .codeBlock
            case (false, false):
                .plainText
            }
            
            components.append(AttributedStringBuilderComponent(id: String(attributedString.characters),
                                                               attributedString: attributedString,
                                                               type: componentType))
        }
        
        return components
    }
    
    /// Returns a new attributed string with leading and trailing whitespace and
    /// newlines removed, preserving the attributes (unlike rebuilding from the
    /// trimmed plain string).
    func trimmingWhitespaceAndNewlines() -> AttributedString {
        guard let start = characters.firstIndex(where: { !$0.isWhitespace }),
              let end = characters.lastIndex(where: { !$0.isWhitespace }) else {
            return AttributedString()
        }
        return AttributedString(self[start..<characters.index(after: end)])
    }

    /// Replaces the specified placeholder with the supplied attributed string.
    /// - Parameters:
    ///   - placeholder: The text in the string that will be replaced. Make sure this is unique within the string.
    ///   - attributedString: The text for the link that will be substituted into the placeholder.
    mutating func replace(_ placeholder: String, with replacement: AttributedString) {
        guard let range = range(of: placeholder) else {
            MXLog.failure("Failed to find the placeholder to be replaced.")
            return
        }
        
        // Replace the placeholder.
        replaceSubrange(range, with: replacement)
    }
    
    /// Returns a new attributed string, created by replacing any hard coded `UIFont` with
    /// a simple presentation intent. This allows simple formatting to respond to Dynamic Type.
    ///
    /// Supports bold, italic and monospaced (inline code) treatments.
    func replacingFontWithPresentationIntent() -> AttributedString {
        var newValue = self
        for run in newValue.runs {
            guard let font = run.uiKit.font else { continue }

            let traits = font.fontDescriptor.symbolicTraits
            var intent: InlinePresentationIntent = []
            if traits.contains(.traitBold) { intent.insert(.stronglyEmphasized) }
            if traits.contains(.traitItalic) { intent.insert(.emphasized) }
            if traits.contains(.traitMonoSpace) { intent.insert(.code) }

            newValue[run.range].inlinePresentationIntent = intent.isEmpty ? nil : intent
            newValue[run.range].uiKit.font = nil
        }
        return newValue
    }

    /// Returns a new attributed string suitable for a flattened, single-block preview
    /// (room list last messages, notifications, the pinned events banner).
    ///
    /// Block semantics don't survive flattening, so quoted lines keep a leading
    /// `> ` marker, and hard coded fonts are swapped for presentation intents so
    /// the text adopts the preview's own font instead of the timeline's.
    func flattenedForPreview() -> AttributedString {
        var newValue = AttributedString()

        for (blockquote, range) in runs[\.blockquote] {
            var piece = AttributedString(self[range])

            if blockquote != nil {
                // Mark every quoted line, not just the first one.
                var markerPositions = [piece.startIndex]
                var index = piece.characters.startIndex
                while index < piece.characters.endIndex {
                    let next = piece.characters.index(after: index)
                    if piece.characters[index].isNewline, next < piece.characters.endIndex {
                        markerPositions.append(next)
                    }
                    index = next
                }

                for position in markerPositions.reversed() {
                    piece.insert(AttributedString("> "), at: position)
                }

                // Quoted content must not run into whatever follows it.
                if piece.characters.last?.isNewline != true {
                    piece.append(AttributedString("\n"))
                }
            }

            newValue += piece
        }

        // Blocks separate with at most one line break in a flattened preview.
        while let range = newValue.range(of: "\n\n") {
            newValue.replaceSubrange(range, with: AttributedString("\n"))
        }

        var result = newValue.replacingFontWithPresentationIntent()

        // The parser applies UIKit line styles, which SwiftUI's Text ignores;
        // previews are rendered with Text so swap them for SwiftUI ones.
        for run in result.runs {
            if run.uiKit.strikethroughStyle != nil {
                result[run.range].uiKit.strikethroughStyle = nil
                result[run.range].swiftUI.strikethroughStyle = .single
            }
            if run.uiKit.underlineStyle != nil {
                result[run.range].uiKit.underlineStyle = nil
                result[run.range].swiftUI.underlineStyle = .single
            }
        }

        return result
    }
    
    /// Makes the entire string bold by setting the presentation intent to strongly emphasized.
    ///
    /// In practice, this is rendered as semibold for smaller font sizes and just so happens to nicely
    /// line up with the semibold → bold font switch used by compound.
    mutating func bold() {
        self[startIndex..<endIndex].inlinePresentationIntent = .stronglyEmphasized
    }
}
