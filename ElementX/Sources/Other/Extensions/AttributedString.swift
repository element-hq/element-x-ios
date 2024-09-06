//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension AttributedString {
    // faster than doing `String(characters)`: https://forums.swift.org/t/attributedstring-to-string/61667
    var string: String {
        String(characters[...])
    }
    
    var formattedComponents: [AttributedStringBuilderComponent] {
        runs[\.blockquote].map { value, range in
            var attributedString = AttributedString(self[range])
            
            // Remove trailing new lines if any
            if attributedString.characters.last?.isNewline ?? false,
               let range = attributedString.range(of: "\n", options: .backwards, locale: nil) {
                attributedString.removeSubrange(range)
            }
            
            let isBlockquote = value != nil
            
            return AttributedStringBuilderComponent(id: String(attributedString.characters), attributedString: attributedString, isBlockquote: isBlockquote)
        }
    }
    
    /// Replaces the specified placeholder with a string that links to the specified URL.
    /// - Parameters:
    ///   - linkPlaceholder: The text in the string that will be replaced. Make sure this is unique within the string.
    ///   - string: The text for the link that will be substituted into the placeholder.
    ///   - url: The URL that the link should open.
    mutating func replace(_ linkPlaceholder: String, with string: String, asLinkTo url: URL) {
        // Replace the placeholder with a link.
        var replacement = AttributedString(string)
        replacement.link = url
        replace(linkPlaceholder, with: replacement)
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
    /// Currently only supports regular and bold weights.
    func replacingFontWithPresentationIntent() -> AttributedString {
        var newValue = self
        for run in newValue.runs {
            guard let font = run.uiKit.font else { continue }
            newValue[run.range].inlinePresentationIntent = font.fontDescriptor.symbolicTraits.contains(.traitBold) ? .stronglyEmphasized : nil
            newValue[run.range].uiKit.font = nil
        }
        return newValue
    }
    
    /// Makes the entire string bold by setting the presentation intent to strongly emphasized.
    ///
    /// In practice, this is rendered as semibold for smaller font sizes and just so happens to nicely
    /// line up with the semibold → bold font switch used by compound.
    mutating func bold() {
        self[startIndex..<endIndex].inlinePresentationIntent = .stronglyEmphasized
    }
}
