//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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

extension NSAttributedString.Key {
    static let DTTextBlocks: NSAttributedString.Key = .init(rawValue: DTTextBlocksAttribute)
    static let MatrixBlockquote: NSAttributedString.Key = .init(rawValue: BlockquoteAttribute.name)
    static let MatrixUserID: NSAttributedString.Key = .init(rawValue: UserIDAttribute.name)
    static let MatrixUserDisplayName: NSAttributedString.Key = .init(rawValue: UserDisplayNameAttribute.name)
    static let MatrixRoomDisplayName: NSAttributedString.Key = .init(rawValue: RoomDisplayNameAttribute.name)
    static let MatrixRoomID: NSAttributedString.Key = .init(rawValue: RoomIDAttribute.name)
    static let MatrixRoomAlias: NSAttributedString.Key = .init(rawValue: RoomAliasAttribute.name)
    static let MatrixEventOnRoomID: NSAttributedString.Key = .init(rawValue: EventOnRoomIDAttribute.name)
    static let MatrixEventOnRoomAlias: NSAttributedString.Key = .init(rawValue: EventOnRoomAliasAttribute.name)
    static let MatrixAllUsersMention: NSAttributedString.Key = .init(rawValue: AllUsersMentionAttribute.name)
    static let CodeBlock: NSAttributedString.Key = .init(rawValue: CodeBlockAttribute.name)
}

struct AttributedStringBuilder: AttributedStringBuilderProtocol {
    private static let defaultKey = "default"
    
    private let builder: AttributedStringBuilderProtocol
    
    static var useNextGenHTMLParser = false
    
    static func invalidateCaches() {
        AttributedStringBuilderV1.invalidateCaches()
        AttributedStringBuilderV2.invalidateCaches()
    }
    
    init(cacheKey: String = defaultKey, mentionBuilder: MentionBuilderProtocol) {
        if Self.useNextGenHTMLParser {
            builder = AttributedStringBuilderV2(cacheKey: cacheKey, mentionBuilder: mentionBuilder)
        } else {
            builder = AttributedStringBuilderV1(cacheKey: cacheKey, mentionBuilder: mentionBuilder)
        }
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
