//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation

class MockRoomTimelineController: RoomTimelineControllerProtocol {
    let roomId = "MockRoomIdentifier"
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    var timelineItems: [RoomTimelineItemProtocol] = [
        SeparatorRoomTimelineItem(id: UUID().uuidString,
                                  text: "Yesterday"),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "That looks so good!",
                             timestamp: "10:10 AM",
                             inGroupState: .single,
                             isOutgoing: false,
                             isEditable: false,
                             senderId: "",
                             senderDisplayName: "Jacob",
                             properties: RoomTimelineItemProperties(isEdited: true)),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "Let’s get lunch soon! New salad place opened up 🥗. When are y’all free? 🤗",
                             timestamp: "10:11 AM",
                             inGroupState: .beginning,
                             isOutgoing: false,
                             isEditable: false,
                             senderId: "",
                             senderDisplayName: "Helena",
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(key: "🙌", count: 1, isHighlighted: true)
                             ])),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "I can be around on Wednesday. How about some 🌮 instead? Like https://www.tortilla.co.uk/",
                             timestamp: "10:11 AM",
                             inGroupState: .end,
                             isOutgoing: false,
                             isEditable: false,
                             senderId: "",
                             senderDisplayName: "Helena",
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(key: "🙏", count: 1, isHighlighted: false),
                                 AggregatedReaction(key: "🙌", count: 2, isHighlighted: true)
                             ])),
        SeparatorRoomTimelineItem(id: UUID().uuidString,
                                  text: "Today"),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "Wow, cool. Ok, lets go the usual place tomorrow?! Is that too soon?  Here’s the menu, let me know what you want it’s on me!",
                             timestamp: "5 PM",
                             inGroupState: .single,
                             isOutgoing: false,
                             isEditable: false,
                             senderId: "",
                             senderDisplayName: "Helena"),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "And John's speech was amazing!",
                             timestamp: "5 PM",
                             inGroupState: .beginning,
                             isOutgoing: true,
                             isEditable: true,
                             senderId: "",
                             senderDisplayName: "Bob"),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "New home office set up!",
                             timestamp: "5 PM",
                             inGroupState: .end,
                             isOutgoing: true,
                             isEditable: true,
                             senderId: "",
                             senderDisplayName: "Bob",
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(key: "🙏", count: 1, isHighlighted: false),
                                 AggregatedReaction(key: "😁", count: 3, isHighlighted: false)
                             ])),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "",
                             attributedComponents: [
                                 AttributedStringBuilderComponent(attributedString: "Hol' up", isBlockquote: false),
                                 AttributedStringBuilderComponent(attributedString: "New home office set up!", isBlockquote: true),
                                 AttributedStringBuilderComponent(attributedString: "That's amazing! Congrats 🥳", isBlockquote: false)
                             ],
                             timestamp: "5 PM",
                             inGroupState: .single,
                             isOutgoing: false,
                             isEditable: false,
                             senderId: "",
                             senderDisplayName: "Helena")
    ]
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError> {
        .failure(.generic)
    }
    
    func processItemAppearance(_ itemId: String) async { }
    
    func processItemDisappearance(_ itemId: String) async { }
    
    func sendMessage(_ message: String) async { }
    
    func sendReply(_ message: String, to itemId: String) async { }
    
    func redact(_ eventID: String) async { }
}
