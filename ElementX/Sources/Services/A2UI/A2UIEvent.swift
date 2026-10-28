//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The Matrix event formats used to carry A2UI over a room timeline.
///
/// This is a prototype mapping, shared with Element Web, and the names use the `io.element` unstable prefix:
/// - An agent renders UI by sending an `m.room.message` with `msgtype` ``messageType``. Its `body` is a
///   plain-text fallback for clients without A2UI support and `messages` holds the server-to-client messages
///   that build the surfaces.
/// - The agent updates an existing surface with an ``updateEventType`` event carrying further `messages`,
///   related to the original message with `m.reference`. Only updates from the original sender are applied.
/// - When the user presses a button, the client sends an ``actionEventType`` event with the A2UI `action`
///   message, again related to the original message with `m.reference`.
nonisolated enum A2UIEvent {
    /// The protocol version this implementation understands.
    static let version = "v0.9"
    static let messageType = "io.element.a2ui"
    static let updateEventType = "io.element.a2ui.update"
    static let actionEventType = "io.element.a2ui.action"
    
    /// The `content` of an event, given its full JSON as the SDK provides it.
    static func content(ofEventJSON eventJSON: String) -> JSONValue? {
        JSONValue(jsonString: eventJSON)?["content"]
    }
    
    /// The A2UI messages in an event's content, dropping anything that isn't an object.
    static func messages(in content: JSONValue) -> [A2UIServerMessage] {
        (content["messages"]?.arrayValue ?? []).compactMap(A2UIServerMessage.init)
    }
    
    /// The event ID that the content relates to with `m.reference`, if any.
    static func referencedEventID(in content: JSONValue) -> String? {
        guard let relation = content["m.relates_to"], relation["rel_type"]?.stringValue == "m.reference" else {
            return nil
        }
        return relation["event_id"]?.stringValue
    }
    
    /// The content of the event reporting a user action to the agent.
    static func actionContent(referencing eventID: String,
                              surfaceID: String,
                              action: A2UIResolvedAction,
                              dataModel: JSONValue?,
                              timestamp: Date = .now) -> JSONValue {
        var content: [String: JSONValue] = [
            "m.relates_to": ["rel_type": "m.reference", "event_id": .string(eventID)],
            "version": .string(version),
            "action": .object([
                "name": .string(action.name),
                "surfaceId": .string(surfaceID),
                "sourceComponentId": .string(action.sourceComponentID),
                "timestamp": .string(Date.ISO8601FormatStyle(includingFractionalSeconds: true).format(timestamp)),
                "context": .object(action.context)
            ])
        ]
        if let dataModel {
            content["dataModel"] = dataModel
        }
        return .object(content)
    }
}

/// An ``A2UIEvent/updateEventType`` event, ready to be matched to the message it updates.
nonisolated struct A2UIUpdate: Hashable, Sendable {
    let senderID: String
    let referencedEventID: String
    let messages: [A2UIServerMessage]
    
    init?(content: JSONValue, senderID: String) {
        guard let referencedEventID = A2UIEvent.referencedEventID(in: content) else { return nil }
        self.senderID = senderID
        self.referencedEventID = referencedEventID
        messages = A2UIEvent.messages(in: content)
    }
}
