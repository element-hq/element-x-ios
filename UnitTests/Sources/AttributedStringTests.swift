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

@testable import ElementX
import XCTest

class AttributedStringTests: XCTestCase {
    func testReplacingFontWithPresentationIntent() {
        // Given a string parsed from HTML that contains specific fixed size fonts.
        let boldString = "Bold"
        guard let originalString = AttributedStringBuilder().fromHTML("Normal <b>\(boldString)</b> Normal.") else {
            XCTFail("The attributed string should be built from the HTML.")
            return
        }
        for run in originalString.runs { XCTAssertNotNil(run.uiKit.font, "The original runs should all have a UIFont.") }
        
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
