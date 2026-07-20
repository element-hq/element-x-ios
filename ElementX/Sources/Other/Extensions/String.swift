//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import UniformTypeIdentifiers

nonisolated extension String {
    // periphery:ignore - might be useful to have
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

nonisolated extension String {
    func ellipsize(length: Int) -> String {
        guard count > length else {
            return self
        }
        return "\(prefix(length))…"
    }
}

nonisolated extension String {
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

nonisolated extension String {
    /// detects if the string is empty or contains only whitespaces and newlines
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

nonisolated extension String {
    static func makeCanonicalAlias(aliasLocalPart: Self?, serverName: Self?) -> Self? {
        guard let aliasLocalPart, !aliasLocalPart.isEmpty,
              let serverName, !serverName.isEmpty else {
            return nil
        }
        return "#\(aliasLocalPart):\(serverName)"
    }
}

nonisolated extension String {
    var validatedFileExtension: String {
        let fileExtension = (self as NSString).pathExtension
        guard !fileExtension.isEmpty else {
            return "bin"
        }
        return UTType(filenameExtension: fileExtension) != nil ? fileExtension : "bin"
    }
}

nonisolated extension String {
    /// Whether the first character with a strong BiDi direction is right-to-left.
    /// Mirrors the Unicode BiDi "first strong" rule used by TextKit to resolve
    /// paragraph direction when `baseWritingDirection` is `.natural`.
    var firstStrongCharacterIsRTL: Bool {
        for scalar in unicodeScalars {
            let value = scalar.value
            // Strong RTL: Hebrew, Arabic, Syriac, Thaana, NKo, Samaritan, Mandaic,
            // Arabic Extended, and their presentation forms.
            let isStrongRTL = (0x0590...0x08FF).contains(value) ||
                (0xFB1D...0xFDFF).contains(value) ||
                (0xFE70...0xFEFF).contains(value)
            if isStrongRTL {
                return true
            }
            if scalar.properties.isAlphabetic {
                return false
            }
        }
        return false
    }
}

nonisolated extension String {
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
