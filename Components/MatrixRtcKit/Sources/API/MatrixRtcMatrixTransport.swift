//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A to-device message delivered by the homeserver. Only encrypted messages are trusted, and the sender
/// is the cryptographically attested one, never the one claimed in the content.
public nonisolated struct MatrixRtcToDeviceMessage: Sendable {
    public let eventType: String
    public let attestedSenderID: String
    public let senderDeviceID: String?
    public let isSenderCrossSigned: Bool
    public let wasEncrypted: Bool
    public let contentJSON: String
    
    public init(eventType: String, attestedSenderID: String, senderDeviceID: String?, isSenderCrossSigned: Bool, wasEncrypted: Bool, contentJSON: String) {
        self.eventType = eventType
        self.attestedSenderID = attestedSenderID
        self.senderDeviceID = senderDeviceID
        self.isSenderCrossSigned = isSenderCrossSigned
        self.wasEncrypted = wasEncrypted
        self.contentJSON = contentJSON
    }
}

public nonisolated struct MatrixRtcRoomStateEvent: Sendable, Hashable {
    public let eventID: String?
    public let eventType: String
    public let stateKey: String
    public let sender: String
    public let originServerTimestamp: Date?
    public let contentJSON: String
    
    public init(eventID: String?, eventType: String, stateKey: String, sender: String, originServerTimestamp: Date?, contentJSON: String) {
        self.eventID = eventID
        self.eventType = eventType
        self.stateKey = stateKey
        self.sender = sender
        self.originServerTimestamp = originServerTimestamp
        self.contentJSON = contentJSON
    }
}

public nonisolated enum MatrixRtcDelayedEventAction: Sendable {
    case cancel, restart
}

/// How the host reports a failed send; the core reacts differently to each.
public nonisolated enum MatrixRtcTransportError: Error, Sendable, Equatable {
    /// A permanent refusal (e.g. the homeserver doesn't implement delayed events): the core retires
    /// the feature for the session instead of retrying it.
    case notSupported(String)
    /// A transient failure the core may retry.
    case failed(String)
}

/// The Matrix side the core needs, implemented by the app with its SDK proxies. The framework never
/// imports the Matrix SDK, so this is the whole contract between the two.
public nonisolated protocol MatrixRtcMatrixTransport: AnyObject, Sendable {
    var userID: String { get }
    var deviceID: String { get }
    
    // MARK: Sends (the core decides *what*, these decide *how*)
    
    /// - Returns: the event ID.
    func sendStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String) async throws -> String
    /// - Returns: the event ID, or an empty string when the SDK doesn't report one.
    func sendStickyEvent(roomID: String, eventType: String, contentJSON: String, durationMs: UInt64) async throws -> String
    /// - Returns: the delay ID.
    func sendDelayedEvent(roomID: String, eventType: String, contentJSON: String, delayMs: UInt64) async throws -> String
    /// - Returns: the delay ID.
    func sendDelayedStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String, delayMs: UInt64) async throws -> String
    func updateDelayedEvent(roomID: String, delayID: String, action: MatrixRtcDelayedEventAction) async throws
    /// Must be encrypted. `messages` is user ID → device ID → content JSON.
    /// - Returns: the recipients that were **not** served, user ID → device IDs.
    func sendToDeviceMessage(eventType: String, messages: [String: [String: String]]) async throws -> [String: [String]]
    /// - Returns: the event ID.
    func sendRoomEvent(roomID: String, eventType: String, contentJSON: String) async throws -> String
    func redactEvent(roomID: String, eventID: String, reason: String?) async throws
    
    func requestOpenIDToken() async throws -> MatrixRtcOpenIDToken
    
    // MARK: Feeds
    
    /// Every to-device message of the given types for as long as the stream is iterated. Must be
    /// subscribed for the whole Matrix session: to-device delivery cannot be caught up on.
    func toDeviceMessages(eventTypes: [String]) -> AsyncStream<MatrixRtcToDeviceMessage>
    /// The full current list of state events of that type, immediately and on every change.
    func roomStateEvents(roomID: String, eventType: String) -> AsyncStream<[MatrixRtcRoomStateEvent]>
    /// The user IDs currently joined to the room, immediately and on every change. Never emits an empty list.
    func joinedMemberIDs(roomID: String) -> AsyncStream<[String]>
    func isRoomEncrypted(roomID: String) async -> Bool
    
    // MARK: Lifecycle
    
    /// Per-room setup the host needs before anything is fed or sent for the room. Default: nothing.
    func willJoinRoom(roomID: String) async throws
    /// The session for the room is gone (left, or the join failed). Default: nothing.
    func didLeaveRoom(roomID: String) async
}

public extension MatrixRtcMatrixTransport {
    func willJoinRoom(roomID: String) async throws { }
    func didLeaveRoom(roomID: String) async { }
}
