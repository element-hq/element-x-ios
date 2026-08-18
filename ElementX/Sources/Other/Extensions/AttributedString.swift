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
    
    /// The string separated into a tree of block components: quotes contain
    /// their nested quotes and code blocks as children, so `> \u{60}\u{60}\u{60}code` and
    /// nested quotes render with their real structure.
    var formattedComponents: [AttributedStringBuilderComponent] {
        struct OpenQuote {
            var children = [AttributedStringBuilderComponent]()
            var content = AttributedString()
            var listIndent = 0
        }
        
        var rootComponents = [AttributedStringBuilderComponent]()
        var openQuotes = [OpenQuote]()
        
        func trimmingTrailingNewline(_ string: AttributedString) -> AttributedString {
            var string = string
            if string.characters.last?.isNewline ?? false,
               let range = string.range(of: "\n", options: .backwards, locale: nil) {
                string.removeSubrange(range)
            }
            return string
        }
        
        // Prefix ids with the position: two components with the same text (e.g.
        // a quote of "test" answered with "test") must not share an identity,
        // or the ForEach rendering them falls apart.
        func append(_ attributedString: AttributedString, kind: AttributedStringBuilderComponent.Kind, listIndent: Int) {
            let index = openQuotes.last.map(\.children.count) ?? rootComponents.count
            let component = AttributedStringBuilderComponent(id: "\(index)-\(String(attributedString.characters))",
                                                             attributedString: attributedString,
                                                             kind: kind,
                                                             listIndent: listIndent)
            if openQuotes.isEmpty {
                rootComponents.append(component)
            } else {
                openQuotes[openQuotes.count - 1].children.append(component)
            }
        }
        
        func closeQuote() {
            let quote = openQuotes.removeLast()
            append(trimmingTrailingNewline(quote.content), kind: .blockquote(children: quote.children), listIndent: quote.listIndent)
        }
        
        for run in runs[\.blockquote, \.codeBlock, \.listIndent] {
            let depth = run.0 ?? 0
            let isCodeBlock = run.1 != nil
            let listIndent = run.2 ?? 0
            let slice = AttributedString(self[run.3])
            
            while openQuotes.count > depth { closeQuote() }
            while openQuotes.count < depth { openQuotes.append(OpenQuote(listIndent: listIndent)) }
            
            for index in openQuotes.indices {
                openQuotes[index].content += slice
            }
            
            let leaf = trimmingTrailingNewline(slice)
            // Inter-block separators reduce to nothing; they only exist to keep
            // adjacent blocks' runs from coalescing.
            guard !leaf.characters.isEmpty else { continue }
            
            append(leaf, kind: isCodeBlock ? .codeBlock : .text, listIndent: listIndent)
        }
        
        while !openQuotes.isEmpty { closeQuote() }
        
        return rootComponents
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

            if let depth = blockquote {
                // Mark every quoted line, not just the first one, repeating the
                // marker to preserve the nesting depth.
                var markerPositions = [piece.startIndex]
                var index = piece.characters.startIndex
                while index < piece.characters.endIndex {
                    let next = piece.characters.index(after: index)
                    if piece.characters[index].isNewline, next < piece.characters.endIndex {
                        markerPositions.append(next)
                    }
                    index = next
                }

                let marker = AttributedString(String(repeating: "> ", count: depth))
                for position in markerPositions.reversed() {
                    piece.insert(marker, at: position)
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
            // Sub/superscripts keep their baseline offset but lost the parser's
            // shrunken font with the intent swap above; give them a small one back.
            if run.uiKit.baselineOffset != nil {
                result[run.range].swiftUI.font = .caption
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
