//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import Compound
import SwiftUI
import Testing

@MainActor
@Suite
struct FontSizeTests {
    /// Test all system text styles to assert mapping between `Font` and `UIFont`.
    @Test("Text style")
    func textStyle() {
        let caption2FontSize = FontSize.reflecting(.caption2)
        #expect(caption2FontSize?.value == 11)
        #expect(caption2FontSize?.style == .caption2)
        
        let captionFontSize = FontSize.reflecting(.caption)
        #expect(captionFontSize?.value == 12)
        #expect(captionFontSize?.style == .caption)
        
        let footnoteFontSize = FontSize.reflecting(.footnote)
        #expect(footnoteFontSize?.value == 13)
        #expect(footnoteFontSize?.style == .footnote)
        
        let subheadlineFontSize = FontSize.reflecting(.subheadline)
        #expect(subheadlineFontSize?.value == 15)
        #expect(subheadlineFontSize?.style == .subheadline)
        
        let calloutFontSize = FontSize.reflecting(.callout)
        #expect(calloutFontSize?.value == 16)
        #expect(calloutFontSize?.style == .callout)
        
        let bodyFontSize = FontSize.reflecting(.body)
        #expect(bodyFontSize?.value == 17)
        #expect(bodyFontSize?.style == .body)
        
        let headlineFontSize = FontSize.reflecting(.headline)
        #expect(headlineFontSize?.value == 17)
        #expect(headlineFontSize?.style == .headline)
        
        let title3FontSize = FontSize.reflecting(.title3)
        #expect(title3FontSize?.value == 20)
        #expect(title3FontSize?.style == .title3)
        
        let title2FontSize = FontSize.reflecting(.title2)
        #expect(title2FontSize?.value == 22)
        #expect(title2FontSize?.style == .title2)
        
        let titleFontSize = FontSize.reflecting(.title)
        #expect(titleFontSize?.value == 28)
        #expect(titleFontSize?.style == .title)
        
        let largeTitleFontSize = FontSize.reflecting(.largeTitle)
        #expect(largeTitleFontSize?.value == 34)
        #expect(largeTitleFontSize?.style == .largeTitle)
    }
    
    @Test("Modified text style font sizes")
    func modifiedTextStyle() {
        let boldCaptionFontSize = FontSize.reflecting(.caption.bold())
        #expect(boldCaptionFontSize?.value == 12)
        #expect(boldCaptionFontSize?.style == .caption)
        
        let styledTitle = Font.title.width(.compressed).bold().italic().monospaced()
        let styledTitleFontSize = FontSize.reflecting(styledTitle)
        #expect(styledTitleFontSize?.value == 28)
        #expect(styledTitleFontSize?.style == .title)
    }
    
    @Test("System font sizes")
    func systemFont() {
        let system21FontSize = FontSize.reflecting(.system(size: 21))
        #expect(system21FontSize?.value == 21)
        
        let boldSystem29FontSize = FontSize.reflecting(.system(size: 29).bold())
        #expect(boldSystem29FontSize?.value == 29)
        
        let styledSystem33 = Font.system(size: 33).width(.compressed).bold().italic().monospacedDigit()
        let styledSystem33FontSize = FontSize.reflecting(styledSystem33)
        #expect(styledSystem33FontSize?.value == 33)
    }
    
    @Test("Custom font sizes")
    func customFont() {
        let custom43FontSize = FontSize.reflecting(.custom("Baskerville", size: 43))
        #expect(custom43FontSize?.value == 43)
        #expect(custom43FontSize?.style == .body)
        
        let styledCustom35 = Font.custom("Baskerville", size: 35).weight(.thin).monospaced().italic()
        let styledCustom35FontSize = FontSize.reflecting(styledCustom35)
        #expect(styledCustom35FontSize?.value == 35)
        #expect(styledCustom35FontSize?.style == .body)
    }
    
    @Test("Custom font with text style")
    func customFontWithTextStyle() {
        let customTitle21FontSize = FontSize.reflecting(.custom("Baskerville", size: 21, relativeTo: .title))
        #expect(customTitle21FontSize?.value == 21)
        #expect(customTitle21FontSize?.style == .title)
        
        let styledCustomFootnote15 = Font.custom("Baskerville", size: 15, relativeTo: .footnote).weight(.thin).monospaced().italic()
        let styledCustomFootnote15FontSize = FontSize.reflecting(styledCustomFootnote15)
        #expect(styledCustomFootnote15FontSize?.value == 15)
        #expect(styledCustomFootnote15FontSize?.style == .footnote)
    }
}
 