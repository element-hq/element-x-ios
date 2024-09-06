//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class EmojiDetectionTests: XCTestCase {
    func testEmojiDetection() {
        XCTAssertTrue("👨‍👩‍👦".containsOnlyEmoji)
        XCTAssertTrue("1️⃣".containsOnlyEmoji)
        XCTAssertTrue("🚀".containsOnlyEmoji)
        XCTAssertTrue("👳🏾‍♂️".containsOnlyEmoji)
        XCTAssertTrue("🪩".containsOnlyEmoji)
        
        XCTAssertTrue("👨‍👩‍👦1️⃣🚀👳🏾‍♂️🪩".containsOnlyEmoji)
        
        XCTAssertFalse(" 👨‍👩‍👦".containsOnlyEmoji)
        XCTAssertFalse(" 👨‍👩‍👦 ".containsOnlyEmoji)
        XCTAssertFalse("👨‍👩‍👦 ".containsOnlyEmoji)
        XCTAssertFalse("Ciao 👨‍👩‍👦 peeps".containsOnlyEmoji)
        
        XCTAssertFalse("0".containsOnlyEmoji)
        XCTAssertFalse("1".containsOnlyEmoji)
        XCTAssertFalse("5".containsOnlyEmoji)
        XCTAssertFalse("000".containsOnlyEmoji)
        
        XCTAssertTrue("👍".containsOnlyEmoji)
        XCTAssertTrue("🫱🏼‍🫲🏾".containsOnlyEmoji)
        XCTAssertFalse("🙂 ".containsOnlyEmoji)
        XCTAssertFalse("Hello 👋".containsOnlyEmoji)
        XCTAssertFalse("Thanks".containsOnlyEmoji)
        
        XCTAssertFalse("0*".containsOnlyEmoji)
    }
}
