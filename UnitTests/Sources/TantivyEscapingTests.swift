//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct TantivyEscapingTests {
    @Test func everyWordBecomesAMustClause() {
        #expect("hello world".escapedForTantivy == "+hello +world")
    }
    
    @Test func operatorWordsAreNeutralised() {
        #expect("cats AND dogs".escapedForTantivy == "+cats +\\AND +dogs")
        #expect("TO".escapedForTantivy == "+\\TO")
        // Lowercase operators are not operators.
        #expect("and".escapedForTantivy == "+and")
    }
    
    @Test func charactersEscapedAnywhere() {
        #expect("a:b".escapedForTantivy == "+a\\:b")
        #expect("foo*".escapedForTantivy == "+foo\\*")
        #expect("(a)".escapedForTantivy == "+\\(a\\)")
        #expect("say \"hi\"".escapedForTantivy == "+say +\\\"hi\\\"")
    }
    
    @Test func charactersEscapedOnlyWhenLeading() {
        #expect("-exclude".escapedForTantivy == "+\\-exclude")
        #expect("~fuzzy".escapedForTantivy == "+\\~fuzzy")
        // Mid-word occurrences survive untouched: real-world tokens must not be mangled.
        #expect("C++".escapedForTantivy == "+C++")
        #expect("1/2/2024".escapedForTantivy == "+1/2/2024")
    }
    
    @Test func typedBackslashesAreDoubled() {
        // A backslash the user typed cannot be allowed to escape one of ours. This is NOT
        // idempotence: the single forward pass only guarantees our own added backslashes are
        // never revisited — user-typed backslashes are always doubled.
        #expect("a\\b".escapedForTantivy == "+a\\\\b")
    }
    
    @Test func symbolOnlyTokensGetNoMustPrefix() {
        // The default tokenizer indexes no terms for `:)`; as a Must clause it could only
        // subtract, so it stays optional.
        #expect(":)".escapedForTantivy == "\\:\\)")
    }
    
    @Test func matrixIdentifiersSurvive() {
        #expect("@alice:example.org".escapedForTantivy == "+@alice\\:example.org")
    }
    
    @Test func specialCharactersCarryingCombiningMarksAreStillEscaped() {
        // A special character followed by a combining mark is one Swift Character but still that
        // special character to tantivy's scalar-level grammar. Escaping must reach it.
        #expect("\u{22}\u{0301}hi".escapedForTantivy == "+\\\u{22}\u{0301}hi") // combined " must escape
        #expect("a:\u{0301}b".escapedForTantivy == "+a\\:\u{0301}b") // combined : must escape
    }
    
    @Test func whitespaceCollapses() {
        #expect("  a \n b  ".escapedForTantivy == "+a +b")
        #expect("".escapedForTantivy == "")
        #expect("   ".escapedForTantivy == "")
    }
    
    @Test func remainingAndroidSuiteCases() {
        // The groups above compress the Android suite; these are the cases they miss. Keep this
        // file 1:1 with TantivyQueryEscaperTest.kt (21 cases) — cross-check when porting.
        #expect("body : hello".escapedForTantivy == "+body \\: +hello") // spaced field colon
        #expect(">quote".escapedForTantivy == "+\\>quote") // leading elastic-range operator
        #expect("\"unclosed".escapedForTantivy == "+\\\"unclosed") // unclosed quote
        #expect("🙂".escapedForTantivy == "🙂") // emoji: indexes no terms, stays optional
        #expect("...".escapedForTantivy == "...") // punctuation-only token, nothing to escape
        #expect("*".escapedForTantivy == "\\*") // lone wildcard, escaped and unprefixed
        #expect("héllo wörld".escapedForTantivy == "+héllo +wörld") // non-ASCII words are words
    }
}
