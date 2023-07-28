//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

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

    /// Calculates a numeric hash same as Element Web
    /// See original function here https://github.com/matrix-org/matrix-react-sdk/blob/321dd49db4fbe360fc2ff109ac117305c955b061/src/utils/FormattingUtils.js#L47
    var hashCode: Int32 {
        var hash: Int32 = 0

        for character in self {
            let shiftedHash = hash << 5
            hash = shiftedHash.subtractingReportingOverflow(hash).partialValue + Int32(character.unicodeScalars[character.unicodeScalars.startIndex].value)
        }
        return abs(hash)
    }
    
    var isASCII: Bool {
        allSatisfy(\.isASCII)
    }
    
    func asciified() -> String? {
        guard !isASCII else {
            return self
        }
        guard !canBeConverted(to: .ascii) else {
            return nil
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
