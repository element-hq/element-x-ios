//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct VoiceMessageAutoplayTests {
    @Test("The directly following voice message is found")
    func voiceMessageFollowsVoiceMessage() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id)?.id.uniqueID == .init("voice2"))
    }
    
    @Test("Decorations don't break the chain of voice messages")
    func decorationsAreIgnored() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("separator")), timestamp: .mock),
                                                 ReadMarkerRoomTimelineItem(id: .virtual(uniqueID: .init("readMarker"))),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id)?.id.uniqueID == .init("voice2"))
    }
    
    @Test("Another kind of message breaks the chain of voice messages")
    func otherMessagesBreakTheChain() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 makeTextMessage(uniqueID: "text"),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id) == nil)
    }
    
    @Test("The last voice message of the timeline isn't followed by anything")
    func lastItemHasNoFollowingVoiceMessage() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("separator")), timestamp: .mock)]
        
        #expect(items.voiceMessageDirectlyFollowing(items[0].id) == nil)
    }
    
    @Test("The preceding voice message isn't considered")
    func precedingVoiceMessageIsIgnored() {
        let items: [RoomTimelineItemProtocol] = [makeVoiceMessage(uniqueID: "voice1"),
                                                 makeVoiceMessage(uniqueID: "voice2")]
        
        #expect(items.voiceMessageDirectlyFollowing(items[1].id) == nil)
    }
    
    @Test("An unknown item has no following voice message")
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
