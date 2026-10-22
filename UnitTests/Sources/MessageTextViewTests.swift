//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing
import UIKit

struct MessageTextViewTests {
    private let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
    private let textView = MessageTextView(usingTextLayoutManager: false)
    
    @Test
    func inlineCodeIsNotHyphenated() throws {
        let textStorage = try makeTextStorage(html: "Merged at <code>d097cc7a2720e8a6e0714d291aa27a034bd20a0b</code> today")
        let layoutManager = try #require(textStorage.layoutManagers.first)
        
        let codeRange = (textStorage.string as NSString).range(of: "d097cc7a2720e8a6e0714d291aa27a034bd20a0b")
        for index in codeRange.location..<NSMaxRange(codeRange) {
            #expect(!textView.layoutManager(layoutManager, shouldBreakLineByHyphenatingBeforeCharacterAt: index))
        }
    }
    
    @Test
    func codeBlockIsNotHyphenated() throws {
        let textStorage = try makeTextStorage(html: "<pre>configurationmanagementinitialization</pre>")
        let layoutManager = try #require(textStorage.layoutManagers.first)
        
        let codeRange = (textStorage.string as NSString).range(of: "configurationmanagementinitialization")
        for index in codeRange.location..<NSMaxRange(codeRange) {
            #expect(!textView.layoutManager(layoutManager, shouldBreakLineByHyphenatingBeforeCharacterAt: index))
        }
    }
    
    @Test
    func plainTextCanStillBeHyphenated() throws {
        let textStorage = try makeTextStorage(html: "Internationalization <code>code</code> incomprehensibilities")
        let layoutManager = try #require(textStorage.layoutManagers.first)
        let string = textStorage.string as NSString
        
        #expect(textView.layoutManager(layoutManager, shouldBreakLineByHyphenatingBeforeCharacterAt: string.range(of: "Internationalization").location + 5))
        #expect(textView.layoutManager(layoutManager, shouldBreakLineByHyphenatingBeforeCharacterAt: string.range(of: "incomprehensibilities").location + 5))
    }
    
    @Test
    func outOfBoundsIndexIsIgnored() throws {
        let textStorage = try makeTextStorage(html: "<code>code</code>")
        let layoutManager = try #require(textStorage.layoutManagers.first)
        
        #expect(textView.layoutManager(layoutManager, shouldBreakLineByHyphenatingBeforeCharacterAt: textStorage.length))
    }
    
    // MARK: - Helpers
    
    /// The layout manager only holds a weak reference to its text storage, so the storage is what must be kept alive.
    private func makeTextStorage(html: String) throws -> NSTextStorage {
        let attributedString = try #require(attributedStringBuilder.fromHTML(html))
        let textStorage = try NSTextStorage(attributedString: NSAttributedString(attributedString, including: \.elementX))
        textStorage.addLayoutManager(NSLayoutManager())
        return textStorage
    }
}
