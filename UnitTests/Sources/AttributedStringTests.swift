//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
struct AttributedStringTests {
    @Test
    func replacingFontWithPresentationIntent() throws {
        // Given a string parsed from HTML that contains specific fixed size fonts.
        let boldString = "Bold"
        let originalString = try #require(AttributedStringBuilder(mentionBuilder: MentionBuilder())
            .fromHTML("Normal <b>\(boldString)</b> Normal."))
        
        // When replacing the font with a presentation intent.
        let string = originalString.replacingFontWithPresentationIntent()
        
        // Then the font should be removed with an inline presentation intent applied to the bold text.
        for run in string.runs {
            #expect(run.uiKit.font == nil, "The UIFont should have been removed.")
            #expect(run.font == nil, "No font should be in the run at all.")
            
            let substring = string[run.range]
            if String(substring.characters) == boldString {
                #expect(run.inlinePresentationIntent == .stronglyEmphasized, "The bold string should be bold.")
            } else {
                #expect(run.presentationIntent == nil, "The rest should be plain.")
            }
        }
    }
}
