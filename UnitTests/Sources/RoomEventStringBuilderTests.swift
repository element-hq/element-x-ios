//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import XCTest

class RoomEventStringBuilderTests: XCTestCase {
    var ownUserID: String!
    var stringBuilder: RoomEventStringBuilder!
    
    override func setUp() {
        ownUserID = "@alice:matrix.org"
        let stateEventStringBuilder = RoomStateEventStringBuilder(userID: ownUserID)
        let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
        
        stringBuilder = RoomEventStringBuilder(stateEventStringBuilder: stateEventStringBuilder,
                                               messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: attributedStringBuilder,
                                                                                                        destination: .roomList),
                                               shouldDisambiguateDisplayNames: true,
                                               shouldPrefixSenderName: true)
    }
    
    func testSenderPrefix() {
        let ownMessageString = stringBuilder.buildAttributedString(for: makeTextMessageItem(senderID: ownUserID, senderDisplayName: "Alice"))
        XCTAssertEqual(ownMessageString?.string, "You: Hello, World!",
                       "Your own messages should be prefixed with 'You'")
        
        let otherMessageString = stringBuilder.buildAttributedString(for: makeTextMessageItem(senderID: "@bob:matrix.org", senderDisplayName: "Bob"))
        XCTAssertEqual(otherMessageString?.string, "Bob: Hello, World!",
                       "Everyone else's messages should be prefixed with their display name.")
        
        let ambiguousMessageString = stringBuilder.buildAttributedString(for: makeTextMessageItem(senderID: "@charlie:matrix.org",
                                                                                                  senderDisplayName: "Charlie",
                                                                                                  senderDisplayNameAmbiguous: true))
        XCTAssertEqual(ambiguousMessageString?.string, "Charlie (@charlie:matrix.org): Hello, World!",
                       "Messages from senders with ambiguous display names should include their user ID in the prefix.")
    }
    
    // MARK: - Helpers
    
    private func makeTextMessageItem(senderID: String,
                                     senderDisplayName: String? = nil,
                                     senderDisplayNameAmbiguous: Bool = false,
                                     message: String = "Hello, World!") -> EventTimelineItemProxy {
        .init(item: .init(configuration: .init(eventID: "1234",
                                               sender: senderID,
                                               senderProfile: .ready(displayName: senderDisplayName, displayNameAmbiguous: senderDisplayNameAmbiguous, avatarUrl: nil),
                                               isOwn: senderID == ownUserID,
                                               content: .msgLike(content: .init(kind: .message(content: .init(msgType: makeTextContent(message: message),
                                                                                                              body: message,
                                                                                                              isEdited: false,
                                                                                                              mentions: nil)),
                                                                                reactions: [],
                                                                                threadRoot: nil,
                                                                                inReplyTo: nil)))),
              uniqueID: .init("0"))
    }
    
    private func makeTextContent(message: String) -> MessageType {
        .text(content: .init(body: message, formatted: nil))
    }
}
