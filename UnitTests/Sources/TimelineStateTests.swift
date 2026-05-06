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
    // MARK: - Read marker

    @Test("Read marker unique ID is captured when present in the timeline")
    func readMarkerUniqueIDPresent() {
        var state = TimelineState()
        state.itemsDictionary[.init("msg1")] = makeTextViewState(uniqueID: "msg1")
        state.itemsDictionary[.init("read-marker")] = makeReadMarkerViewState(uniqueID: "read-marker")
        state.itemsDictionary[.init("msg2")] = makeTextViewState(uniqueID: "msg2")
        state.recomputeReadMarkerUniqueID()

        #expect(state.readMarkerUniqueID == .init("read-marker"))
    }

    @Test("Read marker unique ID is nil when no marker exists")
    func readMarkerUniqueIDAbsent() {
        var state = TimelineState()
        state.itemsDictionary[.init("msg1")] = makeTextViewState(uniqueID: "msg1")
        state.itemsDictionary[.init("msg2")] = makeTextViewState(uniqueID: "msg2")
        state.recomputeReadMarkerUniqueID()

        #expect(state.readMarkerUniqueID == nil)
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
}
