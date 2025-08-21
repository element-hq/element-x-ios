//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import DTCoreText
import Foundation
import LRUCache
import MatrixRustSDK

protocol MentionBuilderProtocol {
    func handleUserMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, userID: String, userDisplayName: String?)
    func handleRoomIDMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, roomID: String)
    func handleRoomAliasMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, roomAlias: String, roomDisplayName: String?)
    func handleEventOnRoomAliasMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, eventID: String, roomAlias: String)
    func handleEventOnRoomIDMention(for attributedString: NSMutableAttributedString, in range: NSRange, url: URL, eventID: String, roomID: String)
    func handleAllUsersMention(for attributedString: NSMutableAttributedString, in range: NSRange)
}

struct AttributedStringBuilder: AttributedStringBuilderProtocol {
    private static let defaultKey = "default"
    
    private let builder: AttributedStringBuilderProtocol
    
    static var useNextGenHTMLParser = false
    
    static func invalidateCaches() {
        AttributedStringBuilderV1.invalidateCaches()
    }
    
    init(cacheKey: String = defaultKey, mentionBuilder: MentionBuilderProtocol) {
        builder = AttributedStringBuilderV1(cacheKey: cacheKey, mentionBuilder: mentionBuilder)
    }
    
    func fromPlain(_ string: String?) -> AttributedString? {
        builder.fromPlain(string)
    }
    
    func fromHTML(_ htmlString: String?) -> AttributedString? {
        builder.fromHTML(htmlString)
    }
    
    func addMatrixEntityPermalinkAttributesTo(_ attributedString: NSMutableAttributedString) {
        builder.addMatrixEntityPermalinkAttributesTo(attributedString)
    }
}
