//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

private nonisolated let escapedAnywhere: Set<Unicode.Scalar> = ["\\", "^", "`", ":", "{", "}", "\"", "'", "[", "]", "(", ")", "*"]
private nonisolated let escapedWhenLeading: Set<Unicode.Scalar> = ["-", "+", "/", ">", "<", "!", "~"]
private nonisolated let operatorWords: Set = ["AND", "OR", "NOT", "IN", "TO"]

nonisolated extension String {
    /// Escapes tantivy query syntax so what the user typed is searched as literal text, and
    /// prefixes every token containing a letter or digit with `+` (Must) so all words are
    /// required — the SDK's parser is OR-by-default and `set_conjunction_by_default` is not
    /// reachable over the FFI.
    ///
    /// Port of `TantivyQueryEscaper.kt` (element-x-android); pinned to the tantivy grammar
    /// shipped in matrix-rust-components-swift 26.07.15. The query is never logged.
    var escapedForTantivy: String {
        split(whereSeparator: \.isWhitespace)
            .map { token in
                let escaped = String(token).tantivyEscapedToken
                // tantivy's default tokenizer splits on non-alphanumerics, so a token like `:)`
                // indexes no terms at all. Required, such a token could only ever subtract.
                // Kotlin parity: `isLetterOrDigit` means letter or DECIMAL digit — Swift's
                // `Character.isNumber` is broader (fractions, Roman numerals) and would wrongly
                // promote such tokens to Must clauses.
                let hasLetterOrDigit = token.contains { character in
                    character.isLetter || character.unicodeScalars.contains { $0.properties.numericType == .decimal }
                }
                return hasLetterOrDigit ? "+\(escaped)" : escaped
            }
            .joined(separator: " ")
    }
    
    private var tantivyEscapedToken: String {
        var result = ""
        result.reserveCapacity(count + 8)
        
        if operatorWords.contains(self) {
            result.append("\\")
        }
        
        // One forward pass: chained replacingOccurrences calls would re-escape the backslashes
        // they just added. The `+` Must prefix is applied by the caller *after* escaping —
        // prefixing first would emit a literal `\+` that parses cleanly and silently restores
        // OR semantics.
        //
        // Escape at scalar granularity: tantivy's grammar is defined over scalars, so a special
        // character carrying a combining mark (one Swift Character, two scalars) is still that
        // special character to the parser and must still be escaped.
        for (index, scalar) in unicodeScalars.enumerated() {
            if escapedAnywhere.contains(scalar) || (index == 0 && escapedWhenLeading.contains(scalar)) {
                result.unicodeScalars.append("\\")
            }
            result.unicodeScalars.append(scalar)
        }
        
        return result
    }
}
