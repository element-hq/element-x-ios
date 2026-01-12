//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import UniformTypeIdentifiers

extension String {
    /// Returns the string as an `AttributedString` with the specified character tinted in a different color.
    /// - Parameters:
    ///   - character: The character to be tinted.
    ///   - color: The color to tint the character. Defaults to the accent color.
    /// - Returns: An `AttributedString`.
    func tinting(_ character: Character, color: Color = .accentColor) -> AttributedString {
        var string = AttributedString(self)
        let characterView = string.characters
        for index in characterView.indices where characterView[index] == character {
            string[index..<characterView.index(after: index)].foregroundColor = color
        }
        
        return string
    }
    
    var isASCII: Bool {
        allSatisfy(\.isASCII)
    }
    
    func asciified() -> String? {
        guard !isASCII else {
            return self
        }
        let mutableString = NSMutableString(string: self)
        guard CFStringTransform(mutableString, nil, "Any-Latin; Latin-ASCII; [:^ASCII:] Remove" as CFString, false) else {
            return nil
        }
        return mutableString.trimmingCharacters(in: .whitespaces)
    }
}

extension String {
    static func generateBreakableWhitespaceEnd(whitespaceCount: Int, layoutDirection: LayoutDirection) -> String {
        guard whitespaceCount > 0 else {
            return ""
        }

        var whiteSpaces = layoutDirection.isolateLayoutUnicodeString

        // fixed size whitespace of size 1/3 em per character
        whiteSpaces += String(repeating: "\u{2004}", count: whitespaceCount)

        // braille whitespace, which is non breakable but makes previous whitespaces breakable
        return whiteSpaces + "\u{2800}"
    }
}

extension String {
    func ellipsize(length: Int) -> String {
        guard count > length else {
            return self
        }
        return "\(prefix(length))…"
    }
}

extension String {
    func replacingHtmlBreaksOccurrences() -> String {
        var result = self
        let pattern = #"</p>(\n+)<p>"#
        
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return result
        }
        let matches = regex.matches(in: self, options: [], range: NSRange(location: 0, length: utf16.count))
        
        for match in matches.reversed() {
            guard let range = Range(match.range, in: self),
                  let innerMatchRange = Range(match.range(at: 1), in: self) else {
                continue
            }
            let numberOfBreaks = (self[innerMatchRange].components(separatedBy: "\n").count - 1)
            let replacement = "<br>" + String(repeating: "<br>", count: numberOfBreaks)
            result.replaceSubrange(range, with: replacement)
        }
        
        return result
    }
}

extension String {
    /// detects if the string is empty or contains only whitespaces and newlines
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension String {
    static func makeCanonicalAlias(aliasLocalPart: Self?, serverName: Self?) -> Self? {
        guard let aliasLocalPart, !aliasLocalPart.isEmpty,
              let serverName, !serverName.isEmpty else {
            return nil
        }
        return "#\(aliasLocalPart):\(serverName)"
    }
}

extension String {
    var validatedFileExtension: String {
        let fileExtension = (self as NSString).pathExtension
        guard !fileExtension.isEmpty else {
            return "bin"
        }
        return UTType(filenameExtension: fileExtension) != nil ? fileExtension : "bin"
    }
}

extension String {
    /// To be used if the string is actually a URL
    var asSanitizedLink: String {
        var link = self
        if !link.contains("://") {
            link.insert(contentsOf: "https://", at: link.startIndex)
        }
        
        // Don't include punctuation characters at the end of links but keep
        // closing brackets as per https://github.com/element-hq/element-x-ios/issues/4946
        // e.g `https://element.io/blog:` which is a valid link but the wrong place
        while !link.isEmpty,
              link.rangeOfCharacter(from: .punctuationWithoutClosingBracketCharacters, options: .backwards)?.upperBound == link.endIndex {
            link = String(link.dropLast())
        }
        
        return link
    }
}
