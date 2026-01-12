//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

class AttributedStringBuilderTests: XCTestCase {
    private var attributedStringBuilder: AttributedStringBuilder!
    private let maxHeaderPointSize = ceil(UIFont.preferredFont(forTextStyle: .body).pointSize * 1.2)
    
    override func setUp() async throws {
        attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
    }
    
    func testRenderHTMLStringWithHeaders() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.headers.rawValue) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "H1 Header\n\nH2 Header\n\nH3 Header\n\nH4 Header\n\nH5 Header\n\nH6 Header")
        
        XCTAssertEqual(attributedString.runs.count, 11) // newlines hold no attributes
        
        let pointSizes = attributedString.runs.compactMap(\.uiKit.font?.pointSize)
        XCTAssertEqual(pointSizes, [23, 23, 23, 21, 19, 17])
    }
    
    func testRenderHTMLStringWithPreCode() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.codeBlocks.rawValue) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.first?.uiKit.font?.fontName, ".AppleSystemUIFontMonospaced-Regular")
        
        let string = String(attributedString.characters)
        
        guard let regex = try? NSRegularExpression(pattern: "\\R", options: []) else {
            XCTFail("Could not build the regex for the test.")
            return
        }
        
        XCTAssertEqual(regex.numberOfMatches(in: string, options: [], range: .init(location: 0, length: string.count)), 18)
    }
    
    func testRenderHTMLStringWithLink() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.links.rawValue) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Links too:\nMatrix rules! 🤘, beta.org, www.gamma.org, http://delta.org")
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        
        XCTAssertEqual(link?.host, "www.alpha.org")
    }
    
    func testRenderPlainStringWithLink() {
        let plainString = "This text contains a https://www.matrix.org link."
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), plainString)
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        
        XCTAssertEqual(link?.host, "www.matrix.org")
    }
    
    func testPunctuationAtTheEndOfPlainStringLinks() {
        let plainString = "Most punctuation marks are removed https://www.matrix.org:;., but closing brackets are kept https://example.com/(test)"
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), plainString)
        
        XCTAssertEqual(attributedString.runs.count, 4)
        
        let firstLink = attributedString.runs.first { $0.link != nil }?.link
        XCTAssertEqual(firstLink, "https://www.matrix.org")
        let secondLink = attributedString.runs.last { $0.link != nil }?.link
        XCTAssertEqual(secondLink, "https://example.com/(test)")
    }
    
    func testLinkDefaultScheme() {
        let plainString = "This text contains a matrix.org link."
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), plainString)
        
        XCTAssertEqual(attributedString.runs.count, 3)
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        
        XCTAssertEqual(link, "https://matrix.org")
    }
    
    func testMailToLinks() {
        let plainString = "Linking to email addresses like stefan@matrix.org should work as well"
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        XCTAssertEqual(link, "mailto:stefan@matrix.org")
    }
    
    func testRenderHTMLStringWithLinkInHeader() {
        let h1HTMLString = "<h1><a href=\"https://matrix.org/\">Matrix.org</a></h1>"
        let h2HTMLString = "<h2><a href=\"https://matrix.org/\">Matrix.org</a></h2>"
        let h3HTMLString = "<h3><a href=\"https://matrix.org/\">Matrix.org</a></h3>"
        
        guard let h1AttributedString = attributedStringBuilder.fromHTML(h1HTMLString),
              let h2AttributedString = attributedStringBuilder.fromHTML(h2HTMLString),
              let h3AttributedString = attributedStringBuilder.fromHTML(h3HTMLString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        guard let h1Font = h1AttributedString.runs.first?.uiKit.font,
              let h2Font = h2AttributedString.runs.first?.uiKit.font,
              let h3Font = h3AttributedString.runs.first?.uiKit.font else {
            XCTFail("Could not extract a font from the strings.")
            return
        }
        
        XCTAssertEqual(String(h1AttributedString.characters), "Matrix.org")
        XCTAssertEqual(String(h2AttributedString.characters), "Matrix.org")
        XCTAssertEqual(String(h3AttributedString.characters), "Matrix.org")
        
        XCTAssertEqual(h1AttributedString.runs.count, 1)
        XCTAssertEqual(h2AttributedString.runs.count, 1)
        XCTAssertEqual(h3AttributedString.runs.count, 1)
        
        XCTAssertEqual(h1Font, h2Font)
        XCTAssertEqual(h2Font, h3Font)
        
        XCTAssert(h1Font.pointSize > UIFont.preferredFont(forTextStyle: .body).pointSize)
        XCTAssert(h1Font.pointSize <= 23)
        
        XCTAssertEqual(h1AttributedString.runs.first?.link?.host, "matrix.org")
        XCTAssertEqual(h2AttributedString.runs.first?.link?.host, "matrix.org")
        XCTAssertEqual(h3AttributedString.runs.first?.link?.host, "matrix.org")
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
        
    func testDefaultFont() {
        let htmlString = "<b>Test</b> <i>string</i> "
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 3)
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
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.groupedBlockQuotes.rawValue) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 11)
        XCTAssertEqual(attributedString.formattedComponents.count, 5)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            numberOfBlockquotes += 1
        }
        
        XCTAssertEqual(numberOfBlockquotes, 3, "Couldn't find all the blockquotes")
    }
    
    func testMultipleSeparatedBlockquotes() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.separatedBlockQuotes.rawValue) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        let coalescedComponents = attributedString.formattedComponents
        
        XCTAssertEqual(attributedString.runs.count, 5)
        XCTAssertEqual(coalescedComponents.count, 5)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            numberOfBlockquotes += 1
        }
        
        XCTAssertEqual(numberOfBlockquotes, 2, "Couldn't find all the blockquotes")
    }
    
    func testUserPermalinkMentionAtachment() {
        let string = "https://matrix.to/#/@test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.userID, "@test:matrix.org")
        XCTAssertEqual(attributedStringFromHTML?.link?.absoluteString, string)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertEqual(attributedStringFromPlain?.userID, "@test:matrix.org")
        XCTAssertEqual(attributedStringFromPlain?.link?.absoluteString, string)
    }
    
    func testUserIDMentionAtachment() {
        let string = "@test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.userID, "@test:matrix.org")
        XCTAssertEqual(attributedStringFromHTML?.link?.absoluteString, "https://matrix.to/#/@test:matrix.org")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertEqual(attributedStringFromPlain?.userID, "@test:matrix.org")
        XCTAssertEqual(attributedStringFromPlain?.link?.absoluteString, "https://matrix.to/#/@test:matrix.org")
    }
    
    func testRoomIDPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/!test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.roomID, "!test:matrix.org")
        XCTAssertEqual(attributedStringFromHTML?.link?.absoluteString, string)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.roomID, "!test:matrix.org")
        XCTAssertEqual(attributedStringFromPlain?.link?.absoluteString, string)
    }
    
    func testRoomAliasPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/#test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.roomAlias, "#test:matrix.org")
        XCTAssertEqual(attributedStringFromHTML?.link?.absoluteString, "https://matrix.to/#/%23test:matrix.org")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.roomAlias, "#test:matrix.org")
        XCTAssertEqual(attributedStringFromPlain?.link?.absoluteString, "https://matrix.to/#/%23test:matrix.org")
    }
    
    func testRoomAliasMentionAttachment() {
        let string = "#test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.roomAlias, "#test:matrix.org")
        XCTAssertEqual(attributedStringFromHTML?.link?.absoluteString, "https://matrix.to/#/%23test:matrix.org")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.roomAlias, "#test:matrix.org")
        XCTAssertEqual(attributedStringFromPlain?.link?.absoluteString, "https://matrix.to/#/%23test:matrix.org")
    }
    
    func testEventRoomIDPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/!test:matrix.org/$test"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.eventOnRoomID, .some(.init(roomID: "!test:matrix.org", eventID: "$test")))
        XCTAssertEqual(attributedStringFromHTML?.link?.absoluteString, string)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertEqual(attributedStringFromPlain?.eventOnRoomID, .some(.init(roomID: "!test:matrix.org", eventID: "$test")))
        XCTAssertEqual(attributedStringFromPlain?.link?.absoluteString, string)
    }
    
    func testEventRoomAliasPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/#test:matrix.org/$test"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        XCTAssertNotNil(attributedStringFromHTML?.attachment)
        XCTAssertEqual(attributedStringFromHTML?.eventOnRoomAlias, .some(.init(alias: "#test:matrix.org", eventID: "$test")))
        XCTAssertEqual(attributedStringFromHTML?.link?.absoluteString, "https://matrix.to/#/%23test:matrix.org/$test")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        XCTAssertNotNil(attributedStringFromPlain?.attachment)
        XCTAssertEqual(attributedStringFromPlain?.eventOnRoomAlias, .some(.init(alias: "#test:matrix.org", eventID: "$test")))
        XCTAssertEqual(attributedStringFromPlain?.link?.absoluteString, "https://matrix.to/#/%23test:matrix.org/$test")
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
        let attributedString = attributedStringBuilder.fromHTML(htmlString)
        
        XCTAssert(attributedString?.runs.count == 1)
        
        XCTAssertNil(attributedString?.attachment)
    }
    
    func testPlainTextUserMentionIsIgnoredInCode() {
        let htmlString = "<pre><code>Hey @some.user.ceriu:matrix.org</code></pre>"
        let attributedString = attributedStringBuilder.fromHTML(htmlString)
        
        XCTAssert(attributedString?.runs.count == 1)
        
        XCTAssertNil(attributedString?.attachment)
    }
    
    func testAllUsersIsIgnoredInCode() {
        let htmlString = "<pre><code>test @room test</code></pre>"
        let attributedString = attributedStringBuilder.fromHTML(htmlString)
        
        XCTAssert(attributedString?.runs.count == 1)
        
        XCTAssertNil(attributedString?.attachment)
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
    
    func testImageTags() {
        let htmlString = "Hey <img src=\"smiley.gif\" alt=\"Smiley face\">! How's work<img src=\"workplace.jpg\">?"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey [img: Smiley face]! How's work[img]?")
    }
    
    func testListTags() {
        let htmlString = "<p>like</p>\n<ul>\n<li>this<br />\ntest</li>\n</ul>\n"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "like\n\n   • this\ntest")
    }
    
    func testUnorderedList() {
        let htmlString = "<ul><li>1</li><li>2</li><li>3</li></ul>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "  • 1\n  • 2\n  • 3")
    }
    
    func testNestedUnorderedList() {
        let htmlString = "<ul><li>A<ul><li>A1</li><li>A2</li><li>A3</li></ul></li><li>B</li><li>C</li></ul>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "  • A\n      • A1\n      • A2\n      • A3\n  • B\n  • C")
    }
    
    func testOrderedList() {
        let htmlString = "<ol><li>1</li><li>2</li><li>3</li></ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "  1. 1\n  2. 2\n  3. 3")
    }
    
    func testNestedOrderedList() {
        let htmlString = "<ol><li>A<ol><li>A1</li><li>A2</li><li>A3</li></ol></li><li>B</li><li>C</li></ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "  1. A\n      1. A1\n      2. A2\n      3. A3\n  2. B\n  3. C")
    }
    
    func testOutOfOrderListNubmering() {
        let htmlString = "<ol start=\"2\">\n<li>this is a two</li>\n</ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "   2. this is a two")
    }
    
    func testNestedHeterogeneousLists() {
        let htmlString = "<ol><li>A<ul><li>A1</li><li>A2</li><li>A3</li></ul></li><li>B</li><li>C</li></ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "  1. A\n      • A1\n      • A2\n      • A3\n  2. B\n  3. C")
    }
    
    // MARK: - Phishing prevention
    
    func testPhishingLink() {
        let htmlString = "Hey check the following link <a href=\"https://matrix.org\">https://element.io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following link https://element.io")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "https://element.io")
    }
    
    func testValidLink() {
        let htmlString = "Hey check the following <a href=\"https://matrix.org\">link</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
                
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertFalse(link.requiresConfirmation)
        XCTAssertEqual(link.absoluteString, "https://matrix.org")
    }
    
    func testValidLinkWithRTLOverride() {
        let htmlString = "<a href=\"https://matrix.org\">\u{202E}https://matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
                
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertFalse(link.requiresConfirmation)
        XCTAssertEqual(link.absoluteString, "https://matrix.org")
    }
    
    func testPhishingUserID() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.org\">@alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following user @alice:matrix.org")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "@alice:matrix.org")
    }
    
    func testValidUserIDLink() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.to/#/@alice:matrix.org\">@alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        checkAttachment(attributedString: attributedString, expectedRuns: 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertFalse(link.requiresConfirmation)
        XCTAssertEqual(link.absoluteString, "https://matrix.to/#/@alice:matrix.org")
    }
    
    func testPhishingUserIDWithAnotherUserIDPermalink() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.to/#/@bob:matrix.org\">@alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following user @alice:matrix.org")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.to/#/@bob:matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "@alice:matrix.org")
    }
    
    func testPhishingUserIDWithDistractingCharacters() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.org\">👉️ @alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following user 👉️ @alice:matrix.org")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "👉️ @alice:matrix.org")
    }
    
    func testPhishingLinkWithDistractingCharacters() {
        let htmlString = "Hey check the following link <a href=\"https://matrix.org\">👉️ https://element.io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following link 👉️ https://element.io")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "👉️ https://element.io")
    }
    
    func testValidLinkWithDistractingCharacters() {
        let htmlString = "Hey check the following link <a href=\"https://element.io\">👉️ https://element.io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        XCTAssertEqual(String(attributedString.characters), "Hey check the following link 👉️ https://element.io")
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        
        XCTAssertFalse(link.requiresConfirmation)
        XCTAssertEqual(link.absoluteString, "https://element.io")
    }
    
    func testPhishingLinkWithFakeDotCharacter() {
        let htmlString = "Hey check the following link <a href=\"https://matrix.org\">https://element﹒io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following link https://element﹒io")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "https://element﹒io")
    }
    
    func testPhishingMatrixPermalinks() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.to/#/#offensive-room:matrix.org\">https://matrix.to/#/#beautiful-room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.to/#/%23offensive-room:matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "https://matrix.to/#/#beautiful-room:matrix.org")
    }
    
    func testValidMatrixPermalinks() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.to/#/#beautiful-room:matrix.org\">https://matrix.to/#/#beautiful-room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        checkAttachment(attributedString: attributedString, expectedRuns: 2)
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        
        XCTAssertFalse(link.requiresConfirmation)
        XCTAssertEqual(link.absoluteString, "https://matrix.to/#/%23beautiful-room:matrix.org")
    }
    
    func testPhishingRoomAlias() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.org\">#room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following room #room:matrix.org")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "#room:matrix.org")
    }
    
    func testValidRoomAliasLink() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.to/#/#room:matrix.org\">#room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        checkAttachment(attributedString: attributedString, expectedRuns: 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertFalse(link.requiresConfirmation)
        XCTAssertEqual(link.absoluteString, "https://matrix.to/#/%23room:matrix.org")
    }
    
    func testPhishingRoomAliasWithAnotherRoomAliasPermalink() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.to/#/#another-room:matrix.org\">#room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following room #room:matrix.org")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.to/#/%23another-room:matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "#room:matrix.org")
    }
    
    func testRoomAliasWithDistractingCharacters() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.org\">👉️ #room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "Hey check the following user 👉️ #room:matrix.org")
        
        XCTAssertEqual(attributedString.runs.count, 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            XCTFail("Couldn't find the link")
            return
        }
        XCTAssertTrue(link.requiresConfirmation)
        XCTAssertEqual(link.confirmationParameters?.internalURL.absoluteString, "https://matrix.org")
        XCTAssertEqual(link.confirmationParameters?.displayString, "👉️ #room:matrix.org")
    }

    func testMxExternalPaymentDetailsRemoved() {
        var htmlString = "This is visible.<span data-msc4286-external-payment-details> But this is hidden <a href=\"https://matrix.org\">and this link too</a></span>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "This is visible.")
        
        for run in attributedString.runs where run.link != nil {
            XCTFail("No link expected, but found one")
            return
        }
        
        htmlString = "This is visible.<span> And this text <a href=\"https://matrix.org\">and link</a> are visible too.</span>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            XCTFail("Could not build the attributed string")
            return
        }
        
        XCTAssertEqual(String(attributedString.characters), "This is visible. And this text and link are visible too.")
        
        guard attributedString.runs.first(where: { $0.link != nil })?.link != nil else {
            XCTFail("Couldn't find the link")
            return
        }
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
