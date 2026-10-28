//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The live A2UI state of one message: its surfaces, the user's edits and the progress of actions.
///
/// Timeline items are rebuilt on every timeline update, so this object outlives them to keep the
/// user's input. New messages (from updates) are applied incrementally so edits survive them.
@Observable
final class A2UIMessageSurfaces {
    let eventID: String
    private(set) var surfaceSet = A2UISurfaceSet()
    private(set) var appliedMessages: [A2UIServerMessage] = []
    /// True while an action is being reported to the agent. Inputs stay editable, buttons are disabled.
    var isSendingAction = false
    /// Why the last action couldn't be sent, if it failed.
    var sendFailureMessage: String?
    
    var renderSurfaces: [A2UIRenderSurface] {
        surfaceSet.all.map { $0.resolve() }
    }
    
    init(eventID: String) {
        self.eventID = eventID
    }
    
    /// Applies the messages not seen yet. If the earlier messages changed (e.g. the event was
    /// edited or an update redacted), the surfaces are rebuilt from scratch instead.
    func update(messages: [A2UIServerMessage]) {
        guard messages != appliedMessages else { return }
        
        if messages.starts(with: appliedMessages) {
            for message in messages.dropFirst(appliedMessages.count) {
                surfaceSet.apply(message)
            }
        } else {
            surfaceSet = A2UISurfaceSet(messages: messages)
        }
        appliedMessages = messages
    }
    
    func setInputValue(_ value: JSONValue, surfaceID: String, key: A2UINodeKey, path: String?) {
        surfaceSet.setInputValue(value, surfaceID: surfaceID, key: key, path: path)
    }
    
    /// The action to report for a button press, with the data model when the agent asked for it.
    func resolveAction(surfaceID: String, key: A2UINodeKey) -> (action: A2UIResolvedAction, dataModel: JSONValue?)? {
        guard let surface = surfaceSet[surfaceID], let action = surface.resolveAction(for: key) else { return nil }
        return (action, surface.sendDataModel ? surface.dataModel ?? .null : nil)
    }
}

/// Keeps the A2UI state of each message in a timeline across timeline updates, keyed by event ID.
final class A2UISurfaceStore {
    private var messageSurfaces: [String: A2UIMessageSurfaces] = [:]
    
    /// The state for the item, created on first use and brought up to date with the item's messages.
    func surfaces(for item: A2UIRoomTimelineItem) -> A2UIMessageSurfaces? {
        guard let eventID = item.id.eventID else { return nil }
        let surfaces = messageSurfaces[eventID] ?? A2UIMessageSurfaces(eventID: eventID)
        messageSurfaces[eventID] = surfaces
        surfaces.update(messages: item.content.allMessages)
        return surfaces
    }
    
    func surfaces(forEventID eventID: String) -> A2UIMessageSurfaces? {
        messageSurfaces[eventID]
    }
    
    /// Brings the state of every A2UI item up to date, ahead of the views reading it.
    func update(with timelineItems: [RoomTimelineItemProtocol]) {
        for case let item as A2UIRoomTimelineItem in timelineItems {
            _ = surfaces(for: item)
        }
    }
    
    func removeAll() {
        messageSurfaces.removeAll()
    }
}
