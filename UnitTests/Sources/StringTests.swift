//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class StringTests: XCTestCase {
    func testEmptyIsAscii() {
        XCTAssertTrue("".isASCII)
    }
    
    func testSpaceIsAscii() {
        XCTAssertTrue("".isASCII)
    }

    func testJohnnyIsAscii() {
        XCTAssertTrue("johnny".isASCII)
    }
    
    func testJöhnnyIsNotAscii() {
        XCTAssertFalse("jöhnny".isASCII)
    }
    
    func testJ🅾️hnnyIsNotAscii() {
        XCTAssertFalse("j🅾️hnny".isASCII)
    }

    func testAsciiStaysAscii() {
        XCTAssertEqual("johnny".asciified(), "johnny")
    }
    
    func testÖBecomesO() {
        XCTAssertEqual("jöhnny".asciified(), "johnny")
    }
    
    func testÅBecomesA() {
        XCTAssertEqual("jåhnny".asciified(), "jahnny")
    }
    
    func test1️⃣2️⃣3️⃣Becomes123() {
        XCTAssertEqual("1️⃣2️⃣3️⃣".asciified(), "123")
    }
    
    func testStripsTheHeartbreakHotel() {
        XCTAssertEqual("Heartbreak Hotel 🏩".asciified(), "Heartbreak Hotel")
    }

    func testGenerateBreakableWhitespaceEnd() {
        var count = 5
        var result = "\u{2066}" + String(repeating: "\u{2004}", count: count) + "\u{2800}"
        XCTAssertEqual(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .leftToRight), result)

        count = 3
        result = "\u{2066}" + String(repeating: "\u{2004}", count: count) + "\u{2800}"
        XCTAssertEqual(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .leftToRight), result)

        count = 0
        result = ""
        XCTAssertEqual(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .leftToRight), result)

        count = 4
        result = "\u{2067}" + String(repeating: "\u{2004}", count: count) + "\u{2800}"
        XCTAssertEqual(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .rightToLeft), result)

        count = 0
        result = ""
        XCTAssertEqual(String.generateBreakableWhitespaceEnd(whitespaceCount: count, layoutDirection: .rightToLeft), result)
    }
    
    func testEllipsizeWorks() {
        XCTAssertEqual("ellipsize".ellipsize(length: 5), "ellip…")
    }
    
    func testEllipsizeNotNeeded() {
        XCTAssertEqual("ellipsize".ellipsize(length: 15), "ellipsize")
    }
    
    func testReplaceBreakOccurrences() {
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
        
        XCTAssertEqual(input0.replacingHtmlBreaksOccurrences(), expectedOutput0)
        XCTAssertEqual(input1.replacingHtmlBreaksOccurrences(), expectedOutput1)
        XCTAssertEqual(input2.replacingHtmlBreaksOccurrences(), expectedOutput2)
        XCTAssertEqual(input3.replacingHtmlBreaksOccurrences(), expectedOutput3)
        XCTAssertEqual(input4.replacingHtmlBreaksOccurrences(), expectedOutput4)
        XCTAssertEqual(input5.replacingHtmlBreaksOccurrences(), expectedOutput5)
    }
}
