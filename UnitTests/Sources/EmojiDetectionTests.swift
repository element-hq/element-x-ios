//
// Copyright 2023 New Vector Ltd
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
        XCTAssertTrue("👁❤️🍝".containsOnlyEmoji)
        XCTAssertFalse("🙂 ".containsOnlyEmoji)
        XCTAssertFalse("Hello 👋".containsOnlyEmoji)
        XCTAssertFalse("Thanks".containsOnlyEmoji)
    }
}
