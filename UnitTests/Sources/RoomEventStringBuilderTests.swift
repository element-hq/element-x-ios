//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
        let ownMessageString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: ownUserID, senderDisplayName: "Alice"))
        XCTAssertEqual(ownMessageString?.string, "You: Hello, World!", "Your own messages should be prefixed with 'You'")
        
        let otherMessageString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@bob:matrix.org", senderDisplayName: "Bob"))
        XCTAssertEqual(otherMessageString?.string, "Bob: Hello, World!", "Everyone else's messages should be prefixed with their display name.")
        
        let ambiguousMessageString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@charlie:matrix.org",
                                                                                              senderDisplayName: "Charlie",
                                                                                              senderDisplayNameAmbiguous: true))
        XCTAssertEqual(ambiguousMessageString?.string, "Charlie (@charlie:matrix.org): Hello, World!",
                       "Messages from senders with ambiguous display names should include their user ID in the prefix.")
        
        let ownEmoteString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: ownUserID,
                                                                                      senderDisplayName: "Alice",
                                                                                      type: .emote,
                                                                                      message: "laughs"))
        XCTAssertEqual(ownEmoteString?.string, "* Alice laughs", "Your own emotes shouldn't contain 'You'")
        
        let otherEmoteString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@bob:matrix.org",
                                                                                        senderDisplayName: "Bob",
                                                                                        type: .emote,
                                                                                        message: "sighs"))
        XCTAssertEqual(otherEmoteString?.string, "* Bob sighs", "Everyone else's emotes should contain their display name.")
        
        let ownPollString = stringBuilder.buildAttributedString(for: makePollItem(senderID: ownUserID, senderDisplayName: "Alice"))
        XCTAssertEqual(ownPollString?.string, "You: Poll: Which is better?", "Your own polls should be prefixed with 'You'")
        
        let otherPollString = stringBuilder.buildAttributedString(for: makePollItem(senderID: "@bob:matrix.org", senderDisplayName: "Bob"))
        XCTAssertEqual(otherPollString?.string, "Bob: Poll: Which is better?", "Everyone else's polls should be prefixed with their display name.")
    }
    
    // MARK: - Helpers
    
    private enum MockMessageType { case textMessage, emote }
    
    private func makeMessageItem(senderID: String,
                                 senderDisplayName: String? = nil,
                                 senderDisplayNameAmbiguous: Bool = false,
                                 type: MockMessageType = .textMessage,
                                 message: String = "Hello, World!") -> EventTimelineItemProxy {
        let content = switch type {
        case .textMessage: makeTextContent(message: message)
        case .emote: makeEmoteContent(message: message)
        }
        
        return .init(item: .init(configuration: .init(eventID: "1234",
                                                      sender: senderID,
                                                      senderProfile: .ready(displayName: senderDisplayName, displayNameAmbiguous: senderDisplayNameAmbiguous, avatarUrl: nil),
                                                      isOwn: senderID == ownUserID,
                                                      content: .msgLike(content: .init(kind: .message(content: .init(msgType: content,
                                                                                                                     body: message,
                                                                                                                     isEdited: false,
                                                                                                                     mentions: nil)),
                                                                                       reactions: [],
                                                                                       inReplyTo: nil,
                                                                                       threadRoot: nil,
                                                                                       threadSummary: nil)))),
                     uniqueID: .init("0"))
    }
    
    private func makeTextContent(message: String) -> MessageType {
        .text(content: .init(body: message, formatted: nil))
    }
    
    private func makeEmoteContent(message: String) -> MessageType {
        .emote(content: .init(body: message, formatted: nil))
    }
    
    private func makePollItem(senderID: String,
                              senderDisplayName: String? = nil,
                              senderDisplayNameAmbiguous: Bool = false,
                              question: String = "Which is better?") -> EventTimelineItemProxy {
        .init(item: .init(configuration: .init(eventID: "1234",
                                               sender: senderID,
                                               senderProfile: .ready(displayName: senderDisplayName, displayNameAmbiguous: senderDisplayNameAmbiguous, avatarUrl: nil),
                                               isOwn: senderID == ownUserID,
                                               content: .msgLike(content: .init(kind: .poll(question: question,
                                                                                            kind: .disclosed,
                                                                                            maxSelections: 1,
                                                                                            answers: [],
                                                                                            votes: [:],
                                                                                            endTime: nil,
                                                                                            hasBeenEdited: false),
                                                                                reactions: [],
                                                                                inReplyTo: nil,
                                                                                threadRoot: nil,
                                                                                threadSummary: nil)))),
              uniqueID: .init("0"))
    }
}
