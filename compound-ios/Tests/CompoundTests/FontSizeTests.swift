//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import Compound
import SwiftUI
import XCTest

final class FontSizeTests: XCTestCase {
    /// Test all system text styles to assert mapping between `Font` and `UIFont`.
    func testTextStyle() throws {
        let caption2FontSize = FontSize.reflecting(.caption2)
        XCTAssertEqual(caption2FontSize?.value, 11)
        XCTAssertEqual(caption2FontSize?.style, .caption2)
        
        let captionFontSize = FontSize.reflecting(.caption)
        XCTAssertEqual(captionFontSize?.value, 12)
        XCTAssertEqual(captionFontSize?.style, .caption)
        
        let footnoteFontSize = FontSize.reflecting(.footnote)
        XCTAssertEqual(footnoteFontSize?.value, 13)
        XCTAssertEqual(footnoteFontSize?.style, .footnote)
        
        let subheadlineFontSize = FontSize.reflecting(.subheadline)
        XCTAssertEqual(subheadlineFontSize?.value, 15)
        XCTAssertEqual(subheadlineFontSize?.style, .subheadline)
        
        let calloutFontSize = FontSize.reflecting(.callout)
        XCTAssertEqual(calloutFontSize?.value, 16)
        XCTAssertEqual(calloutFontSize?.style, .callout)
        
        let bodyFontSize = FontSize.reflecting(.body)
        XCTAssertEqual(bodyFontSize?.value, 17)
        XCTAssertEqual(bodyFontSize?.style, .body)
        
        let headlineFontSize = FontSize.reflecting(.headline)
        XCTAssertEqual(headlineFontSize?.value, 17)
        XCTAssertEqual(headlineFontSize?.style, .headline)
        
        let title3FontSize = FontSize.reflecting(.title3)
        XCTAssertEqual(title3FontSize?.value, 20)
        XCTAssertEqual(title3FontSize?.style, .title3)
        
        let title2FontSize = FontSize.reflecting(.title2)
        XCTAssertEqual(title2FontSize?.value, 22)
        XCTAssertEqual(title2FontSize?.style, .title2)
        
        let titleFontSize = FontSize.reflecting(.title)
        XCTAssertEqual(titleFontSize?.value, 28)
        XCTAssertEqual(titleFontSize?.style, .title)
        
        let largeTitleFontSize = FontSize.reflecting(.largeTitle)
        XCTAssertEqual(largeTitleFontSize?.value, 34)
        XCTAssertEqual(largeTitleFontSize?.style, .largeTitle)
    }
    
    func testModifiedTextStyle() {
        let boldCaptionFontSize = FontSize.reflecting(.caption.bold())
        XCTAssertEqual(boldCaptionFontSize?.value, 12)
        XCTAssertEqual(boldCaptionFontSize?.style, .caption)
        
        let styledTitle = Font.title.width(.compressed).bold().italic().monospaced()
        let styledTitleFontSize = FontSize.reflecting(styledTitle)
        XCTAssertEqual(styledTitleFontSize?.value, 28)
        XCTAssertEqual(styledTitleFontSize?.style, .title)
    }
    
    func testSystemFont() {
        let system21FontSize = FontSize.reflecting(.system(size: 21))
        XCTAssertEqual(system21FontSize?.value, 21)
        
        let boldSystem29FontSize = FontSize.reflecting(.system(size: 29).bold())
        XCTAssertEqual(boldSystem29FontSize?.value, 29)
        
        let styledSystem33 = Font.system(size: 33).width(.compressed).bold().italic().monospacedDigit()
        let styledSystem33FontSize = FontSize.reflecting(styledSystem33)
        XCTAssertEqual(styledSystem33FontSize?.value, 33)
    }
    
    func testCustomFont() {
        let custom43FontSize = FontSize.reflecting(.custom("Baskerville", size: 43))
        XCTAssertEqual(custom43FontSize?.value, 43)
        XCTAssertEqual(custom43FontSize?.style, .body)
        
        let styledCustom35 = Font.custom("Baskerville", size: 35).weight(.thin).monospaced().italic()
        let styledCustom35FontSize = FontSize.reflecting(styledCustom35)
        XCTAssertEqual(styledCustom35FontSize?.value, 35)
        XCTAssertEqual(styledCustom35FontSize?.style, .body)
    }
    
    func testCustomFontWithTextStyle() {
        let customTitle21FontSize = FontSize.reflecting(.custom("Baskerville", size: 21, relativeTo: .title))
        XCTAssertEqual(customTitle21FontSize?.value, 21)
        XCTAssertEqual(customTitle21FontSize?.style, .title)
        
        let styledCustomFootnote15 = Font.custom("Baskerville", size: 15, relativeTo: .footnote).weight(.thin).monospaced().italic()
        let styledCustomFootnote15FontSize = FontSize.reflecting(styledCustomFootnote15)
        XCTAssertEqual(styledCustomFootnote15FontSize?.value, 15)
        XCTAssertEqual(styledCustomFootnote15FontSize?.style, .footnote)
    }
}
