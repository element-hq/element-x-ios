//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@MainActor
struct ArrayTests {
    @Test
    func grouping() {
        #expect([].groupBy { $0 == 0 } == [])
        
        #expect([0].groupBy { $0 == 0 } == [[0]])
        
        #expect([1].groupBy { $0 == 0 } == [[1]])
        
        #expect([0, 0, 0].groupBy { $0 == 0 } == [[0, 0, 0]])
        
        #expect([1, 1, 1].groupBy { $0 == 0 } == [[1], [1], [1]])
        
        #expect([1, 0, 0, 1].groupBy { $0 == 0 } == [[1], [0, 0], [1]])
        
        #expect([0, 0, 1, 0].groupBy { $0 == 0 } == [[0, 0], [1], [0]])
        
        #expect([0, 0, 0, 1, 2, 3, 0].groupBy { $0 == 0 } == [[0, 0, 0], [1], [2], [3], [0]])
        
        #expect([0, 0, 0, 1, 2, 3, 0, 0].groupBy { $0 == 0 } == [[0, 0, 0], [1], [2], [3], [0, 0]])
        
        #expect([0, 0, 0, 1, 0, 2, 3, 0, 0].groupBy { $0 == 0 } == [[0, 0, 0], [1], [0], [2], [3], [0, 0]])
    }
    
    // MARK: - Voice message autoplay
    
    @Test
    func voiceMessageFollowsVoiceMessage() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id)?.id.uniqueID == .init("voice2"))
    }
    
    @Test
    func decorationsAreIgnored() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("separator")), timestamp: .mock),
                                                 ReadMarkerRoomTimelineItem(id: .virtual(uniqueID: .init("readMarker"))),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id)?.id.uniqueID == .init("voice2"))
    }
    
    @Test
    func otherMessagesBreakTheChain() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 makeTextMessage(uniqueID: "text"),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id) == nil)
    }
    
    @Test
    func lastItemHasNoFollowingVoiceMessage() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("separator")), timestamp: .mock)]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id) == nil)
    }
    
    @Test
    func precedingVoiceMessageIsIgnored() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[1].id) == nil)
    }
    
    @Test
    func unknownItemHasNoFollowingVoiceMessage() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(.virtual(uniqueID: .init("unknown"))) == nil)
    }
    
    // MARK: - Helpers
    
    private func makeVoiceMessage(uniqueID: String) -> VoiceMessageRoomTimelineItem {
        VoiceMessageRoomTimelineItem(id: .virtual(uniqueID: .init(uniqueID)),
                                     timestamp: .mock,
                                     isOutgoing: false,
                                     isEditable: false,
                                     canBeRepliedTo: true,
                                     sender: .init(id: "@sender:example.com"),
                                     content: .init(filename: "audio.ogg",
                                                    duration: 10,
                                                    waveform: .mockWaveform,
                                                    source: try? MediaSourceProxy(url: .mockMXCAudio, mimeType: nil),
                                                    fileSize: nil,
                                                    contentType: nil))
    }
    
    private func makeTextMessage(uniqueID: String) -> TextRoomTimelineItem {
        TextRoomTimelineItem(id: .virtual(uniqueID: .init(uniqueID)),
                             timestamp: .mock,
                             isOutgoing: false,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "@sender:example.com"),
                             content: .init(body: "Test message"))
    }
}
