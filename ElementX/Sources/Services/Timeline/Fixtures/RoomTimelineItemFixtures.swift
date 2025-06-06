//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomTimelineItemFixtures {
    /// The default timeline items used in Xcode previews etc.
    static var `default`: [RoomTimelineItemProtocol] = [
        SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("Yesterday")), timestamp: .mock),
        TextRoomTimelineItem(id: .event(uniqueID: .init(".RoomTimelineItemFixtures.default.0"),
                                        eventOrTransactionID: .eventID("RoomTimelineItemFixtures.default.0")),
                             timestamp: .mock,
                             isOutgoing: false,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "", displayName: "Jacob"),
                             content: .init(body: "That looks so good!"),
                             properties: RoomTimelineItemProperties(isEdited: true)),
        TextRoomTimelineItem(id: .event(uniqueID: .init("RoomTimelineItemFixtures.default.1"),
                                        eventOrTransactionID: .eventID("RoomTimelineItemFixtures.default.1")),
                             timestamp: .mock,
                             isOutgoing: false,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "", displayName: "Helena"),
                             content: .init(body: "Let’s get lunch soon! New salad place opened up 🥗. When are y’all free? 🤗"),
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(accountOwnerID: "me", key: "🙌", senders: [ReactionSender(id: "me", timestamp: Date())])
                             ])),
        TextRoomTimelineItem(id: .event(uniqueID: .init("RoomTimelineItemFixtures.default.2"),
                                        eventOrTransactionID: .eventID("RoomTimelineItemFixtures.default.2")),
                             timestamp: .mock,
                             isOutgoing: false,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "", displayName: "Helena"),
                             content: .init(body: "I can be around on Wednesday. How about some 🌮 instead? Like https://www.tortilla.co.uk/"),
                             properties: RoomTimelineItemProperties(reactions: [
                                 AggregatedReaction(accountOwnerID: "me", key: "🙏", senders: [ReactionSender(id: "helena", timestamp: Date())]),
                                 AggregatedReaction(accountOwnerID: "me",
                                                    key: "🙌",
                                                    senders: [
                                                        ReactionSender(id: "me", timestamp: Date()),
                                                        ReactionSender(id: "helena", timestamp: Date()),
                                                        ReactionSender(id: "jacob", timestamp: Date())
                                                    ])
                             ])),
        SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init("Today")), timestamp: .mock),
        TextRoomTimelineItem(id: .event(uniqueID: .init("RoomTimelineItemFixtures.default.3"),
                                        eventOrTransactionID: .eventID("RoomTimelineItemFixtures.default.3")),
                             timestamp: .mock,
                             isOutgoing: false,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "", displayName: "Helena"),
                             content: .init(body: "Wow, cool. Ok, lets go the usual place tomorrow?! Is that too soon?  Here’s the menu, let me know what you want it’s on me!"),
                             properties: RoomTimelineItemProperties(orderedReadReceipts: [ReadReceipt(userID: "alice", formattedTimestamp: nil)])),
        TextRoomTimelineItem(id: .event(uniqueID: .init("RoomTimelineItemFixtures.default.4"),
                                        eventOrTransactionID: .eventID("RoomTimelineItemFixtures.default.4")),
                             timestamp: .mock,
                             isOutgoing: true,
                             isEditable: true,
                             canBeRepliedTo: true,
                             sender: .init(id: "", displayName: "Bob"),
                             content: .init(body: "And John's speech was amazing!")),
        TextRoomTimelineItem(id: .event(uniqueID: .init("RoomTimelineItemFixtures.default.5"),
                                        eventOrTransactionID: .eventID("RoomTimelineItemFixtures.default.5")),
                             timestamp: .mock,
                             isOutgoing: true,
                             isEditable: true,
                             canBeRepliedTo: true,
                             sender: .init(id: "", displayName: "Bob"),
                             content: .init(body: "New home office set up!"),
                             properties: RoomTimelineItemProperties(reactions: AggregatedReaction.mockReactions,
                                                                    orderedReadReceipts: [ReadReceipt(userID: "alice", formattedTimestamp: nil),
                                                                                          ReadReceipt(userID: "bob", formattedTimestamp: nil),
                                                                                          ReadReceipt(userID: "charlie", formattedTimestamp: nil),
                                                                                          ReadReceipt(userID: "dan", formattedTimestamp: nil)])),
        TextRoomTimelineItem(id: .event(uniqueID: .init("RoomTimelineItemFixtures.default.6"),
                                        eventOrTransactionID: .eventID("RoomTimelineItemFixtures.default.6")),
                             timestamp: .mock,
                             isOutgoing: false,
                             isEditable: false,
                             canBeRepliedTo: true,
                             sender: .init(id: "", displayName: "Helena"),
                             content: .init(body: "",
                                            formattedBody: AttributedStringBuilder(mentionBuilder: MentionBuilder())
                                                .fromHTML("Hol' up <blockquote>New home office set up!</blockquote>That's amazing! Congrats 🥳")))
    ]
    
    /// A small chunk of events, containing 2 text items.
    static var smallChunk: [RoomTimelineItemProtocol] {
        [TextRoomTimelineItem(text: "Hey there 👋",
                              senderDisplayName: "Alice"),
         TextRoomTimelineItem(text: "How are you?",
                              senderDisplayName: "Alice")]
    }

    /// A small chunk of events, containing 2 text items.
    static var smallChunkWithReadReceipts: [RoomTimelineItemProtocol] {
        [TextRoomTimelineItem(text: "Hey there 👋",
                              senderDisplayName: "Alice")
                .withReadReceipts([ReadReceipt(userID: "a1", formattedTimestamp: nil)]),
            TextRoomTimelineItem(text: "How are you?",
                                 senderDisplayName: "Alice")
                .withReadReceipts([ReadReceipt(userID: "a2", formattedTimestamp: nil),
                                   ReadReceipt(userID: "b2", formattedTimestamp: nil)]),
            TextRoomTimelineItem(text: "Fine, Thanks!",
                                 senderDisplayName: "Bob")
                .withReadReceipts([ReadReceipt(userID: "a3", formattedTimestamp: nil),
                                   ReadReceipt(userID: "b3", formattedTimestamp: nil),
                                   ReadReceipt(userID: "c3", formattedTimestamp: nil)]),
            TextRoomTimelineItem(text: "What about you?",
                                 senderDisplayName: "Bob")
                .withReadReceipts([ReadReceipt(userID: "a4", formattedTimestamp: nil),
                                   ReadReceipt(userID: "b4", formattedTimestamp: nil),
                                   ReadReceipt(userID: "c4", formattedTimestamp: nil),
                                   ReadReceipt(userID: "d4", formattedTimestamp: nil)])]
    }
    
    /// A chunk of events that contains a single text item.
    static var singleMessageChunk: [RoomTimelineItemProtocol] {
        [TextRoomTimelineItem(text: "Tap tap tap 🎙️. Is this thing on?",
                              senderDisplayName: "Helena")]
    }
    
    /// A single text item.
    static var incomingMessage: RoomTimelineItemProtocol {
        TextRoomTimelineItem(text: "Hello, World!",
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

    static var disclosedPolls: [RoomTimelineItemProtocol] {
        [PollRoomTimelineItem.mock(poll: .disclosed(), isOutgoing: false),
         PollRoomTimelineItem.mock(poll: .endedDisclosed)]
    }

    static var undisclosedPolls: [RoomTimelineItemProtocol] {
        [PollRoomTimelineItem.mock(poll: .undisclosed(), isOutgoing: false),
         PollRoomTimelineItem.mock(poll: .endedUndisclosed)]
    }

    static var outgoingPolls: [RoomTimelineItemProtocol] {
        [PollRoomTimelineItem.mock(poll: .disclosed(createdByAccountOwner: true), isOutgoing: true)]
    }
    
    static var permalinkChunk: [RoomTimelineItemProtocol] {
        (1...20).map { index in
            TextRoomTimelineItem(id: .event(uniqueID: .init("\(index)"), eventOrTransactionID: .eventID("$\(index)")),
                                 text: "Message ID \(index)",
                                 senderDisplayName: index > 10 ? "Alice" : "Bob")
        }
    }
    
    static var mediaChunk: [RoomTimelineItemProtocol] {
        [
            AudioRoomTimelineItem(isOutgoing: false, caption: "Listen to this!"),
            AudioRoomTimelineItem(isOutgoing: true),
            FileRoomTimelineItem(isOutgoing: false),
            FileRoomTimelineItem(isOutgoing: true, caption: "Please check this ASAP!"),
            ImageRoomTimelineItem(isOutgoing: false),
            ImageRoomTimelineItem(isOutgoing: true, caption: "Isn't this pretty!"),
            VideoRoomTimelineItem(isOutgoing: false, caption: "Woah, it was incredible!"),
            VideoRoomTimelineItem(isOutgoing: true),
            VoiceMessageRoomTimelineItem(isOutgoing: false),
            VoiceMessageRoomTimelineItem(isOutgoing: true)
        ]
    }
    
    static var separator: SeparatorRoomTimelineItem {
        SeparatorRoomTimelineItem(id: .virtual(uniqueID: .init(UUID().uuidString)),
                                  timestamp: .now)
    }
}

private extension TextRoomTimelineItem {
    init(id: TimelineItemIdentifier? = nil, text: String, senderDisplayName: String) {
        self.init(id: id ?? .randomEvent,
                  timestamp: .mock,
                  isOutgoing: senderDisplayName == "Alice",
                  isEditable: false,
                  canBeRepliedTo: true,
                  sender: .init(id: "", displayName: senderDisplayName),
                  content: .init(body: text))
    }
    
    func withReadReceipts(_ receipts: [ReadReceipt]) -> TextRoomTimelineItem {
        var newSelf = self
        newSelf.properties.orderedReadReceipts = receipts
        return newSelf
    }
}

private extension AudioRoomTimelineItem {
    init(isOutgoing: Bool, caption: String? = nil) {
        self.init(id: .randomEvent,
                  timestamp: .mock,
                  isOutgoing: isOutgoing,
                  isEditable: isOutgoing,
                  canBeRepliedTo: true,
                  sender: .init(id: isOutgoing ? "@alice:matrix.org" : "@bob:matrix.org"),
                  content: .init(filename: "audio.mp3",
                                 caption: caption,
                                 duration: 60,
                                 waveform: nil,
                                 source: try? .init(url: .mockMXCAudio, mimeType: nil),
                                 fileSize: nil,
                                 contentType: .mp3))
    }
}

private extension FileRoomTimelineItem {
    init(isOutgoing: Bool, caption: String? = nil) {
        self.init(id: .randomEvent,
                  timestamp: .mock,
                  isOutgoing: isOutgoing,
                  isEditable: isOutgoing,
                  canBeRepliedTo: true,
                  sender: .init(id: isOutgoing ? "@alice:matrix.org" : "@bob:matrix.org"),
                  content: .init(filename: "file.pdf",
                                 caption: caption,
                                 source: try? .init(url: .mockMXCFile, mimeType: nil),
                                 fileSize: nil,
                                 thumbnailSource: nil,
                                 contentType: .pdf))
    }
}

private extension ImageRoomTimelineItem {
    init(isOutgoing: Bool, caption: String? = nil) {
        self.init(id: .randomEvent,
                  timestamp: .mock,
                  isOutgoing: isOutgoing,
                  isEditable: isOutgoing,
                  canBeRepliedTo: true,
                  sender: .init(id: isOutgoing ? "@alice:matrix.org" : "@bob:matrix.org"),
                  content: .init(filename: "image.jpg",
                                 caption: caption,
                                 imageInfo: .mockImage,
                                 thumbnailInfo: nil,
                                 blurhash: "KpE4oyayR5|GbHb];3j@of"))
    }
}

private extension VideoRoomTimelineItem {
    init(isOutgoing: Bool, caption: String? = nil) {
        self.init(id: .randomEvent,
                  timestamp: .mock,
                  isOutgoing: isOutgoing,
                  isEditable: isOutgoing,
                  canBeRepliedTo: true,
                  sender: .init(id: isOutgoing ? "@alice:matrix.org" : "@bob:matrix.org"),
                  content: .init(filename: "video.mp4",
                                 caption: caption,
                                 videoInfo: .mockVideo,
                                 thumbnailInfo: .mockVideoThumbnail,
                                 blurhash: "KtI~70X5V?yss9oyrYs:t6"))
    }
}

private extension VoiceMessageRoomTimelineItem {
    init(isOutgoing: Bool) {
        self.init(id: .randomEvent,
                  timestamp: .mock,
                  isOutgoing: isOutgoing,
                  isEditable: isOutgoing,
                  canBeRepliedTo: true,
                  sender: .init(id: isOutgoing ? "@alice:matrix.org" : "@bob:matrix.org"),
                  content: .init(filename: "message.ogg",
                                 duration: 10,
                                 waveform: .mockWaveform,
                                 source: try? .init(url: .mockMXCAudio, mimeType: nil),
                                 fileSize: nil,
                                 contentType: .audio))
    }
}
