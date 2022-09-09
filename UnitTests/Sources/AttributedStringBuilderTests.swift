//
// Copyright 2022 New Vector Ltd
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

class AttributedStringBuilderTests: XCTestCase {
    let attributedStringBuilder = AttributedStringBuilder()
    let maxHeaderPointSize = ceil(UIFont.preferredFont(forTextStyle: .body).pointSize * 1.2)
    
    func testRenderHTMLStringWithHeaders() async {
        let h1HTMLString = "<h1>Large Heading</h1>"
        let h2HTMLString = "<h2>Smaller Heading</h2>"
        let h3HTMLString = "<h3>Acceptable Heading</h3>"
        
        guard let h1AttributedString = await attributedStringBuilder.fromHTML(h1HTMLString),
              let h2AttributedString = await attributedStringBuilder.fromHTML(h2HTMLString),
              let h3AttributedString = await attributedStringBuilder.fromHTML(h3HTMLString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(h1AttributedString.characters), "Large Heading")
        XCTAssertEqual(String(h2AttributedString.characters), "Smaller Heading")
        XCTAssertEqual(String(h3AttributedString.characters), "Acceptable Heading")
        
        XCTAssert(h1AttributedString.runs.count == 1)
        XCTAssert(h2AttributedString.runs.count == 1)
        XCTAssert(h3AttributedString.runs.count == 1)
        
        guard let h1Font = h1AttributedString.runs.first?.uiKit.font,
              let h2Font = h2AttributedString.runs.first?.uiKit.font,
              let h3Font = h3AttributedString.runs.first?.uiKit.font else {
            XCTFail("Could not extract a font from the strings.")
            return
        }
    
        XCTAssertEqual(h1Font, h2Font)
        XCTAssertEqual(h2Font, h3Font)
        
        XCTAssert(h1Font.pointSize > UIFont.preferredFont(forTextStyle: .body).pointSize)
        
        XCTAssert(h1Font.pointSize <= maxHeaderPointSize)
    }
    
    func testRenderHTMLStringWithPreCode() async {
        let htmlString = "<pre><code>1\n2\n3\n4\n</code></pre>"
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.first?.uiKit.font?.fontName, "Menlo-Regular")
        
        let string = String(attributedString.characters)
        
        guard let regex = try? NSRegularExpression(pattern: "\\R", options: []) else {
            XCTFail("Could not build the regex for the test.")
            return
        }
        
        XCTAssertEqual(regex.numberOfMatches(in: string, options: [], range: .init(location: 0, length: string.count)), 3)
    }
    
    func testRenderHTMLStringWithLink() async {
        let htmlString = "This text contains a <a href=\"https://www.matrix.org/\">link</a>."
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "This text contains a link.")
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first(where: { $0.link != nil })?.link
        
        XCTAssertEqual(link?.host, "www.matrix.org")
    }
    
    func testRenderPlainStringWithLink() async {
        let plainString = "This text contains a https://www.matrix.org link."
        
        guard let attributedString = await attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), plainString)
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first(where: { $0.link != nil })?.link
        
        XCTAssertEqual(link?.host, "www.matrix.org")
    }
    
    func testRenderHTMLStringWithLinkInHeader() async {
        let h1HTMLString = "<h1><a href=\"https://www.matrix.org/\">Matrix.org</a></h1>"
        let h2HTMLString = "<h2><a href=\"https://www.matrix.org/\">Matrix.org</a></h2>"
        let h3HTMLString = "<h3><a href=\"https://www.matrix.org/\">Matrix.org</a></h3>"
        
        guard let h1AttributedString = await attributedStringBuilder.fromHTML(h1HTMLString),
              let h2AttributedString = await attributedStringBuilder.fromHTML(h2HTMLString),
              let h3AttributedString = await attributedStringBuilder.fromHTML(h3HTMLString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(h1AttributedString.characters), "Matrix.org")
        XCTAssertEqual(String(h2AttributedString.characters), "Matrix.org")
        XCTAssertEqual(String(h3AttributedString.characters), "Matrix.org")
        
        XCTAssertEqual(h1AttributedString.runs.count, 1)
        XCTAssertEqual(h2AttributedString.runs.count, 1)
        XCTAssertEqual(h3AttributedString.runs.count, 1)
        
        guard let h1Font = h1AttributedString.runs.first?.uiKit.font,
              let h2Font = h2AttributedString.runs.first?.uiKit.font,
              let h3Font = h3AttributedString.runs.first?.uiKit.font else {
            XCTFail("Could not extract a font from the strings.")
            return
        }
        
        XCTAssertEqual(h1Font, h2Font)
        XCTAssertEqual(h2Font, h3Font)
        
        XCTAssert(h1Font.pointSize > UIFont.preferredFont(forTextStyle: .body).pointSize)
        XCTAssert(h1Font.pointSize <= maxHeaderPointSize)
        
        XCTAssertEqual(h1AttributedString.runs.first?.link?.host, "www.matrix.org")
        XCTAssertEqual(h2AttributedString.runs.first?.link?.host, "www.matrix.org")
        XCTAssertEqual(h3AttributedString.runs.first?.link?.host, "www.matrix.org")
    }
    
    func testRenderHTMLStringWithIFrame() async {
        let htmlString = "<iframe src=\"https://www.matrix.org/\"></iframe>"
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertNil(attributedString.uiKit.attachment, "iFrame attachments should be removed as they're not included in the allowedHTMLTags array.")
    }
    
    func testUserIdLink() async {
        let userId = "@user:matrix.org"
        let string = "The user is \(userId)."
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromHTML(string), expected: userId)
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromPlain(string), expected: userId)
    }
    
    func testRoomAliasLink() async {
        let roomAlias = "#matrix:matrix.org"
        let string = "The room alias is \(roomAlias)."
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromHTML(string), expected: roomAlias)
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromPlain(string), expected: roomAlias)
    }
    
    func testRoomIdLink() async {
        let roomId = "!roomidentifier:matrix.org"
        let string = "The room is \(roomId)."
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromHTML(string), expected: roomId)
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromPlain(string), expected: roomId)
    }
    
    func testEventIdLink() async {
        let eventId = "$eventidentifier"
        let string = "The event is \(eventId)."
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromHTML(string), expected: eventId)
        checkMatrixEntityLinkIn(attributedString: await attributedStringBuilder.fromPlain(string), expected: eventId)
    }
    
    func testDefaultFont() async {
        let htmlString = "<b>Test</b> <i>string</i>."
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 4)
        
        for run in attributedString.runs {
            XCTAssertEqual(run.uiKit.font?.familyName, UIFont.preferredFont(forTextStyle: .body).familyName)
        }
    }
    
    func testDefaultForegroundColor() async {
        let htmlString = "<b>Test</b> <i>string</i>."
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 4)
        
        for run in attributedString.runs {
            XCTAssertNil(run.uiKit.foregroundColor)
        }
    }
    
    func testCustomForegroundColor() async {
        // swiftlint:disable:next line_length
        let htmlString = "<font color=\"#ff00be\">R</font><font color=\"#ff0082\">a</font><font color=\"#ff0047\">i</font><font color=\"#ff5800\">n </font><font color=\"#ffa300\">w</font><font color=\"#d2ba00\">w</font><font color=\"#97ca00\">w</font><font color=\"#3ed500\">.</font><font color=\"#00dd00\">m</font><font color=\"#00e251\">a</font><font color=\"#00e595\">t</font><font color=\"#00e7d6\">r</font><font color=\"#00e7ff\">i</font><font color=\"#00e6ff\">x</font><font color=\"#00e3ff\">.</font><font color=\"#00dbff\">o</font><font color=\"#00ceff\">r</font><font color=\"#00baff\">g</font><font color=\"#f477ff\"> b</font><font color=\"#ff3aff\">o</font><font color=\"#ff00fb\">w</font>"
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 8)
        
        var foundLink = false
        for run in attributedString.runs {
            if run.link != nil {
                XCTAssertEqual(run.link?.path, "www.matrix.org")
                XCTAssertNil(run.uiKit.foregroundColor)
                foundLink = true
            } else {
                XCTAssertNotNil(run.uiKit.foregroundColor)
            }
        }
        
        XCTAssertTrue(foundLink)
    }
    
    func testSingleBlockquote() async {
        let htmlString = "<blockquote>Blockquote</blockquote>"
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 1)
        
        XCTAssertEqual(attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString)?.count, 1)
        
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            return
        }
        
        XCTFail("Couldn't find blockquote")
    }
    
    // swiftlint:disable line_length
    func testBlockquoteWithinText() async {
        let htmlString = """
        The text before the blockquote
        <blockquote> For 50 years, WWF has been protecting the future of nature. The world's leading conservation organization, WWF works in 100 countries and is supported by 1.2 million members in the United States and close to 5 million globally.</blockquote>
        The text after the blockquote
        """
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        XCTAssertEqual(attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString)?.count, 3)
        
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            return
        }
        
        XCTFail("Couldn't find blockquote")
    }

    // swiftlint:enable line_length
    
    func testBlockquoteWithLink() async {
        let htmlString = "<blockquote>Blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>"
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        guard let coalescedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString) else {
            XCTFail("Could not build the attributed string components")
            return
        }
        XCTAssertEqual(coalescedComponents.count, 1)
        
        XCTAssertEqual(coalescedComponents.first?.attributedString.runs.count, 3, "Link not present in the component")
        
        var foundBlockquoteAndLink = false
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            foundBlockquoteAndLink = true
        }
        
        XCTAssertNotNil(foundBlockquoteAndLink, "Couldn't find blockquote or link")
    }
    
    func testMultipleGroupedBlockquotes() async {
        let htmlString = """
        <blockquote>First blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        <blockquote>Second blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        <blockquote>Third blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        """
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 7)
        
        XCTAssertEqual(attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString)?.count, 1)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            numberOfBlockquotes += 1
        }
        
        XCTAssertEqual(numberOfBlockquotes, 3, "Couldn't find all the blockquotes")
    }
    
    func testMultipleSeparatedBlockquotes() async {
        let htmlString = """
        First
        <blockquote>blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        Second
        <blockquote>blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        Third
        <blockquote>blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        """
        
        guard let attributedString = await attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 12)
        
        XCTAssertEqual(attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedString)?.count, 6)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            numberOfBlockquotes += 1
        }
        
        XCTAssertEqual(numberOfBlockquotes, 3, "Couldn't find all the blockquotes")
    }
    
    // MARK: - Private
    
    private func checkMatrixEntityLinkIn(attributedString: AttributedString?, expected: String) {
        guard let attributedString = attributedString else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        for run in attributedString.runs where run.link != nil {
            XCTAssertEqual(run.link?.path, expected)
            return
        }
        
        XCTFail("Couldn't find expected value.")
    }
}
