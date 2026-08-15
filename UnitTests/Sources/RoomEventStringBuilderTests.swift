//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import Testing

struct RoomEventStringBuilderTests {
    private let ownUserID: String
    private let stringBuilder: RoomEventStringBuilder
    
    init() {
        ownUserID = "@alice:matrix.org"
        let stateEventStringBuilder = RoomStateEventStringBuilder(userID: ownUserID)
        let attributedStringBuilder = AttributedStringBuilder(mentionBuilder: MentionBuilder())
        
        stringBuilder = RoomEventStringBuilder(stateEventStringBuilder: stateEventStringBuilder,
                                               messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: attributedStringBuilder,
                                                                                                        style: .senderPrefixed),
                                               shouldPrefixSenderName: true)
    }
    
    @Test
    func senderPrefix() {
        let ownMessageString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: ownUserID, senderDisplayName: "Alice"))
        #expect(ownMessageString?.string == "You: Hello, World!", "Your own messages should be prefixed with 'You'")
        
        let otherMessageString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@bob:matrix.org", senderDisplayName: "Bob"))
        #expect(otherMessageString?.string == "Bob: Hello, World!", "Everyone else's messages should be prefixed with their display name.")
        
        let ambiguousMessageString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@charlie:matrix.org",
                                                                                              senderDisplayName: "Charlie",
                                                                                              senderDisplayNameAmbiguous: true))
        #expect(ambiguousMessageString?.string == "Charlie (@charlie:matrix.org): Hello, World!",
                "Messages from senders with ambiguous display names should include their user ID in the prefix.")
        
        let ownEmoteString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: ownUserID,
                                                                                      senderDisplayName: "Alice",
                                                                                      type: .emote,
                                                                                      message: "laughs"))
        #expect(ownEmoteString?.string == "* Alice laughs", "Your own emotes shouldn't contain 'You'")
        
        let otherEmoteString = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@bob:matrix.org",
                                                                                        senderDisplayName: "Bob",
                                                                                        type: .emote,
                                                                                        message: "sighs"))
        #expect(otherEmoteString?.string == "* Bob sighs", "Everyone else's emotes should contain their display name.")
        
        let ownPollString = stringBuilder.buildAttributedString(for: makePollItem(senderID: ownUserID, senderDisplayName: "Alice"))
        #expect(ownPollString?.string == "You: Poll: Which is better?", "Your own polls should be prefixed with 'You'")
        
        let otherPollString = stringBuilder.buildAttributedString(for: makePollItem(senderID: "@bob:matrix.org", senderDisplayName: "Bob"))
        #expect(otherPollString?.string == "Bob: Poll: Which is better?", "Everyone else's polls should be prefixed with their display name.")
    }
    
    @Test
    func blockquotePreviewKeepsQuoteMarkers() {
        let quoteReply = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@bob:matrix.org",
                                                                                  senderDisplayName: "Bob",
                                                                                  message: "> original quote\n\na reply",
                                                                                  formattedBody: "<blockquote><p>original quote</p></blockquote><p>a reply</p>"))
        #expect(quoteReply?.string == "Bob: > original quote\na reply",
                "Quoted lines should keep a quote marker in flattened previews.")
        
        let multilineQuote = stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@bob:matrix.org",
                                                                                      senderDisplayName: "Bob",
                                                                                      message: "> line one\n> line two\n\na reply",
                                                                                      formattedBody: "<blockquote><p>line one</p><p>line two</p></blockquote><p>a reply</p>"))
        #expect(multilineQuote?.string == "Bob: > line one\n> line two\na reply",
                "Every quoted line should get its own marker.")
    }
    
    @Test
    func formattedPreviewCapabilities() throws {
        let preview = try #require(stringBuilder.buildAttributedString(for: makeMessageItem(senderID: "@bob:matrix.org",
                                                                                            senderDisplayName: "Bob",
                                                                                            message: "**bold** ~~struck~~ `code` [site](https://example.org)",
                                                                                            formattedBody: "<strong>bold</strong> <del>struck</del> <code>code</code> <a href=\"https://example.org\">site</a>")))
        #expect(preview.string == "Bob: bold struck code site")
        
        for run in preview.runs {
            #expect(run.link == nil, "Previews aren't interactive; links should be plain text.")
        }
        
        for run in preview.runs {
            #expect(run.uiKit.font == nil, "Previews should carry presentation intents, not fixed-size fonts.")
            #expect(run.uiKit.strikethroughStyle == nil, "UIKit line styles aren't rendered by Text and should be replaced.")
        }
        
        let bold = try #require(preview.range(of: "bold"))
        #expect(preview[bold].runs.allSatisfy { $0.inlinePresentationIntent?.contains(.stronglyEmphasized) == true },
                "Bold text should render bold at the preview's own font size.")
        
        let struck = try #require(preview.range(of: "struck"))
        #expect(preview[struck].runs.allSatisfy { $0.swiftUI.strikethroughStyle == .single },
                "Strikethrough should survive via the SwiftUI attribute.")
        
        let code = try #require(preview.range(of: "code", options: .backwards))
        #expect(preview[code].runs.allSatisfy { $0.inlinePresentationIntent?.contains(.code) == true },
                "Inline code should stay monospaced via its presentation intent.")
    }
    
    // MARK: - Helpers
    
    private enum MockMessageType { case textMessage, emote }
    
    private func makeMessageItem(senderID: String,
                                 senderDisplayName: String? = nil,
                                 senderDisplayNameAmbiguous: Bool = false,
                                 type: MockMessageType = .textMessage,
                                 message: String = "Hello, World!",
                                 formattedBody: String? = nil) -> EventTimelineItemProxy {
        let content = switch type {
        case .textMessage: makeTextContent(message: message, formattedBody: formattedBody)
        case .emote: makeEmoteContent(message: message)
        }
        
        return .init(item: .init(configuration: .init(eventID: "1234",
                                                      sender: senderID,
                                                      senderProfile: .ready(displayName: senderDisplayName,
                                                                            displayNameAmbiguous: senderDisplayNameAmbiguous,
                                                                            avatarUrl: nil,
                                                                            status: nil,
                                                                            call: nil),
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
    
    private func makeTextContent(message: String, formattedBody: String? = nil) -> MessageType {
        .text(content: .init(body: message, formatted: formattedBody.map { .init(format: .html, body: $0) }))
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
                                               senderProfile: .ready(displayName: senderDisplayName,
                                                                     displayNameAmbiguous: senderDisplayNameAmbiguous,
                                                                     avatarUrl: nil,
                                                                     status: nil,
                                                                     call: nil),
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
