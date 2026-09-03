//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct TimelineItemMenuActionProviderTests {
    @Test
    func liveLocationShareIsNotForwardable() throws {
        let item = makeLiveLocationItem(isLive: true)
        let actions = try #require(makeActions(for: item))
        
        let hasForward = actions.actions.contains(where: \.isForward)
        #expect(!hasForward)
    }
    
    @Test
    func endedLiveLocationShareIsNotForwardable() throws {
        let item = makeLiveLocationItem(isLive: false)
        let actions = try #require(makeActions(for: item))
        
        let hasForward = actions.actions.contains(where: \.isForward)
        #expect(!hasForward)
    }
    
    @Test
    func pollIsNotForwardable() throws {
        let item = PollRoomTimelineItem.mock(poll: .emptyDisclosed)
        let actions = try #require(makeActions(for: item))
        
        let hasForward = actions.actions.contains(where: \.isForward)
        #expect(!hasForward)
    }
    
    @Test
    func textMessageIsForwardable() throws {
        let item = TextRoomTimelineItem(id: .randomEvent,
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        sender: .init(id: "@alice:matrix.org"),
                                        content: .init(body: "Hello"))
        let actions = try #require(makeActions(for: item))
        
        let hasForward = actions.actions.contains(where: \.isForward)
        #expect(hasForward)
    }
    
    // MARK: - Select
    
    @Test
    func selectIsShownForRemoteMessageWhenEnabled() throws {
        let actions = try #require(makeActions(for: makeTextItem(), isMultiSelectEnabled: true))
        #expect(actions.actions.contains(.select))
    }
    
    @Test
    func selectIsHiddenWhenDisabled() throws {
        let actions = try #require(makeActions(for: makeTextItem()))
        #expect(!actions.actions.contains(.select))
    }
    
    @Test
    func selectIsHiddenInPinnedTimeline() throws {
        let actions = try #require(makeActions(for: makeTextItem(), isMultiSelectEnabled: true, timelineKind: .pinned))
        #expect(!actions.actions.contains(.select))
    }
    
    @Test
    func selectIsHiddenForLocalEcho() throws {
        let item = makeTextItem(id: .event(uniqueID: .init("local"), eventOrTransactionID: .transactionID("txn")))
        let actions = try #require(makeActions(for: item, isMultiSelectEnabled: true))
        #expect(!actions.actions.contains(.select))
    }
    
    @Test
    func selectIsHiddenForLiveLocationShare() throws {
        let actions = try #require(makeActions(for: makeLiveLocationItem(isLive: true), isMultiSelectEnabled: true))
        #expect(!actions.actions.contains(.select))
    }
    
    @Test
    func selectIsShownForEncryptedItemWhenEnabled() throws {
        let item = EncryptedRoomTimelineItem(id: .randomEvent,
                                             body: "",
                                             encryptionType: .unknown,
                                             timestamp: .mock,
                                             isOutgoing: false,
                                             isEditable: false,
                                             canBeRepliedTo: false,
                                             sender: .init(id: "@alice:matrix.org"))
        let actions = try #require(makeActions(for: item, isMultiSelectEnabled: true))
        #expect(actions.actions.contains(.select))
    }
    
    // MARK: - Helpers
    
    private func makeTextItem(id: TimelineItemIdentifier = .randomEvent) -> TextRoomTimelineItem {
        .init(id: id,
              timestamp: .mock,
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              sender: .init(id: "@alice:matrix.org"),
              content: .init(body: "Hello"))
    }
    
    private func makeLiveLocationItem(isLive: Bool) -> LiveLocationRoomTimelineItem {
        .init(id: .randomEvent,
              timestamp: .mock,
              isOutgoing: false,
              isEditable: false,
              canBeRepliedTo: true,
              sender: .init(id: "@alice:matrix.org"),
              content: .init(isLive: isLive, timeoutDate: .mock, lastGeoURI: nil))
    }
    
    private func makeActions(for item: RoomTimelineItemProtocol,
                             isMultiSelectEnabled: Bool = false,
                             timelineKind: TimelineKind = .live) -> TimelineItemMenuActions? {
        TimelineItemMenuActionProvider(timelineItem: item,
                                       canCurrentUserSendMessage: true,
                                       canCurrentUserRedactSelf: true,
                                       canCurrentUserRedactOthers: false,
                                       canCurrentUserPin: true,
                                       pinnedEventIDs: [],
                                       isViewSourceEnabled: true,
                                       areThreadsEnabled: true,
                                       isMultiSelectEnabled: isMultiSelectEnabled,
                                       timelineKind: timelineKind,
                                       emojiProvider: EmojiProvider(appSettings: .volatile()))
            .makeActions()
    }
}

private extension TimelineItemMenuAction {
    var isForward: Bool {
        if case .forward = self {
            return true
        }
        return false
    }
}
