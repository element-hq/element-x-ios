//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

struct TimelineControllerTests {
    // MARK: - Date Divider Filtering
    
    @Test
    func noDividers() {
        let items: [RoomTimelineItemProtocol] = [mockText(), mockText()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.count == 2)
    }
    
    @Test
    func singleDividerWithContent() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator(), mockText()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.count == 2)
    }
    
    @Test
    func singleDividerAtEnd() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.isEmpty)
    }
    
    @Test
    func twoDividersNoContent() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator(), mockSeparator()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.count == 1)
        #expect(result[0] is SeparatorRoomTimelineItem)
    }
    
    @Test
    func twoDividersWithContentBetween() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator(), mockText(), mockSeparator()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.count == 3)
    }
    
    @Test
    func threeDividersWithContentAfterLast() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator(), mockSeparator(), mockSeparator(), mockText()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        // The first two separators should be removed (next non-pagination is also a separator),
        // the third should be kept (text follows).
        #expect(result.count == 2)
        #expect(result[0] is SeparatorRoomTimelineItem)
        #expect(result[1] is TextRoomTimelineItem)
    }
    
    @Test
    func dividerThenPaginationThenDivider() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator(), PaginationIndicatorRoomTimelineItem(position: .start), mockSeparator()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.isEmpty)
    }
    
    @Test
    func dividerThenPaginationThenContent() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator(), PaginationIndicatorRoomTimelineItem(position: .start), mockText()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        // Divider kept — content follows (pagination indicators are ignored).
        #expect(result.count == 3)
    }
    
    @Test
    func noItems() {
        let items: [RoomTimelineItemProtocol] = []
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.isEmpty)
    }
    
    @Test
    func onlyContent() {
        let items: [RoomTimelineItemProtocol] = [mockText(), mockText(), mockText()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.count == 3)
    }
    
    @Test
    func onlyPaginationIndicators() {
        let items: [RoomTimelineItemProtocol] = [PaginationIndicatorRoomTimelineItem(position: .start), PaginationIndicatorRoomTimelineItem(position: .end)]
        let result = TimelineController.stripOrphanedDateDividers(items)
        #expect(result.count == 2)
    }
    
    @Test
    func dividerAtStartWithContentAfterPagination() {
        let items: [RoomTimelineItemProtocol] = [mockSeparator(), PaginationIndicatorRoomTimelineItem(position: .start), mockText(), mockSeparator()]
        let result = TimelineController.stripOrphanedDateDividers(items)
        // First separator kept (content after pagination), last separator kept (end).
        #expect(result.count == 4)
    }
    
    // MARK: - Helpers
    
    private func mockSeparator() -> SeparatorRoomTimelineItem {
        SeparatorRoomTimelineItem(id: .randomVirtual, timestamp: Date())
    }
    
    private func mockText() -> TextRoomTimelineItem {
        TextRoomTimelineItem(id: .randomEvent,
                             timestamp: Date(),
                             isOutgoing: false,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "@alice:matrix.org"),
                             content: .init(body: "Hello"))
    }
}
