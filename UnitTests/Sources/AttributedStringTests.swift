//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import XCTest

class AttributedStringTests: XCTestCase {
    func testReplacingFontWithPresentationIntent() {
        // Given a string parsed from HTML that contains specific fixed size fonts.
        let boldString = "Bold"
        guard let originalString = AttributedStringBuilder(mentionBuilder: MentionBuilder())
            .fromHTML("Normal <b>\(boldString)</b> Normal.") else {
            XCTFail("The attributed string should be built from the HTML.")
            return
        }
        originalString.runs.forEach { XCTAssertNotNil($0.uiKit.font, "The original runs should all have a UIFont.") }
        
        // When replacing the font with a presentation intent.
        let string = originalString.replacingFontWithPresentationIntent()
        
        // Then the font should be removed with an inline presentation intent applied to the bold text.
        for run in string.runs {
            XCTAssertNil(run.uiKit.font, "The UIFont should have been removed.")
            XCTAssertNil(run.font, "No font should be in the run at all.")
            
            let substring = string[run.range]
            if String(substring.characters) == boldString {
                XCTAssertEqual(run.inlinePresentationIntent, .stronglyEmphasized, "The bold string should be bold.")
            } else {
                XCTAssertNil(run.presentationIntent, "The rest should be plain.")
            }
        }
    }
}
