//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import XCTest

class AttributedStringBuilderTests: XCTestCase {
    private lazy var attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
    private let maxHeaderPointSize = ceil(UIFont.preferredFont(forTextStyle: .body).pointSize * 1.2)
    
    func testRenderHTMLStringWithHeaders() {
        let h1HTMLString = "<h1>Large Heading</h1>"
        let h2HTMLString = "<h2>Smaller Heading</h2>"
        let h3HTMLString = "<h3>Acceptable Heading</h3>"
        
        guard let h1AttributedString = attributedStringBuilder.fromHTML(h1HTMLString),
              let h2AttributedString = attributedStringBuilder.fromHTML(h2HTMLString),
              let h3AttributedString = attributedStringBuilder.fromHTML(h3HTMLString) else {
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
    
    func testRenderHTMLStringWithPreCode() {
        let htmlString = "<pre><code>1\n2\n3\n4\n</code></pre>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.first?.uiKit.font?.fontName, ".AppleSystemUIFontMonospaced-Regular")
        
        let string = String(attributedString.characters)
        
        guard let regex = try? NSRegularExpression(pattern: "\\R", options: []) else {
            XCTFail("Could not build the regex for the test.")
            return
        }
        
        XCTAssertEqual(regex.numberOfMatches(in: string, options: [], range: .init(location: 0, length: string.count)), 3)
    }
    
    func testRenderHTMLStringWithLink() {
        let htmlString = "This text contains a <a href=\"https://www.matrix.org/\">link</a>."
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "This text contains a link.")
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first(where: { $0.link != nil })?.link
        
        XCTAssertEqual(link?.host, "www.matrix.org")
    }
    
    func testRenderPlainStringWithLink() {
        let plainString = "This text contains a https://www.matrix.org link."
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), plainString)
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first(where: { $0.link != nil })?.link
        
        XCTAssertEqual(link?.host, "www.matrix.org")
    }
    
    func testPunctuationAtTheEndOfPlainStringLinks() {
        let plainString = "This text contains a https://www.matrix.org:;., link."
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), plainString)
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first(where: { $0.link != nil })?.link
        
        XCTAssertEqual(link?.host, "www.matrix.org")
    }
    
    func testLinkDefaultScheme() {
        let plainString = "This text contains a matrix.org link."
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), plainString)
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first(where: { $0.link != nil })?.link
        
        XCTAssertEqual(link, "https://matrix.org")
    }
    
    func testRenderHTMLStringWithLinkInHeader() {
        let h1HTMLString = "<h1><a href=\"https://www.matrix.org/\">Matrix.org</a></h1>"
        let h2HTMLString = "<h2><a href=\"https://www.matrix.org/\">Matrix.org</a></h2>"
        let h3HTMLString = "<h3><a href=\"https://www.matrix.org/\">Matrix.org</a></h3>"
        
        guard let h1AttributedString = attributedStringBuilder.fromHTML(h1HTMLString),
              let h2AttributedString = attributedStringBuilder.fromHTML(h2HTMLString),
              let h3AttributedString = attributedStringBuilder.fromHTML(h3HTMLString) else {
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
    
    func testRenderHTMLStringWithIFrame() {
        let htmlString = "<iframe src=\"https://www.matrix.org/\"></iframe>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertNil(attributedString.uiKit.attachment, "iFrame attachments should be removed as they're not included in the allowedHTMLTags array.")
    }
    
    func testLinkWithFragment() {
        var string = "https://example.com/#/"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: "https://example.com", expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: "https://example.com", expectedRuns: 1)
        
        string = "https://example.com/#/some_fragment/"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: "https://example.com/#/some_fragment", expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: "https://example.com/#/some_fragment", expectedRuns: 1)
    }
    
    func testPermalink() {
        let string = "https://matrix.to/#/!hello:matrix.org/$world?via=matrix.org"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: string, expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: string, expectedRuns: 1)
    }
    
    func testMatrixURI() {
        let string = "matrix:roomid/hello:matrix.org/e/world?via=matrix.org"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: string, expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: string, expectedRuns: 1)
    }
    
    func testUserIDLink() {
        let userID = "@user:matrix.org"
        let string = "The user is \(userID)."
        let expectedLink = "https://matrix.to/#/\(userID)"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: expectedLink, expectedRuns: 3)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: expectedLink, expectedRuns: 3)
    }
    
    func testRoomAliasLink() {
        let roomAlias = "#room:matrix.org"
        let string = "The room is \(roomAlias)."
        guard let expectedLink = URL(string: "https://matrix.to/#/\(roomAlias)") else {
            XCTFail("The expected link should be valid.")
            return
        }
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: expectedLink.absoluteString, expectedRuns: 3)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: expectedLink.absoluteString, expectedRuns: 3)
    }
    
    // `Plain link in codeblock: https://www.matrix.org`, Link tag in codeblock: <a href=\"https://www.matrix.org/\">link</a>, plain link: https://www.matrix.org, link tag: <a href=\"https://www.matrix.org/\">link</a>
        
    func testDefaultFont() {
        let htmlString = "<b>Test</b> <i>string</i> "
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        for run in attributedString.runs {
            XCTAssertEqual(run.uiKit.font?.familyName, UIFont.preferredFont(forTextStyle: .body).familyName)
        }
    }
    
    func testDefaultForegroundColor() {
        let htmlString = "<b>Test</b> <i>string</i> <a href=\"https://www.matrix.org/\">link</a> <code><a href=\"https://www.matrix.org/\">link</a></code>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 7)
        
        for run in attributedString.runs {
            XCTAssertNil(run.uiKit.foregroundColor)
        }
    }
    
    func testCustomForegroundColor() {
        // swiftlint:disable:next line_length
        let htmlString = "<font color=\"#ff00be\">R</font><font color=\"#ff0082\">a</font><font color=\"#ff0047\">i</font><font color=\"#ff5800\">n </font><font color=\"#ffa300\">w</font><font color=\"#d2ba00\">w</font><font color=\"#97ca00\">w</font><font color=\"#3ed500\">.</font><font color=\"#00dd00\">m</font><font color=\"#00e251\">a</font><font color=\"#00e595\">t</font><font color=\"#00e7d6\">r</font><font color=\"#00e7ff\">i</font><font color=\"#00e6ff\">x</font><font color=\"#00e3ff\">.</font><font color=\"#00dbff\">o</font><font color=\"#00ceff\">r</font><font color=\"#00baff\">g</font><font color=\"#f477ff\"> b</font><font color=\"#ff3aff\">o</font><font color=\"#ff00fb\">w</font>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        var foundLink = false
        // Foreground colors should be completely stripped from the attributed string
        // letting UI components chose the defaults (e.g. tintColor)
        for run in attributedString.runs {
            if run.link != nil {
                XCTAssertEqual(run.link?.host, "www.matrix.org")
                XCTAssertNil(run.uiKit.foregroundColor)
                foundLink = true
            } else {
                XCTAssertNil(run.uiKit.foregroundColor)
            }
        }
        
        XCTAssertTrue(foundLink)
    }
    
    func testSingleBlockquote() {
        let htmlString = "<blockquote>Blockquote</blockquote>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 1)
        
        XCTAssertEqual(attributedString.formattedComponents.count, 1)
        
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            return
        }
        
        XCTFail("Couldn't find blockquote")
    }
    
    // swiftlint:disable line_length
    func testBlockquoteWithinText() {
        let htmlString = """
        The text before the blockquote
        <blockquote> For 50 years, WWF has been protecting the future of nature. The world's leading conservation organization, WWF works in 100 countries and is supported by 1.2 million members in the United States and close to 5 million globally.</blockquote>
        The text after the blockquote
        """
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        XCTAssertEqual(attributedString.formattedComponents.count, 3)
        
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            return
        }
        
        XCTFail("Couldn't find blockquote")
    }

    // swiftlint:enable line_length
    
    func testBlockquoteWithLink() {
        let htmlString = "<blockquote>Blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let coalescedComponents = attributedString.formattedComponents
        
        XCTAssertEqual(coalescedComponents.count, 1)
        
        XCTAssertEqual(coalescedComponents.first?.attributedString.runs.count, 3, "Link not present in the component")
        
        var foundBlockquoteAndLink = false
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            foundBlockquoteAndLink = true
        }
        
        XCTAssertNotNil(foundBlockquoteAndLink, "Couldn't find blockquote or link")
    }
    
    func testReplyBlockquote() {
        let htmlString = "<blockquote><a href=\"https://matrix.to/#/someroom/someevent\">In reply to</a> <a href=\"https://matrix.to/#/@user:matrix.org\">@user:matrix.org</a><br>The future is <code>swift run tools</code> 😎</blockquote>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        let coalescedComponents = attributedString.formattedComponents
        XCTAssertEqual(coalescedComponents.count, 1)
        
        guard let component = coalescedComponents.first else {
            XCTFail("Could not get the first component")
            return
        }
        
        XCTAssertTrue(component.isBlockquote, "The reply quote should be a blockquote.")
    }
    
    func testMultipleGroupedBlockquotes() {
        let htmlString = """
        <blockquote>First blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        <blockquote>Second blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        <blockquote>Third blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        """
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 7)
        
        XCTAssertEqual(attributedString.formattedComponents.count, 1)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            numberOfBlockquotes += 1
        }
        
        XCTAssertEqual(numberOfBlockquotes, 3, "Couldn't find all the blockquotes")
    }
    
    func testMultipleSeparatedBlockquotes() {
        let htmlString = """
        First
        <blockquote>blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        Second
        <blockquote>blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        Third
        <blockquote>blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>
        """
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 12)
        
        let coalescedComponents = attributedString.formattedComponents
        
        XCTAssertEqual(coalescedComponents.count, 6)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            numberOfBlockquotes += 1
        }
        
        XCTAssertEqual(numberOfBlockquotes, 3, "Couldn't find all the blockquotes")
    }
    
    func testUserMentionAtachment() {
        let string = "https://matrix.to/#/@test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertNotNil(attributedStringFromHTML?.link)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertNotNil(attributedStringFromHTML?.link)
    }
    
    func testUserMentionAtachmentInBlockQuotes() {
        let link = "https://matrix.to/#/@test:matrix.org"
        let string = "<blockquote>hello \(link) how are you?</blockquote>"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            XCTFail("Attributed string is nil")
            return
        }
        
        for run in attributedStringFromHTML.runs {
            XCTAssertNotNil(run.blockquote)
        }
        
        checkAttachment(attributedString: attributedStringFromHTML, expectedRuns: 3)
        checkLinkIn(attributedString: attributedStringFromHTML, expectedLink: link, expectedRuns: 3)
    }
    
    func testAllUsersMentionAtachmentInBlockQuotes() {
        let string = "<blockquote>hello @room how are you?</blockquote>"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            XCTFail("Attributed string is nil")
            return
        }
        
        for run in attributedStringFromHTML.runs {
            XCTAssertNotNil(run.blockquote)
        }
        
        checkAttachment(attributedString: attributedStringFromHTML, expectedRuns: 3)
    }
    
    func testAllUsersMentionAttachment() {
        let string = "@room"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        checkAttachment(attributedString: attributedStringFromHTML, expectedRuns: 1)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        checkAttachment(attributedString: attributedStringFromPlain, expectedRuns: 1)

        let string2 = "Hello @room"
        let attributedStringFromHTML2 = attributedStringBuilder.fromHTML(string2)
        checkAttachment(attributedString: attributedStringFromHTML2, expectedRuns: 2)
        let attributedStringFromPlain2 = attributedStringBuilder.fromPlain(string2)
        checkAttachment(attributedString: attributedStringFromPlain2, expectedRuns: 2)
        
        let string3 = "Hello @room how are you doing?"
        let attributedStringFromHTML3 = attributedStringBuilder.fromHTML(string3)
        checkAttachment(attributedString: attributedStringFromHTML3, expectedRuns: 3)
        let attributedStringFromPlain3 = attributedStringBuilder.fromPlain(string3)
        checkAttachment(attributedString: attributedStringFromPlain3, expectedRuns: 3)
    }
    
    func testLinksHavePriorityOverAllUserMention() {
        let string = "https://test@room.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        checkLinkIn(attributedString: attributedStringFromHTML, expectedLink: string, expectedRuns: 1)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        checkLinkIn(attributedString: attributedStringFromPlain, expectedLink: string, expectedRuns: 1)
        
        let string2 = "https://matrix.to/#/@roomusername:matrix.org"
        let attributedStringFromHTML2 = attributedStringBuilder.fromHTML(string2)
        checkLinkIn(attributedString: attributedStringFromHTML2, expectedLink: string2, expectedRuns: 1)
        checkAttachment(attributedString: attributedStringFromHTML2, expectedRuns: 1)
        let attributedStringFromPlain2 = attributedStringBuilder.fromPlain(string2)
        checkLinkIn(attributedString: attributedStringFromPlain2, expectedLink: string2, expectedRuns: 1)
        checkAttachment(attributedString: attributedStringFromPlain2, expectedRuns: 1)
    }
    
    func testURLsAreIgnoredInCode() {
        var htmlString = "<pre><code>test https://matrix.org test</code></pre>"
        var attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        XCTAssert(attributedStringFromHTML?.runs.count == 1)
        XCTAssertNil(attributedStringFromHTML?.link)
        
        htmlString = "<pre><code>matrix.org</code></pre>"
        attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        XCTAssert(attributedStringFromHTML?.runs.count == 1)
        XCTAssertNil(attributedStringFromHTML?.link)
    }
    
    func testHyperlinksAreIgnoredInCode() {
        let htmlString = "<pre><code>test <a href=\"https://matrix.org\">matrix</a> test</code></pre>"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        XCTAssertNil(attributedStringFromHTML?.link)
    }
    
    func testUserMentionIsIgnoredInCode() {
        let htmlString = "<pre><code>test https://matrix.org/#/@test:matrix.org test</code></pre>"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        XCTAssert(attributedStringFromHTML?.runs.count == 1)
        XCTAssertNil(attributedStringFromHTML?.attachment)
    }
    
    func testPlainTextUserMentionIsIgnoredInCode() {
        let htmlString = "<pre><code>Hey @some.user.ceriu:matrix.org</code></pre>"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        XCTAssert(attributedStringFromHTML?.runs.count == 1)
        XCTAssertNil(attributedStringFromHTML?.attachment)
    }
    
    func testAllUsersIsIgnoredInCode() {
        let htmlString = "<pre><code>test @room test</code></pre>"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        XCTAssert(attributedStringFromHTML?.runs.count == 1)
        XCTAssertNil(attributedStringFromHTML?.attachment)
    }
    
    func testMultipleMentions() {
        guard let url = URL(string: "https://matrix.to/#/@test:matrix.org") else {
            XCTFail("Invalid url")
            return
        }
        
        let string = "Hello @room, but especially hello to you \(url)"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            XCTFail("Attributed string is nil")
            return
        }
        
        var foundAttachments = 0
        var foundLink: URL?
        for run in attributedStringFromHTML.runs {
            if run.attachment != nil {
                foundAttachments += 1
            }
            
            if let link = run.link {
                foundLink = link
            }
        }
        XCTAssertEqual(foundLink, url)
        XCTAssertEqual(foundAttachments, 2)
        
        guard let attributedStringFromPlain = attributedStringBuilder.fromPlain(string) else {
            XCTFail("Attributed string is nil")
            return
        }
        
        foundAttachments = 0
        foundLink = nil
        for run in attributedStringFromPlain.runs {
            if run.attachment != nil {
                foundAttachments += 1
            }
            
            if let link = run.link {
                foundLink = link
            }
        }
        XCTAssertEqual(foundLink, url)
        XCTAssertEqual(foundAttachments, 2)
    }
    
    func testMultipleMentions2() {
        guard let url = URL(string: "https://matrix.to/#/@test:matrix.org") else {
            XCTFail("Invalid url")
            return
        }
        
        let string = "\(url) @room"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            XCTFail("Attributed string is nil")
            return
        }
        
        var foundAttachments = 0
        var foundLink: URL?
        for run in attributedStringFromHTML.runs {
            if run.attachment != nil {
                foundAttachments += 1
            }
            
            if let link = run.link {
                foundLink = link
            }
        }
        XCTAssertEqual(foundLink, url)
        XCTAssertEqual(foundAttachments, 2)
        
        guard let attributedStringFromPlain = attributedStringBuilder.fromPlain(string) else {
            XCTFail("Attributed string is nil")
            return
        }
        
        foundAttachments = 0
        foundLink = nil
        for run in attributedStringFromPlain.runs {
            if run.attachment != nil {
                foundAttachments += 1
            }
            
            if let link = run.link {
                foundLink = link
            }
        }
        XCTAssertEqual(foundLink, url)
        XCTAssertEqual(foundAttachments, 2)
    }

    // MARK: - Private
    
    private func checkLinkIn(attributedString: AttributedString?, expectedLink: String, expectedRuns: Int) {
        guard let attributedString else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, expectedRuns)
        
        for run in attributedString.runs where run.link != nil {
            XCTAssertEqual(run.link?.absoluteString, expectedLink)
            return
        }
        
        XCTFail("Couldn't find expected value.")
    }
    
    private func checkAttachment(attributedString: AttributedString?, expectedRuns: Int) {
        guard let attributedString else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, expectedRuns)
        
        for run in attributedString.runs where run.attachment != nil {
            return
        }
        
        XCTFail("Couldn't find expected value.")
    }
}
