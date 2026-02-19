//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
struct StringTests {
    @Test
    func emptyIsAscii() {
        #expect("".isASCII)
    }
    
    @Test
    func spaceIsAscii() {
        #expect("".isASCII)
    }

    @Test
    func johnnyIsAscii() {
        #expect("johnny".isASCII)
    }
    
    @Test
    func jöhnnyIsNotAscii() {
        #expect(!"jöhnny".isASCII)
    }
    
    @Test
    func jEmojiHnnyIsNotAscii() {
        #expect(!"j🅾️hnny".isASCII)
    }
    
    @Test
    func asciifiedMethod() {
        // ASCII strings return themselves unchanged
        #expect("johnny".asciified() == "johnny")
        #expect("hello".asciified() == "hello")
        #expect("abc123".asciified() == "abc123")
        #expect("".asciified() == "")
        #expect(" ".asciified() == " ")
        
        // Non-ASCII strings get converted or stripped
        #expect("jöhnny".asciified() == "johnny", "ö should become o")
        #expect("jåhnny".asciified() == "jahnny", "å should become a")
        #expect("café".asciified() == "cafe")
        #expect("naïve".asciified() == "naive")
        #expect("résumé".asciified() == "resume")
        #expect("🚀".asciified() == "")
        #expect("Heartbreak Hotel 🏩".asciified() == "Heartbreak Hotel", "The emoji should be stripped.")
        #expect("1️⃣2️⃣3️⃣".asciified() == "123", "The emoji should be converted to ASCII.")
    }

    @Test
    func generateBreakableWhitespaceEnd() {
        var count = 5
        var result = "\u{2066}" + String(repeating: "\u{2004}", count: count) + "\u{2800}"
        #expect(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .leftToRight) == result)

        count = 3
        result = "\u{2066}" + String(repeating: "\u{2004}", count: count) + "\u{2800}"
        #expect(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .leftToRight) == result)

        count = 0
        result = ""
        #expect(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .leftToRight) == result)

        count = 4
        result = "\u{2067}" + String(repeating: "\u{2004}", count: count) + "\u{2800}"
        #expect(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .rightToLeft) == result)

        count = 0
        result = ""
        #expect(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .rightToLeft) == result)
    }
    
    @Test
    func ellipsizeWorks() {
        #expect("ellipsize".ellipsize(length: 5) == "ellip…")
    }
    
    @Test
    func ellipsizeNotNeeded() {
        #expect("ellipsize".ellipsize(length: 15) == "ellipsize")
    }
    
    @Test
    func replaceBreakOccurrences() {
        let input0 = "</p><p>"
        let input1 = "</p>\n<p>"
        let input2 = "</p>\n\n<p>"
        let input3 = "</p>\n\n\n\n<p>"
        let input4 = "<p>a</p>\n<p>b</p>"
        let input5 = "empty"
        
        let expectedOutput0 = input0
        let expectedOutput1 = "<br><br>"
        let expectedOutput2 = "<br><br><br>"
        let expectedOutput3 = "<br><br><br><br><br>"
        let expectedOutput4 = "<p>a<br><br>b</p>"
        let expectedOutput5 = input5
        
        #expect(input0.replacingHtmlBreaksOccurrences() == expectedOutput0)
        #expect(input1.replacingHtmlBreaksOccurrences() == expectedOutput1)
        #expect(input2.replacingHtmlBreaksOccurrences() == expectedOutput2)
        #expect(input3.replacingHtmlBreaksOccurrences() == expectedOutput3)
        #expect(input4.replacingHtmlBreaksOccurrences() == expectedOutput4)
        #expect(input5.replacingHtmlBreaksOccurrences() == expectedOutput5)
    }
}
