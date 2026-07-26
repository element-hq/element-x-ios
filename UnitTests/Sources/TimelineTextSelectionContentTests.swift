//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing
import UIKit

@MainActor
struct TimelineTextSelectionContentTests {
    @Test
    func replacesMatrixPillsWithReadableText() throws {
        let attributedString = NSMutableAttributedString(string: "")
        attributedString.append(makeUserMention(userID: "@alice:matrix.org", displayName: "Alice"))
        attributedString.append(NSAttributedString(string: " "))
        attributedString.append(makeUserMention(userID: "@bob:matrix.org", displayName: nil))
        attributedString.append(NSAttributedString(string: " "))
        attributedString.append(makeAllUsersMention())
        attributedString.append(NSAttributedString(string: " "))
        attributedString.append(makeRoomAliasMention(alias: "#element:matrix.org", displayName: "Element"))
        attributedString.append(NSAttributedString(string: " "))
        attributedString.append(makeRoomIDMention(roomID: "!room:matrix.org"))
        attributedString.append(NSAttributedString(string: " "))
        attributedString.append(makeEventOnRoomAliasMention(alias: "#foundation:matrix.org"))
        attributedString.append(NSAttributedString(string: " "))
        attributedString.append(makeEventOnRoomIDMention(roomID: "!event-room:matrix.org"))

        let result = try transformed(attributedString,
                                     roomNameForID: { $0 == "!room:matrix.org" ? "Matrix HQ" : nil },
                                     roomNameForAlias: { $0 == "#foundation:matrix.org" ? "Foundation" : nil })

        #expect(result.string == "@Alice @bob:matrix.org @room #Element #Matrix HQ 💬 > #Foundation 💬 > !event-room:matrix.org")
        #expect(!result.string.contains("\u{fffc}"))
        result.enumerateAttributes(in: NSRange(location: 0, length: result.length)) { attributes, _, _ in
            #expect(!(attributes[.attachment] is PillTextAttachment))
            #expect(attributes[.link] == nil)
        }
    }

    @Test
    func preservesUnicodeAndNoninteractiveFormatting() throws {
        let originalString = "Family: 👨‍👩‍👧‍👦 — مرحبا بالعالم"
        let attributedString = NSMutableAttributedString(string: originalString)
        let range = NSRange(location: 0, length: attributedString.length)
        let font = UIFont.preferredFont(forTextStyle: .body)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .natural
        attributedString.addAttributes([.font: font,
                                        .paragraphStyle: paragraphStyle,
                                        .MatrixBlockquote: true,
                                        .link: URL(string: "https://matrix.org")!],
                                       range: range)

        let result = try transformed(attributedString)

        #expect(result.string == originalString)
        #expect(result.attribute(.font, at: 0, effectiveRange: nil) as? UIFont == font)
        #expect((result.attribute(.paragraphStyle, at: 0, effectiveRange: nil) as? NSParagraphStyle)?.alignment == .natural)
        #expect(result.attribute(.MatrixBlockquote, at: 0, effectiveRange: nil) as? Bool == true)
        #expect(result.attribute(.link, at: 0, effectiveRange: nil) == nil)
    }

    private func makeUserMention(userID: String, displayName: String?) -> NSAttributedString {
        makeMention("user") { attributedString, range in
            MentionBuilder().handleUserMention(for: attributedString,
                                               in: range,
                                               url: URL(string: "https://matrix.org")!,
                                               userID: userID,
                                               userDisplayName: displayName)
        }
    }

    private func makeAllUsersMention() -> NSAttributedString {
        makeMention("@room") { attributedString, range in
            MentionBuilder().handleAllUsersMention(for: attributedString, in: range)
        }
    }

    private func makeRoomAliasMention(alias: String, displayName: String?) -> NSAttributedString {
        makeMention("room") { attributedString, range in
            MentionBuilder().handleRoomAliasMention(for: attributedString,
                                                    in: range,
                                                    url: URL(string: "https://matrix.org")!,
                                                    roomAlias: alias,
                                                    roomDisplayName: displayName)
        }
    }

    private func makeRoomIDMention(roomID: String) -> NSAttributedString {
        makeMention("room") { attributedString, range in
            MentionBuilder().handleRoomIDMention(for: attributedString,
                                                 in: range,
                                                 url: URL(string: "https://matrix.org")!,
                                                 roomID: roomID)
        }
    }

    private func makeEventOnRoomAliasMention(alias: String) -> NSAttributedString {
        makeMention("event") { attributedString, range in
            MentionBuilder().handleEventOnRoomAliasMention(for: attributedString,
                                                           in: range,
                                                           url: URL(string: "https://matrix.org")!,
                                                           eventID: "$event",
                                                           roomAlias: alias)
        }
    }

    private func makeEventOnRoomIDMention(roomID: String) -> NSAttributedString {
        makeMention("event") { attributedString, range in
            MentionBuilder().handleEventOnRoomIDMention(for: attributedString,
                                                        in: range,
                                                        url: URL(string: "https://matrix.org")!,
                                                        eventID: "$event",
                                                        roomID: roomID)
        }
    }

    private func makeMention(_ string: String,
                             configure: (NSMutableAttributedString, NSRange) -> Void) -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: string,
                                                         attributes: [.font: UIFont.preferredFont(forTextStyle: .body),
                                                                      .foregroundColor: UIColor.label])
        configure(attributedString, NSRange(location: 0, length: attributedString.length))
        return attributedString
    }

    private func transformed(_ attributedString: NSAttributedString,
                             userDisplayNameForID: (String) -> String? = { _ in nil },
                             roomNameForID: (String) -> String? = { _ in nil },
                             roomNameForAlias: (String) -> String? = { _ in nil }) throws -> NSAttributedString {
        let source = try AttributedString(attributedString, including: \.elementX)
        let result = MatrixPillTextTransformer.transform(source,
                                                         userDisplayNameForID: userDisplayNameForID,
                                                         roomNameForID: roomNameForID,
                                                         roomNameForAlias: roomNameForAlias)
        return try NSAttributedString(result, including: \.elementX)
    }
}
