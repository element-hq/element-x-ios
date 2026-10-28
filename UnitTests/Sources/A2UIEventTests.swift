//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDK
import Testing

struct A2UIEventTests {
    @Test
    func parsesMessagesFromEventJSON() throws {
        let content = try #require(A2UIEvent.content(ofEventJSON: A2UIFixtures.contactFormEventJSON))
        let messages = A2UIEvent.messages(in: content)
        
        #expect(messages.count == 3, "Entries that aren't objects are dropped.")
        #expect(messages[0].createSurface == .init(surfaceID: "main", sendDataModel: false))
        #expect(messages[1].updateComponents?.components.count == 6)
        #expect(messages[2].updateDataModel == .init(surfaceID: "main", path: "/", value: ["contact": ["name": "", "subscribe": false]]))
    }
    
    @Test
    func buildsActionContent() {
        let action = A2UIResolvedAction(name: "submitContactForm", sourceComponentID: "submit", context: ["formId": "contact_form_1"])
        let timestamp = Date(timeIntervalSince1970: 1_792_000_000)
        
        let content = A2UIEvent.actionContent(referencing: "$surface_event_id",
                                              surfaceID: "main",
                                              action: action,
                                              dataModel: ["contact": ["name": "Alice"]],
                                              timestamp: timestamp)
        
        #expect(content == [
            "m.relates_to": ["rel_type": "m.reference", "event_id": "$surface_event_id"],
            "version": "v0.9",
            "action": [
                "name": "submitContactForm",
                "surfaceId": "main",
                "sourceComponentId": "submit",
                "timestamp": "2026-10-14T20:26:40.000Z",
                "context": ["formId": "contact_form_1"]
            ],
            "dataModel": ["contact": ["name": "Alice"]]
        ])
        #expect(A2UIEvent.referencedEventID(in: content) == "$surface_event_id")
        
        let withoutDataModel = A2UIEvent.actionContent(referencing: "$surface_event_id", surfaceID: "main", action: action, dataModel: nil)
        #expect(withoutDataModel["dataModel"] == nil)
    }
    
    @Test
    func parsesUpdates() throws {
        let content: JSONValue = [
            "m.relates_to": ["rel_type": "m.reference", "event_id": "$surface_event_id"],
            "messages": [["version": "v0.9", "updateDataModel": ["surfaceId": "main", "path": "/contact/name", "value": "Alice"]]]
        ]
        
        let update = try #require(A2UIUpdate(content: content, senderID: "@agent:example.com"))
        #expect(update.referencedEventID == "$surface_event_id")
        #expect(update.messages == [.init(updateDataModel: .init(surfaceID: "main", path: "/contact/name", value: "Alice"))])
        
        #expect(A2UIUpdate(content: ["messages": []], senderID: "@agent:example.com") == nil)
        #expect(A2UIUpdate(content: ["m.relates_to": ["rel_type": "m.thread", "event_id": "$x"]], senderID: "@agent:example.com") == nil)
    }
    
    @Test
    func factoryBuildsA2UIItemsFromTheRawEvent() throws {
        let factory = RoomTimelineItemFactory(userID: "@alice:matrix.org",
                                              attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                              stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@alice:matrix.org"))
        
        let item = try #require(factory.buildTimelineItem(for: .a2uiMessage(latestJSON: A2UIFixtures.contactFormEventJSON), isDM: false) as? A2UIRoomTimelineItem)
        #expect(item.body == "Please fill in the contact form.")
        #expect(item.content.messages == A2UIFixtures.contactFormMessages)
        #expect(item.isForwardable == false)
        
        let otherItem = factory.buildTimelineItem(for: .otherMessage(msgtype: "org.example.custom"), isDM: false)
        #expect(otherItem == nil, "Other custom msgtypes still aren't rendered.")
    }
    
    @Test
    func updatesAreGroupedAndFilteredBySender() {
        let updateContent: (String) -> String = { value in
            """
            { "type": "io.element.a2ui.update", "content": {
                "m.relates_to": { "rel_type": "m.reference", "event_id": "$surface_event_id" },
                "messages": [{ "version": "v0.9", "updateDataModel": { "surfaceId": "main", "path": "/contact/name", "value": "\(value)" } }]
            } }
            """
        }
        
        let messageProxy = EventTimelineItemProxy.a2uiMessage(latestJSON: A2UIFixtures.contactFormEventJSON)
        let proxies: [TimelineItemProxy] = [
            .event(messageProxy),
            .event(.a2uiUpdate(latestJSON: updateContent("Alice"), sender: "@agent:example.com")),
            .event(.a2uiUpdate(latestJSON: updateContent("Mallory"), sender: "@mallory:example.com")),
            .event(.a2uiUpdate(latestJSON: updateContent("Bob"), sender: "@agent:example.com"))
        ]
        
        let updates = A2UIUpdate.updates(in: proxies)
        #expect(updates["$surface_event_id"]?.count == 3)
        
        let factory = RoomTimelineItemFactory(userID: "@alice:matrix.org",
                                              attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                              stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@alice:matrix.org"))
        guard let item = factory.buildTimelineItem(for: messageProxy, isDM: false) as? A2UIRoomTimelineItem else {
            Issue.record("Expected an A2UI item")
            return
        }
        
        let updated = item.applyingUpdates(updates["$surface_event_id"] ?? [])
        #expect(updated.content.updates.map(\.senderID) == ["@agent:example.com", "@agent:example.com"])
        #expect(updated.content.allMessages.count == 5)
        
        let surfaces = A2UIMessageSurfaces(eventID: "$surface_event_id")
        surfaces.update(messages: updated.content.allMessages)
        #expect(surfaces.surfaceSet["main"]?.dataModel?.value(at: "/contact/name") == "Bob")
    }
}

private extension EventTimelineItemProxy {
    static func a2uiMessage(latestJSON: String) -> EventTimelineItemProxy {
        let content = TimelineItemContent.msgLike(content: .init(kind: .message(content: .init(msgType: .other(msgtype: A2UIEvent.messageType,
                                                                                                               body: "Please fill in the contact form."),
                body: "Please fill in the contact form.",
                isEdited: false,
                mentions: nil)),
                                                                 inReplyTo: nil,
                                                                 threadRoot: nil,
                                                                 threadSummary: nil))
        let item = EventTimelineItem(configuration: .init(eventID: "$surface_event_id",
                                                          sender: "@agent:example.com",
                                                          content: content,
                                                          eventTypeRaw: "m.room.message",
                                                          latestJSON: latestJSON))
        return EventTimelineItemProxy(item: item, uniqueID: .init("surface"))
    }
    
    static func otherMessage(msgtype: String) -> EventTimelineItemProxy {
        let content = TimelineItemContent.msgLike(content: .init(kind: .message(content: .init(msgType: .other(msgtype: msgtype, body: "Hello"),
                                                                                               body: "Hello",
                                                                                               isEdited: false,
                                                                                               mentions: nil)),
                                                                 inReplyTo: nil,
                                                                 threadRoot: nil,
                                                                 threadSummary: nil))
        let item = EventTimelineItem(configuration: .init(sender: "@agent:example.com", content: content, eventTypeRaw: "m.room.message"))
        return EventTimelineItemProxy(item: item, uniqueID: .init(UUID().uuidString))
    }
    
    static func a2uiUpdate(latestJSON: String, sender: String) -> EventTimelineItemProxy {
        let content = TimelineItemContent.msgLike(content: .init(kind: .other(eventType: messageLikeEventTypeFromString(s: A2UIEvent.updateEventType)),
                                                                 inReplyTo: nil,
                                                                 threadRoot: nil,
                                                                 threadSummary: nil))
        let item = EventTimelineItem(configuration: .init(sender: sender,
                                                          content: content,
                                                          eventTypeRaw: A2UIEvent.updateEventType,
                                                          latestJSON: latestJSON))
        return EventTimelineItemProxy(item: item, uniqueID: .init(UUID().uuidString))
    }
}
