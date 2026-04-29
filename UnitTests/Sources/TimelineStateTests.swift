//
// Copyright 2026 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import OrderedCollections
import Testing

struct TimelineStateTests {
    // MARK: - Unread Message Count

    @Test("Unread count includes only message-content items after the read marker")
    func unreadMessageCountWithMixedContent() {
        // Two messages before the marker, then a separator + a state event + two messages after.
        var state = TimelineState()
        state.itemsDictionary[.init("msg1")] = makeTextViewState(uniqueID: "msg1")
        state.itemsDictionary[.init("msg2")] = makeTextViewState(uniqueID: "msg2")
        state.itemsDictionary[.init("read-marker")] = makeReadMarkerViewState(uniqueID: "read-marker")
        state.itemsDictionary[.init("separator")] = makeSeparatorViewState(uniqueID: "separator")
        state.itemsDictionary[.init("msg3")] = makeTextViewState(uniqueID: "msg3")
        state.itemsDictionary[.init("state-event")] = makeStateViewState(uniqueID: "state-event")
        state.itemsDictionary[.init("msg4")] = makeTextViewState(uniqueID: "msg4")
        state.recomputeReadMarkerState()

        #expect(state.unreadMessageCount == 2)
    }

    @Test("Unread count is zero when there is no read marker")
    func unreadMessageCountWithoutReadMarker() {
        var state = TimelineState()
        state.itemsDictionary[.init("msg1")] = makeTextViewState(uniqueID: "msg1")
        state.itemsDictionary[.init("msg2")] = makeTextViewState(uniqueID: "msg2")
        state.recomputeReadMarkerState()

        #expect(state.unreadMessageCount == 0)
    }

    // MARK: - Helpers

    private func makeTextViewState(uniqueID: String) -> RoomTimelineItemViewState {
        let item = TextRoomTimelineItem(id: .virtual(uniqueID: .init(uniqueID)),
                                        timestamp: .mock,
                                        isOutgoing: false,
                                        isEditable: false,
                                        canBeRepliedTo: true,
                                        sender: .init(id: "@sender:example.com"),
                                        content: .init(body: "Test message"))
        return RoomTimelineItemViewState(type: .text(item), groupStyle: .single)
    }

    private func makeReadMarkerViewState(uniqueID: String) -> RoomTimelineItemViewState {
        let item = ReadMarkerRoomTimelineItem(id: .virtual(uniqueID: .init(uniqueID)))
        return RoomTimelineItemViewState(type: .readMarker(item), groupStyle: .single)
    }

    private func makeSeparatorViewState(uniqueID: String) -> RoomTimelineItemViewState {
        let item = SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init(uniqueID)), timestamp: .mock)
        return RoomTimelineItemViewState(type: .separator(item), groupStyle: .single)
    }

    private func makeStateViewState(uniqueID: String) -> RoomTimelineItemViewState {
        let item = StateRoomTimelineItem(id: .virtual(uniqueID: .init(uniqueID)),
                                         body: "Alice joined",
                                         timestamp: .mock,
                                         isOutgoing: false,
                                         isEditable: false,
                                         canBeRepliedTo: false,
                                         sender: .init(id: "@sender:example.com"))
        return RoomTimelineItemViewState(type: .state(item), groupStyle: .single)
    }
}
