//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
struct AttributedStringBuilderTests {
    private var attributedStringBuilder: AttributedStringBuilder!
    private let maxHeaderPointSize = ceil(UIFont.preferredFont(forTextStyle: .body).pointSize * 1.2)
    
    init() async throws {
        attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
    }
    
    @Test
    func renderHTMLStringWithHeaders() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.headers.rawValue) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "H1 Header\nH2 Header\nH3 Header\nH4 Header\nH5 Header\nH6 Header")
        
        #expect(attributedString.runs.count == 4) // newlines hold no attributes
        
        let pointSizes = attributedString.runs.compactMap(\.uiKit.font?.pointSize)
        #expect(pointSizes == [23, 21, 19, 17])
    }
    
    @Test
    func renderHTMLStringWithPreCode() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.code.rawValue) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.first?.uiKit.font?.fontName == ".AppleSystemUIFontMonospaced-Regular")
        
        let string = String(attributedString.characters)
        
        guard let regex = try? NSRegularExpression(pattern: "\\R", options: []) else {
            Issue.record("Could not build the regex for the test.")
            return
        }
        
        #expect(regex.numberOfMatches(in: string, options: [], range: .init(location: 0, length: string.count)) == 23)
    }
    
    @Test
    func renderHTMLStringWithLink() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.links.rawValue) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Links too:\nMatrix rules! 🤘, beta.org, www.gamma.org, http://delta.org")
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        
        #expect(link?.host == "www.alpha.org")
    }
    
    @Test
    func renderPlainStringWithLink() {
        let plainString = "This text contains a https://www.matrix.org link."
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == plainString)
        
        #expect(attributedString.runs.count == 3)
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        
        #expect(link?.host == "www.matrix.org")
    }
    
    @Test
    func punctuationAtTheEndOfPlainStringLinks() {
        let plainString = "Most punctuation marks are removed https://www.matrix.org:;., but closing brackets are kept https://example.com/(test)"
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == plainString)
        
        #expect(attributedString.runs.count == 4)
        
        let firstLink = attributedString.runs.first { $0.link != nil }?.link
        #expect(firstLink == "https://www.matrix.org")
        let secondLink = attributedString.runs.last { $0.link != nil }?.link
        #expect(secondLink == "https://example.com/(test)")
    }
    
    @Test
    func linkDefaultScheme() {
        let plainString = "This text contains a matrix.org link."
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == plainString)
        
        #expect(attributedString.runs.count == 3)
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        
        #expect(link == "https://matrix.org")
    }
    
    @Test
    func mailToLinks() {
        let plainString = "Linking to email addresses like stefan@matrix.org should work as well"
        
        guard let attributedString = attributedStringBuilder.fromPlain(plainString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        let link = attributedString.runs.first { $0.link != nil }?.link
        #expect(link == "mailto:stefan@matrix.org")
    }
    
    @Test
    func renderHTMLStringWithLinkInHeader() {
        let h1HTMLString = "<h1><a href=\"https://matrix.org/\">Matrix.org</a></h1>"
        let h2HTMLString = "<h2><a href=\"https://matrix.org/\">Matrix.org</a></h2>"
        let h3HTMLString = "<h3><a href=\"https://matrix.org/\">Matrix.org</a></h3>"
        
        guard let h1AttributedString = attributedStringBuilder.fromHTML(h1HTMLString),
              let h2AttributedString = attributedStringBuilder.fromHTML(h2HTMLString),
              let h3AttributedString = attributedStringBuilder.fromHTML(h3HTMLString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        guard let h1Font = h1AttributedString.runs.first?.uiKit.font,
              let h2Font = h2AttributedString.runs.first?.uiKit.font,
              let h3Font = h3AttributedString.runs.first?.uiKit.font else {
            Issue.record("Could not extract a font from the strings.")
            return
        }
        
        #expect(String(h1AttributedString.characters) == "Matrix.org")
        #expect(String(h2AttributedString.characters) == "Matrix.org")
        #expect(String(h3AttributedString.characters) == "Matrix.org")
        
        #expect(h1AttributedString.runs.count == 1)
        #expect(h2AttributedString.runs.count == 1)
        #expect(h3AttributedString.runs.count == 1)
        
        #expect(h1Font == h2Font)
        #expect(h2Font == h3Font)
        
        #expect(h1Font.pointSize > UIFont.preferredFont(forTextStyle: .body).pointSize)
        #expect(h1Font.pointSize <= 23)
        
        #expect(h1AttributedString.runs.first?.link?.host == "matrix.org")
        #expect(h2AttributedString.runs.first?.link?.host == "matrix.org")
        #expect(h3AttributedString.runs.first?.link?.host == "matrix.org")
    }
    
    @Test
    func renderHTMLStringWithIFrame() {
        let htmlString = "<iframe src=\"https://www.matrix.org/\"></iframe>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.uiKit.attachment == nil)
    }
    
    @Test
    func linkWithFragment() {
        var string = "https://example.com/#/"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: "https://example.com", expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: "https://example.com", expectedRuns: 1)
        
        string = "https://example.com/#/some_fragment/"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: "https://example.com/#/some_fragment", expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: "https://example.com/#/some_fragment", expectedRuns: 1)
    }
    
    @Test
    func permalink() {
        let string = "https://matrix.to/#/!hello:matrix.org/$world?via=matrix.org"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: string, expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: string, expectedRuns: 1)
    }
    
    @Test
    func matrixURI() {
        let string = "matrix:roomid/hello:matrix.org/e/world?via=matrix.org"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: string, expectedRuns: 1)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: string, expectedRuns: 1)
    }
    
    @Test
    func userIDLink() {
        let userID = "@user:matrix.org"
        let string = "The user is \(userID)."
        let expectedLink = "https://matrix.to/#/\(userID)"
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: expectedLink, expectedRuns: 3)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: expectedLink, expectedRuns: 3)
    }
    
    @Test
    func roomAliasLink() {
        let roomAlias = "#room:matrix.org"
        let string = "The room is \(roomAlias)."
        guard let expectedLink = URL(string: "https://matrix.to/#/\(roomAlias)") else {
            Issue.record("The expected link should be valid.")
            return
        }
        checkLinkIn(attributedString: attributedStringBuilder.fromHTML(string), expectedLink: expectedLink.absoluteString, expectedRuns: 3)
        checkLinkIn(attributedString: attributedStringBuilder.fromPlain(string), expectedLink: expectedLink.absoluteString, expectedRuns: 3)
    }
    
    @Test
    func defaultFont() {
        let htmlString = "<b>Test</b> <i>string</i> "
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 3)
    }
    
    @Test
    func defaultForegroundColor() {
        let htmlString = "<b>Test</b> <i>string</i> <a href=\"https://www.matrix.org/\">link</a> <code><a href=\"https://www.matrix.org/\">link</a></code>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 7)
        
        for run in attributedString.runs {
            #expect(run.uiKit.foregroundColor == nil)
        }
    }
    
    @Test
    func customForegroundColor() {
        // swiftlint:disable:next line_length
        let htmlString = "<font color=\"#ff00be\">R</font><font color=\"#ff0082\">a</font><font color=\"#ff0047\">i</font><font color=\"#ff5800\">n </font><font color=\"#ffa300\">w</font><font color=\"#d2ba00\">w</font><font color=\"#97ca00\">w</font><font color=\"#3ed500\">.</font><font color=\"#00dd00\">m</font><font color=\"#00e251\">a</font><font color=\"#00e595\">t</font><font color=\"#00e7d6\">r</font><font color=\"#00e7ff\">i</font><font color=\"#00e6ff\">x</font><font color=\"#00e3ff\">.</font><font color=\"#00dbff\">o</font><font color=\"#00ceff\">r</font><font color=\"#00baff\">g</font><font color=\"#f477ff\"> b</font><font color=\"#ff3aff\">o</font><font color=\"#ff00fb\">w</font>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 3)
        
        var foundLink = false
        // Foreground colors should be completely stripped from the attributed string
        // letting UI components chose the defaults (e.g. tintColor)
        for run in attributedString.runs {
            if run.link != nil {
                #expect(run.link?.host == "www.matrix.org")
                #expect(run.uiKit.foregroundColor == nil)
                foundLink = true
            } else {
                #expect(run.uiKit.foregroundColor == nil)
            }
        }
        
        #expect(foundLink)
    }
    
    @Test
    func singleBlockquote() {
        let htmlString = "<blockquote>Blockquote</blockquote><p>Another paragraph</p>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 2)
        
        #expect(attributedString.formattedComponents.count == 2)
        
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            return
        }
        
        Issue.record("Couldn't find blockquote")
        
        #expect(String(attributedString.characters) == "Blockquote\nAnother paragraph")
    }
    
    // swiftlint:disable line_length
    @Test
    func blockquoteWithinText() {
        let htmlString = """
        The text before the blockquote
        <blockquote> For 50 years, WWF has been protecting the future of nature. The world's leading conservation organization, WWF works in 100 countries and is supported by 1.2 million members in the United States and close to 5 million globally.</blockquote>
        The text after the blockquote
        """
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 3)
        
        #expect(attributedString.formattedComponents.count == 3)
        
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            return
        }
        
        Issue.record("Couldn't find blockquote")
    }
    
    // swiftlint:enable line_length
    
    @Test
    func blockquoteWithLink() {
        let htmlString = "<blockquote>Blockquote with a <a href=\"https://www.matrix.org/\">link</a> in it</blockquote>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 3)
        
        let coalescedComponents = attributedString.formattedComponents
        
        #expect(coalescedComponents.count == 1)
        
        #expect(coalescedComponents.first?.attributedString.runs.count == 3, "Link not present in the component")
        
        var foundBlockquoteAndLink = false
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            foundBlockquoteAndLink = true
        }
        
        #expect(foundBlockquoteAndLink != nil)
    }
    
    @Test
    func replyBlockquote() {
        let htmlString = "<blockquote><a href=\"https://matrix.to/#/someroom/someevent\">In reply to</a> <a href=\"https://matrix.to/#/@user:matrix.org\">@user:matrix.org</a><br>The future is <code>swift run tools</code> 😎</blockquote>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        let coalescedComponents = attributedString.formattedComponents
        #expect(coalescedComponents.count == 1)
        
        guard let component = coalescedComponents.first else {
            Issue.record("Could not get the first component")
            return
        }
        
        #expect(component.type == .blockquote, "The reply quote should be a blockquote.")
    }
    
    @Test
    func multipleGroupedBlockquotes() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.groupedBlockQuotes.rawValue) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 11)
        #expect(attributedString.formattedComponents.count == 5)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false && run.link != nil {
            numberOfBlockquotes += 1
        }
        
        #expect(numberOfBlockquotes == 3, "Couldn't find all the blockquotes")
    }
    
    @Test
    func multipleSeparatedBlockquotes() {
        guard let attributedString = attributedStringBuilder.fromHTML(HTMLFixtures.separatedBlockQuotes.rawValue) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        let coalescedComponents = attributedString.formattedComponents
        
        #expect(attributedString.runs.count == 5)
        #expect(coalescedComponents.count == 5)
        
        var numberOfBlockquotes = 0
        for run in attributedString.runs where run.elementX.blockquote ?? false {
            numberOfBlockquotes += 1
        }
        
        #expect(numberOfBlockquotes == 2, "Couldn't find all the blockquotes")
    }
    
    @Test
    func userPermalinkMentionAtachment() {
        let string = "https://matrix.to/#/@test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        #expect(attributedStringFromHTML?.attachment != nil)
        #expect(attributedStringFromHTML?.userID == "@test:matrix.org")
        #expect(attributedStringFromHTML?.link?.absoluteString == string)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        #expect(attributedStringFromPlain?.attachment != nil)
        #expect(attributedStringFromPlain?.userID == "@test:matrix.org")
        #expect(attributedStringFromPlain?.link?.absoluteString == string)
    }
    
    @Test
    func userIDMentionAtachment() {
        let string = "@test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        #expect(attributedStringFromHTML?.attachment != nil)
        #expect(attributedStringFromHTML?.userID == "@test:matrix.org")
        #expect(attributedStringFromHTML?.link?.absoluteString == "https://matrix.to/#/@test:matrix.org")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        #expect(attributedStringFromPlain?.attachment != nil)
        #expect(attributedStringFromPlain?.userID == "@test:matrix.org")
        #expect(attributedStringFromPlain?.link?.absoluteString == "https://matrix.to/#/@test:matrix.org")
    }
    
    @Test
    func roomIDPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/!test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        #expect(attributedStringFromHTML?.attachment != nil)
        #expect(attributedStringFromHTML?.roomID == "!test:matrix.org")
        #expect(attributedStringFromHTML?.link?.absoluteString == string)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        #expect(attributedStringFromPlain?.attachment != nil)
        #expect(attributedStringFromHTML?.roomID == "!test:matrix.org")
        #expect(attributedStringFromPlain?.link?.absoluteString == string)
    }
    
    @Test
    func roomAliasPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/#test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        #expect(attributedStringFromHTML?.attachment != nil)
        #expect(attributedStringFromHTML?.roomAlias == "#test:matrix.org")
        #expect(attributedStringFromHTML?.link?.absoluteString == "https://matrix.to/#/%23test:matrix.org")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        #expect(attributedStringFromPlain?.attachment != nil)
        #expect(attributedStringFromHTML?.roomAlias == "#test:matrix.org")
        #expect(attributedStringFromPlain?.link?.absoluteString == "https://matrix.to/#/%23test:matrix.org")
    }
    
    @Test
    func roomAliasMentionAttachment() {
        let string = "#test:matrix.org"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        #expect(attributedStringFromHTML?.attachment != nil)
        #expect(attributedStringFromHTML?.roomAlias == "#test:matrix.org")
        #expect(attributedStringFromHTML?.link?.absoluteString == "https://matrix.to/#/%23test:matrix.org")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        #expect(attributedStringFromPlain?.attachment != nil)
        #expect(attributedStringFromHTML?.roomAlias == "#test:matrix.org")
        #expect(attributedStringFromPlain?.link?.absoluteString == "https://matrix.to/#/%23test:matrix.org")
    }
    
    @Test
    func eventRoomIDPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/!test:matrix.org/$test"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        #expect(attributedStringFromHTML?.attachment != nil)
        #expect(attributedStringFromHTML?.eventOnRoomID == .some(.init(roomID: "!test:matrix.org", eventID: "$test")))
        #expect(attributedStringFromHTML?.link?.absoluteString == string)
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        #expect(attributedStringFromPlain?.attachment != nil)
        #expect(attributedStringFromPlain?.eventOnRoomID == .some(.init(roomID: "!test:matrix.org", eventID: "$test")))
        #expect(attributedStringFromPlain?.link?.absoluteString == string)
    }
    
    @Test
    func eventRoomAliasPermalinkMentionAttachment() {
        let string = "https://matrix.to/#/#test:matrix.org/$test"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(string)
        #expect(attributedStringFromHTML?.attachment != nil)
        #expect(attributedStringFromHTML?.eventOnRoomAlias == .some(.init(alias: "#test:matrix.org", eventID: "$test")))
        #expect(attributedStringFromHTML?.link?.absoluteString == "https://matrix.to/#/%23test:matrix.org/$test")
        let attributedStringFromPlain = attributedStringBuilder.fromPlain(string)
        #expect(attributedStringFromPlain?.attachment != nil)
        #expect(attributedStringFromPlain?.eventOnRoomAlias == .some(.init(alias: "#test:matrix.org", eventID: "$test")))
        #expect(attributedStringFromPlain?.link?.absoluteString == "https://matrix.to/#/%23test:matrix.org/$test")
    }
    
    @Test
    func userMentionAtachmentInBlockQuotes() {
        let link = "https://matrix.to/#/@test:matrix.org"
        let string = "<blockquote>hello \(link) how are you?</blockquote>"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            Issue.record("Attributed string is nil")
            return
        }
        
        for run in attributedStringFromHTML.runs {
            #expect(run.blockquote != nil)
        }
        
        checkAttachment(attributedString: attributedStringFromHTML, expectedRuns: 3)
        checkLinkIn(attributedString: attributedStringFromHTML, expectedLink: link, expectedRuns: 3)
    }
    
    @Test
    func allUsersMentionAtachmentInBlockQuotes() {
        let string = "<blockquote>hello @room how are you?</blockquote>"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            Issue.record("Attributed string is nil")
            return
        }
        
        for run in attributedStringFromHTML.runs {
            #expect(run.blockquote != nil)
        }
        
        checkAttachment(attributedString: attributedStringFromHTML, expectedRuns: 3)
    }
    
    @Test
    func allUsersMentionAttachment() {
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
    
    @Test
    func linksHavePriorityOverAllUserMention() {
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
    
    @Test
    func uRLsAreIgnoredInCode() {
        var htmlString = "<pre><code>test https://matrix.org test</code></pre>"
        var attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        #expect(attributedStringFromHTML?.runs.count == 1)
        #expect(attributedStringFromHTML?.link == nil)
        
        htmlString = "<pre><code>matrix.org</code></pre>"
        attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        #expect(attributedStringFromHTML?.runs.count == 1)
        #expect(attributedStringFromHTML?.link == nil)
    }
    
    @Test
    func hyperlinksAreIgnoredInCode() {
        let htmlString = "<pre><code>test <a href=\"https://matrix.org\">matrix</a> test</code></pre>"
        let attributedStringFromHTML = attributedStringBuilder.fromHTML(htmlString)
        #expect(attributedStringFromHTML?.link == nil)
    }
    
    @Test
    func userMentionIsIgnoredInCode() {
        let htmlString = "<pre><code>test https://matrix.org/#/@test:matrix.org test</code></pre>"
        let attributedString = attributedStringBuilder.fromHTML(htmlString)
        
        #expect(attributedString?.runs.count == 1)
        
        #expect(attributedString?.attachment == nil)
    }
    
    @Test
    func plainTextUserMentionIsIgnoredInCode() {
        let htmlString = "<pre><code>Hey @some.user.ceriu:matrix.org</code></pre>"
        let attributedString = attributedStringBuilder.fromHTML(htmlString)
        
        #expect(attributedString?.runs.count == 1)
        
        #expect(attributedString?.attachment == nil)
    }
    
    @Test
    func allUsersIsIgnoredInCode() {
        let htmlString = "<pre><code>test @room test</code></pre>"
        let attributedString = attributedStringBuilder.fromHTML(htmlString)
        
        #expect(attributedString?.runs.count == 1)
        
        #expect(attributedString?.attachment == nil)
    }
    
    @Test
    func multipleMentions() {
        guard let url = URL(string: "https://matrix.to/#/@test:matrix.org") else {
            Issue.record("Invalid url")
            return
        }
        
        let string = "Hello @room, but especially hello to you \(url)"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            Issue.record("Attributed string is nil")
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
        #expect(foundLink == url)
        #expect(foundAttachments == 2)
        
        guard let attributedStringFromPlain = attributedStringBuilder.fromPlain(string) else {
            Issue.record("Attributed string is nil")
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
        #expect(foundLink == url)
        #expect(foundAttachments == 2)
    }
    
    @Test
    func multipleMentions2() {
        guard let url = URL(string: "https://matrix.to/#/@test:matrix.org") else {
            Issue.record("Invalid url")
            return
        }
        
        let string = "\(url) @room"
        guard let attributedStringFromHTML = attributedStringBuilder.fromHTML(string) else {
            Issue.record("Attributed string is nil")
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
        #expect(foundLink == url)
        #expect(foundAttachments == 2)
        
        guard let attributedStringFromPlain = attributedStringBuilder.fromPlain(string) else {
            Issue.record("Attributed string is nil")
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
        #expect(foundLink == url)
        #expect(foundAttachments == 2)
    }
    
    @Test
    func imageTags() {
        let htmlString = "Hey <img src=\"smiley.gif\" alt=\"Smiley face\">! How's work<img src=\"workplace.jpg\">?"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey [img: Smiley face]! How's work[img]?")
    }
    
    @Test
    func listTags() {
        let htmlString = "<p>like</p>\n<ul>\n<li>this<br />\ntest</li>\n</ul>\n"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "like\n    • this\ntest")
    }
    
    @Test
    func unorderedList() {
        let htmlString = "<ul><li>1</li><li>2</li><li>3</li></ul>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "  • 1\n  • 2\n  • 3")
    }
    
    @Test
    func nestedUnorderedList() {
        let htmlString = "<ul><li>A<ul><li>A1</li><li>A2</li><li>A3</li></ul></li><li>B</li><li>C</li></ul>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "  • A\n      • A1\n      • A2\n      • A3\n  • B\n  • C")
    }
    
    @Test
    func orderedList() {
        let htmlString = "<ol><li>1</li><li>2</li><li>3</li></ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "  1. 1\n  2. 2\n  3. 3")
    }
    
    @Test
    func nestedOrderedList() {
        let htmlString = "<ol><li>A<ol><li>A1</li><li>A2</li><li>A3</li></ol></li><li>B</li><li>C</li></ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "  1. A\n      1. A1\n      2. A2\n      3. A3\n  2. B\n  3. C")
    }
    
    @Test
    func outOfOrderListNubmering() {
        let htmlString = "<ol start=\"2\">\n<li>this is a two</li>\n</ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "   2. this is a two")
    }
    
    @Test
    func nestedHeterogeneousLists() {
        let htmlString = "<ol><li>A<ul><li>A1</li><li>A2</li><li>A3</li></ul></li><li>B</li><li>C</li></ol>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "  1. A\n      • A1\n      • A2\n      • A3\n  2. B\n  3. C")
    }
    
    /// https://github.com/element-hq/element-x-ios/issues/4856
    @Test
    func normalisedWhitespaces() {
        let html = """
        <a href="https://github.com/stefan">Stefan</a>      pushed
                <a href="https://github.com">2 commits</a>
            to
         main:<ul>         <li>
                    <a href="https://github.com"><code>Some update</code></a>
                    
                </li>
                <li>
                    <a href="https://github.com"><code>Some other update</code></a>
                    
                </li>
         </ul>
        """
        guard let attributedString = attributedStringBuilder.fromHTML(html) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Stefan pushed 2 commits to main:\n   •  Some update \n   •  Some other update")
    }
    
    // MARK: - Phishing prevention
    
    @Test
    func phishingLink() {
        let htmlString = "Hey check the following link <a href=\"https://matrix.org\">https://element.io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following link https://element.io")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.org")
        #expect(link.confirmationParameters?.displayString == "https://element.io")
    }
    
    @Test
    func validLink() {
        let htmlString = "Hey check the following <a href=\"https://matrix.org\">link</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(!link.requiresConfirmation)
        #expect(link.absoluteString == "https://matrix.org")
    }
    
    @Test
    func validLinkWithRTLOverride() {
        let htmlString = "<a href=\"https://matrix.org\">\u{202E}https://matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(!link.requiresConfirmation)
        #expect(link.absoluteString == "https://matrix.org")
    }
    
    @Test
    func phishingUserID() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.org\">@alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following user @alice:matrix.org")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.org")
        #expect(link.confirmationParameters?.displayString == "@alice:matrix.org")
    }
    
    @Test
    func validUserIDLink() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.to/#/@alice:matrix.org\">@alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        checkAttachment(attributedString: attributedString, expectedRuns: 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(!link.requiresConfirmation)
        #expect(link.absoluteString == "https://matrix.to/#/@alice:matrix.org")
    }
    
    @Test
    func phishingUserIDWithAnotherUserIDPermalink() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.to/#/@bob:matrix.org\">@alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following user @alice:matrix.org")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.to/#/@bob:matrix.org")
        #expect(link.confirmationParameters?.displayString == "@alice:matrix.org")
    }
    
    @Test
    func phishingUserIDWithDistractingCharacters() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.org\">👉️ @alice:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following user 👉️ @alice:matrix.org")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.org")
        #expect(link.confirmationParameters?.displayString == "👉️ @alice:matrix.org")
    }
    
    @Test
    func phishingLinkWithDistractingCharacters() {
        let htmlString = "Hey check the following link <a href=\"https://matrix.org\">👉️ https://element.io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following link 👉️ https://element.io")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.org")
        #expect(link.confirmationParameters?.displayString == "👉️ https://element.io")
    }
    
    @Test
    func validLinkWithDistractingCharacters() {
        let htmlString = "Hey check the following link <a href=\"https://element.io\">👉️ https://element.io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        #expect(String(attributedString.characters) == "Hey check the following link 👉️ https://element.io")
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        
        #expect(!link.requiresConfirmation)
        #expect(link.absoluteString == "https://element.io")
    }
    
    @Test
    func phishingLinkWithFakeDotCharacter() {
        let htmlString = "Hey check the following link <a href=\"https://matrix.org\">https://element﹒io</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following link https://element﹒io")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.org")
        #expect(link.confirmationParameters?.displayString == "https://element﹒io")
    }
    
    @Test
    func phishingMatrixPermalinks() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.to/#/#offensive-room:matrix.org\">https://matrix.to/#/#beautiful-room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.to/#/%23offensive-room:matrix.org")
        #expect(link.confirmationParameters?.displayString == "https://matrix.to/#/#beautiful-room:matrix.org")
    }
    
    @Test
    func validMatrixPermalinks() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.to/#/#beautiful-room:matrix.org\">https://matrix.to/#/#beautiful-room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        checkAttachment(attributedString: attributedString, expectedRuns: 2)
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        
        #expect(!link.requiresConfirmation)
        #expect(link.absoluteString == "https://matrix.to/#/%23beautiful-room:matrix.org")
    }
    
    @Test
    func phishingRoomAlias() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.org\">#room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following room #room:matrix.org")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.org")
        #expect(link.confirmationParameters?.displayString == "#room:matrix.org")
    }
    
    @Test
    func validRoomAliasLink() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.to/#/#room:matrix.org\">#room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        checkAttachment(attributedString: attributedString, expectedRuns: 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(!link.requiresConfirmation)
        #expect(link.absoluteString == "https://matrix.to/#/%23room:matrix.org")
    }
    
    @Test
    func phishingRoomAliasWithAnotherRoomAliasPermalink() {
        let htmlString = "Hey check the following room <a href=\"https://matrix.to/#/#another-room:matrix.org\">#room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following room #room:matrix.org")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.to/#/%23another-room:matrix.org")
        #expect(link.confirmationParameters?.displayString == "#room:matrix.org")
    }
    
    @Test
    func roomAliasWithDistractingCharacters() {
        let htmlString = "Hey check the following user <a href=\"https://matrix.org\">👉️ #room:matrix.org</a>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "Hey check the following user 👉️ #room:matrix.org")
        
        #expect(attributedString.runs.count == 2)
        
        guard let link = attributedString.runs.first(where: { $0.link != nil })?.link else {
            Issue.record("Couldn't find the link")
            return
        }
        #expect(link.requiresConfirmation)
        #expect(link.confirmationParameters?.internalURL.absoluteString == "https://matrix.org")
        #expect(link.confirmationParameters?.displayString == "👉️ #room:matrix.org")
    }
    
    @Test
    func mxExternalPaymentDetailsRemoved() {
        var htmlString = "This is visible.<span data-msc4286-external-payment-details> But this is hidden <a href=\"https://matrix.org\">and this link too</a></span>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "This is visible.")
        
        for run in attributedString.runs where run.link != nil {
            Issue.record("No link expected, but found one")
            return
        }
        
        htmlString = "This is visible.<span> And this text <a href=\"https://matrix.org\">and link</a> are visible too.</span>"
        
        guard let attributedString = attributedStringBuilder.fromHTML(htmlString) else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(String(attributedString.characters) == "This is visible. And this text and link are visible too.")
        
        guard attributedString.runs.first(where: { $0.link != nil })?.link != nil else {
            Issue.record("Couldn't find the link")
            return
        }
    }
    
    // MARK: - Private
    
    private func checkLinkIn(attributedString: AttributedString?, expectedLink: String, expectedRuns: Int) {
        guard let attributedString else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == expectedRuns)
        
        for run in attributedString.runs where run.link != nil {
            #expect(run.link?.absoluteString == expectedLink)
            return
        }
        
        Issue.record("Couldn't find expected value.")
    }
    
    private func checkAttachment(attributedString: AttributedString?, expectedRuns: Int) {
        guard let attributedString else {
            Issue.record("Could not build the attributed string")
            return
        }
        
        #expect(attributedString.runs.count == expectedRuns)
        
        for run in attributedString.runs where run.attachment != nil {
            return
        }
        
        Issue.record("Couldn't find expected value.")
    }
}
