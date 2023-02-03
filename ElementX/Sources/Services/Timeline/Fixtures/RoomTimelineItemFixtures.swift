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

import Foundation

enum RoomTimelineItemFixtures {
    /// The default timeline items used in Xcode previews etc.
    static var `default`: [RoomTimelineItemProtocol] = [
        SeparatorRoomTimelineItem(text: "Yesterday"),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "That looks so good!",
                             timestamp: "10:10 AM",
                             groupState: .single,
                             isOutgoing: false,
                             isEditable: false,
                             sender: .init(id: "", displayName: "Jacob"),
                             properties: RoomTimelineItemProperties(isEdited: true)),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "Let’s get lunch soon! New salad place opened up 🥗. When are y’all free? 🤗",
                             timestamp: "10:11 AM",
                             groupState: .beginning,
                             isOutgoing: false,
                             isEditable: false,
                             sender: .init(id: "", displayName: "Helena"),
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(key: "🙌", count: 1, isHighlighted: true)
                             ])),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "I can be around on Wednesday. How about some 🌮 instead? Like https://www.tortilla.co.uk/",
                             timestamp: "10:11 AM",
                             groupState: .end,
                             isOutgoing: false,
                             isEditable: false,
                             sender: .init(id: "", displayName: "Helena"),
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(key: "🙏", count: 1, isHighlighted: false),
                                 AggregatedReaction(key: "🙌", count: 2, isHighlighted: true)
                             ])),
        SeparatorRoomTimelineItem(text: "Today"),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "Wow, cool. Ok, lets go the usual place tomorrow?! Is that too soon?  Here’s the menu, let me know what you want it’s on me!",
                             timestamp: "5 PM",
                             groupState: .single,
                             isOutgoing: false,
                             isEditable: false,
                             sender: .init(id: "", displayName: "Helena")),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "And John's speech was amazing!",
                             timestamp: "5 PM",
                             groupState: .beginning,
                             isOutgoing: true,
                             isEditable: true,
                             sender: .init(id: "", displayName: "Bob")),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "New home office set up!",
                             timestamp: "5 PM",
                             groupState: .end,
                             isOutgoing: true,
                             isEditable: true,
                             sender: .init(id: "", displayName: "Bob"),
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(key: "🙏", count: 1, isHighlighted: false),
                                 AggregatedReaction(key: "😁", count: 3, isHighlighted: false)
                             ])),
        TextRoomTimelineItem(id: UUID().uuidString,
                             text: "",
                             attributedComponents: [
                                 AttributedStringBuilderComponent(attributedString: "Hol' up", isBlockquote: false, isReply: false),
                                 AttributedStringBuilderComponent(attributedString: "New home office set up!", isBlockquote: true, isReply: false),
                                 AttributedStringBuilderComponent(attributedString: "That's amazing! Congrats 🥳", isBlockquote: false, isReply: false)
                             ],
                             timestamp: "5 PM",
                             groupState: .single,
                             isOutgoing: false,
                             isEditable: false,
                             sender: .init(id: "", displayName: "Helena"))
    ]
    
    /// A small chunk of events, containing 2 text items.
    static var smallChunk: [RoomTimelineItemProtocol] {
        [TextRoomTimelineItem(text: "Hey there 👋",
                              groupState: .beginning,
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "How are you?",
                              groupState: .end,
                              senderDisplayName: "Alice")]
    }
    
    /// A chunk of events that contains a single text item.
    static var singleMessageChunk: [RoomTimelineItemProtocol] {
        [TextRoomTimelineItem(text: "Tap tap tap 🎙️. Is this thing on?",
                              groupState: .single,
                              senderDisplayName: "Helena")]
    }
    
    /// A single text item.
    static var incomingMessage: RoomTimelineItemProtocol {
        TextRoomTimelineItem(text: "Hello, World!",
                             groupState: .single,
                             senderDisplayName: "Bob")
    }
    
    /// A large chunk of events, containing 40 text items which should fill an iPad
    /// with enough items so that it won't perform another back pagination.
    static var largeChunk: [RoomTimelineItemProtocol] {
        [TextRoomTimelineItem(text: "Bacon ipsum dolor amet commodo incididunt ribeye dolore cupidatat short ribs.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Labore ipsum jowl meatloaf adipisicing ham leberkas.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Tongue culpa dolor, short ribs doner cillum do rump id nulla mollit.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Capicola laborum aute porchetta, kevin ut ut bacon swine kielbasa beef rump ipsum.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Leberkas beef ad salami flank laborum ex veniam excepteur picanha occaecat burgdoggen.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Magna leberkas nostrud laboris, biltong in tongue nulla et id drumstick brisket.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Landjaeger adipisicing spare ribs sunt pig voluptate beef ribs venison ut meatloaf nulla beef sed.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Bacon chicken excepteur, filet mignon pastrami meatball ribeye sunt sausage.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Ham et dolore, nisi adipisicing kielbasa andouille ribeye enim chicken.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Ribeye prosciutto aliquip tail dolore.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Salami culpa exercitation ea non rump consectetur ipsum boudin irure jerky spare ribs duis leberkas pastrami.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Andouille shankle magna pig corned beef strip steak ex landjaeger sed chicken drumstick.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Deserunt ea esse quis bresaola, ham hock sirloin spare ribs porchetta dolore ham nisi est.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Consectetur nulla laboris, rump minim tempor turducken sunt tongue in.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Ea ut laboris eu spare ribs occaecat esse et shankle chicken.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Frankfurter brisket eu, landjaeger ea ham hamburger rump eiusmod pastrami cow.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Qui prosciutto sed, officia occaecat drumstick non veniam in elit chicken capicola buffalo beef ribs irure.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "In pork loin lorem, pariatur tail cupim voluptate chicken id eu pancetta esse pastrami.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Excepteur minim ea est, jerky sirloin frankfurter nisi dolor ball tip.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Shank corned beef velit chislic, pork chop enim in chuck in excepteur fatback minim.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Mollit minim ipsum in, in do doner ribeye cow jowl short loin sed.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Meatloaf est hamburger, spare ribs pork belly officia dolor.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Pancetta do aliqua picanha tempor.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Ad pig incididunt doner pork chop flank velit capicola aliqua.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Ullamco ex qui kevin meatball, leberkas hamburger venison.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Capicola et esse, fatback porchetta filet mignon ham nulla salami shank.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Boudin adipisicing pancetta chuck spare ribs beef ribs, in ut pork kevin.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Adipisicing pig short loin hamburger nisi exercitation landjaeger pancetta picanha ex cupim beef ribs.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Burgdoggen tri-tip eu elit consectetur, hamburger dolore commodo bacon capicola esse ex exercitation anim nostrud.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Id burgdoggen bresaola pork.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Pariatur meatloaf dolore tenderloin ea et proident strip steak velit nostrud pork loin laboris.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Pork chop cupim pastrami, prosciutto chislic kevin tempor eu ut deserunt ut occaecat consectetur non.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Aliquip kevin fugiat esse, adipisicing bresaola andouille biltong.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Andouille est picanha, beef ribs boudin exercitation flank venison ea tongue landjaeger meatloaf velit.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Boudin rump hamburger laborum adipisicing consectetur officia frankfurter shoulder quis biltong fugiat esse.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Ham hock culpa corned beef cupim pastrami swine in.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Boudin adipisicing pancetta chuck spare ribs beef ribs, in ut pork kevin.",
                              senderDisplayName: "Bob"),
         TextRoomTimelineItem(text: "Aliquip meatball incididunt fatback, pork belly in jowl tri-tip commodo spare ribs.",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "Excepteur rump tri-tip culpa in shankle esse ut.",
                              senderDisplayName: "Helena"),
         TextRoomTimelineItem(text: "Pork buffalo mollit culpa strip steak in leberkas flank cow.",
                              senderDisplayName: "Alice")]
    }
}

private extension TextRoomTimelineItem {
    init(text: String, groupState: TimelineItemGroupState = .single, senderDisplayName: String) {
        self.init(id: UUID().uuidString,
                  text: text,
                  timestamp: "10:47 am",
                  groupState: groupState,
                  isOutgoing: senderDisplayName == "Alice",
                  isEditable: false,
                  sender: .init(id: "", displayName: senderDisplayName))
    }
}
