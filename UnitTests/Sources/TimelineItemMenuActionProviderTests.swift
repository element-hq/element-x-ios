//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct TimelineItemMenuActionProviderTests {
    @Test
    func textMessagesIncludeSelectText() throws {
        let item = try #require(TimelineFixtures.singleMessageChunk.first)
        let actions = try #require(makeActions(for: item))

        #expect(actions.actions.contains(.copy))
        #expect(actions.actions.contains(.selectText))
    }

    @Test
    func mediaCaptionsIncludeSelectText() throws {
        let item = try #require(TimelineFixtures.mediaChunk[5] as? EventBasedMessageTimelineItemProtocol)
        let actions = try #require(makeActions(for: item))

        #expect(item.hasMediaCaption)
        #expect(actions.actions.contains(.copyCaption))
        #expect(actions.actions.contains(.selectText))
    }

    @Test
    func selectableTextPrefersFormattedMediaCaption() {
        let formattedCaption = AttributedString("Formatted caption")
        let item = ImageRoomTimelineItem(id: .randomEvent,
                                         timestamp: .mock,
                                         isOutgoing: false,
                                         isEditable: false,
                                         canBeRepliedTo: true,
                                         sender: .init(id: "@alice:matrix.org"),
                                         content: .init(filename: "image.jpg",
                                                        caption: "Plain caption",
                                                        formattedCaption: formattedCaption,
                                                        imageInfo: .mockImage,
                                                        thumbnailInfo: nil))

        #expect(item.selectableText == formattedCaption)
    }

    @Test
    func mediaWithoutCaptionDoesNotIncludeSelectText() throws {
        let item = try #require(TimelineFixtures.mediaChunk[1] as? EventBasedMessageTimelineItemProtocol)
        let actions = try #require(makeActions(for: item))

        #expect(!item.hasMediaCaption)
        #expect(item.selectableText == nil)
        #expect(!actions.actions.contains(.selectText))
    }

    @Test
    func selectableTextPrefersFormattedMessageBody() throws {
        let formattedBody = AttributedString("Formatted body")
        let item = TextRoomTimelineItem(id: .randomEvent,
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        sender: .init(id: "@alice:matrix.org"),
                                        content: .init(body: "Plain body", formattedBody: formattedBody))

        #expect(item.selectableText == formattedBody)
    }

    @Test
    func selectableTextFallsBackToPlainMessageBody() {
        let item = TextRoomTimelineItem(id: .randomEvent,
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        sender: .init(id: "@alice:matrix.org"),
                                        content: .init(body: "Plain body"))

        #expect(item.selectableText == AttributedString("Plain body"))
    }

    private func makeActions(for item: RoomTimelineItemProtocol) -> TimelineItemMenuActions? {
        TimelineItemMenuActionProvider(timelineItem: item,
                                       canCurrentUserSendMessage: true,
                                       canCurrentUserRedactSelf: true,
                                       canCurrentUserRedactOthers: false,
                                       canCurrentUserPin: true,
                                       pinnedEventIDs: [],
                                       isViewSourceEnabled: true,
                                       areThreadsEnabled: true,
                                       timelineKind: .live,
                                       emojiProvider: EmojiProvider(appSettings: .volatile()))
            .makeActions()
    }
}
