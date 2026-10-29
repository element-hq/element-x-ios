//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
import Foundation
import MatrixRustSDK

/// The call's Matrix backend over a Rust SDK `Client`, for a host that has an SDK client to hand to
/// `ElementCallController`. The reference a host copies, so the package carries no SDK dependency and
/// never holds back a host's SDK bump. The example itself has no client and runs on fakes, so this is
/// compiled and its mappings are unit-tested, but it is never run here.
///
/// One per Matrix session, alive between calls. The core calls it from its own threads, and the SDK
/// calls the listeners below from its own; the core's sinks only post to a channel, so events are
/// delivered straight from the SDK's callbacks, with nothing buffered in between.
///
/// Every type in these files is marked `nonisolated` although this target does not need it: a host
/// whose default isolation is the main actor, as Element X's is, must be able to copy them unchanged.
final nonisolated class SDKMatrixBackend: ElementCallMatrixBackendProtocol {
    static let redactionEventType = "m.room.redaction"
    /// The core retries a failed send itself, within its own budget, so the SDK must not retry underneath it.
    static let noRetry = RequestConfigOverride(retryLimit: 0, timeout: nil)
    
    let userID: String
    let deviceID: String
    
    private let client: Client
    private let logger: (any ElementCallLoggingProtocol)?
    
    init?(client: Client, logger: (any ElementCallLoggingProtocol)? = nil) {
        guard let userID = try? client.userId(), let deviceID = try? client.deviceId() else {
            logger?.log(.error, "no user or device ID, cannot serve a call")
            return nil
        }
        self.client = client
        self.userID = userID
        self.deviceID = deviceID
        self.logger = logger
    }
    
    // MARK: - Sends
    
    func sendStickyEvent(roomID: String, eventType: String, contentJSON: String, duration: Duration) async throws(ElementCallMatrixBackendError) -> String {
        try await send("sendStickyEvent(\(eventType))") {
            try await room(roomID).sendStickyRaw(eventType: eventType,
                                                 content: contentJSON,
                                                 durationMs: UInt64(duration / .milliseconds(1)),
                                                 requestConfigOverride: Self.noRetry)
        }
    }
    
    /// The bindings have no delayed events (matrix-rust-sdk#6973), so this answers as a homeserver
    /// without MSC4140: the core joins without a dead man's switch, never asks again this session, and
    /// shortens the membership's lifetime instead.
    func sendDelayedStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String, delay: Duration) async throws(ElementCallMatrixBackendError) -> String {
        throw Self.delayedEventsNotSupported
    }
    
    func sendDelayedStickyEvent(roomID: String, eventType: String, contentJSON: String, stickyDuration: Duration, delay: Duration) async throws(ElementCallMatrixBackendError) -> String {
        throw Self.delayedEventsNotSupported
    }
    
    // Never called: no delayed event was ever scheduled.
    func restartDelayedEvent(roomID: String, delayID: String) async throws(ElementCallMatrixBackendError) {
        throw Self.delayedEventsNotSupported
    }
    
    func cancelDelayedEvent(roomID: String, delayID: String) async throws(ElementCallMatrixBackendError) {
        throw Self.delayedEventsNotSupported
    }
    
    func sendStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String) async throws(ElementCallMatrixBackendError) -> String {
        try await send("sendStateEvent(\(eventType))") {
            try await room(roomID).sendStateEventRaw(eventType: eventType, stateKey: stateKey, content: contentJSON, requestConfigOverride: Self.noRetry)
        }
    }
    
    func sendRoomEvent(roomID: String, eventType: String, contentJSON: String) async throws(ElementCallMatrixBackendError) -> String {
        try await send("sendRoomEvent(\(eventType))") {
            try await room(roomID).sendRaw(eventType: eventType, content: contentJSON, requestConfigOverride: Self.noRetry)
        }
    }
    
    func redactEvent(roomID: String, eventID: String, reason: String?) async throws(ElementCallMatrixBackendError) {
        try await send("redactEvent") {
            try await room(roomID).redact(eventId: eventID, reason: reason)
        }
    }
    
    /// Media keys never go out in the clear, and every undelivered recipient is reported: one reported
    /// as delivered is never re-sent to, so a failure reported as a success leaves a member keyless.
    func sendToDeviceMessage(eventType: String, contentJSON: String, to recipients: [ElementCallDevice]) async throws(ElementCallMatrixBackendError) -> [ElementCallDevice: String] {
        try await send("sendToDeviceMessage(\(eventType) to \(recipients.map { "\($0.userID)/\($0.deviceID)" }))") {
            let devices = Dictionary(grouping: recipients, by: \.userID).mapValues { $0.map(\.deviceID) }
            let failures = try await client.sendEncryptedToDeviceMessage(eventType: eventType, recipients: devices, content: contentJSON).failures
            if !failures.isEmpty {
                logger?.log(.warning, "to-device \(eventType) not delivered to \(failures)")
            }
            return SDKMappings.undelivered(recipients, failures: failures)
        }
    }
    
    // MARK: - Reads
    
    /// Each subject on its own listener, so one that fails ends only itself. The room handle is held
    /// by the listeners until the core cancels.
    func subscribeToRoom(roomID: String, subjects: ElementCallRoomSubjects, sink: ElementCallRoomSink) throws(ElementCallMatrixBackendError) -> ElementCallBackendSubscription {
        let room = try room(roomID)
        logger?.log(.info, "subscribing \(roomID) to state \(subjects.stateEventTypes), timeline \(subjects.timelineEventTypes)")
        
        var handles = [TaskHandle]()
        handles.append(room.subscribeToStickyEvents(listener: SDKStickyEventsListener(sink: sink)))
        // The SDK answers at once from the store, an empty set included, which is the first delivery
        // the core waits on. Only the state the sync asks for is stored, which is why the call keeps
        // to the room-state format: `m.rtc.slot` is not in sliding sync's `required_state`, so the
        // store reads every room as slotless.
        for eventType in subjects.stateEventTypes {
            handles.append(room.subscribeToStateEvents(eventType: stateEventTypeFromString(s: eventType),
                                                       listener: SDKStateEventsListener { events in
                                                           sink.deliverStateEvents(events.compactMap { SDKMappings.event($0, subscribedAs: eventType) }, ofType: eventType)
                                                       }))
        }
        for eventType in subjects.timelineEventTypes where eventType != Self.redactionEventType {
            handles.append(room.subscribeToMessageLikeEvents(eventType: messageLikeEventTypeFromString(s: eventType),
                                                             listener: SDKMessageLikeEventsListener { event in
                                                                 sink.deliverTimelineEvents([SDKMappings.event(event, subscribedAs: eventType)])
                                                             }))
        }
        handles.append(room.subscribeToMessageLikeEvents(eventType: messageLikeEventTypeFromString(s: Self.redactionEventType),
                                                         listener: SDKMessageLikeEventsListener { event in
                                                             if let redacted = SDKMappings.redactedEventID(fromContent: event.contentJson) {
                                                                 sink.deliverRedaction(ofEventID: redacted)
                                                             }
                                                         }))
        
        let roomInfo = SDKRoomInfoFeed(room: room, logger: logger)
        let tasks = [Task { await roomInfo.deliverEncryption(into: sink) },
                     Task { await roomInfo.deliverJoinedMembers(into: sink) }]
        
        let allHandles = handles + [roomInfo.handle]
        return ElementCallBackendSubscription {
            allHandles.forEach { $0.cancel() }
            tasks.forEach { $0.cancel() }
        }
    }
    
    func subscribeToDeviceMessages(eventTypes: [String], sink: ElementCallToDeviceSink) throws(ElementCallMatrixBackendError) -> ElementCallBackendSubscription {
        logger?.log(.info, "subscribing to to-device \(eventTypes)")
        let handle = client.subscribeToCustomToDeviceMessages(eventTypes: eventTypes, listener: SDKToDeviceListener { message in
            sink.deliver(SDKMappings.toDeviceMessage(message))
        })
        return ElementCallBackendSubscription { handle.cancel() }
    }
    
    /// The SDK's relations come back as typed content, with neither raw JSON nor encryption info, so
    /// a hand raised before we joined shows only once it changes. None rather than a failure, which
    /// is how the core asks a backend that cannot serve them to say so.
    func relations(roomID: String, eventID: String, relationshipType: String, eventType: String) async throws(ElementCallMatrixBackendError) -> [ElementCallMatrixEvent] {
        []
    }
    
    func openIDToken() async throws(ElementCallMatrixBackendError) -> ElementCallOpenIDToken {
        try await send("openIDToken") {
            let token = try await client.requestOpenidToken()
            return ElementCallOpenIDToken(accessToken: token.accessToken,
                                          tokenType: token.tokenType,
                                          matrixServerName: token.matrixServerName,
                                          expiresIn: .seconds(token.expiresInSeconds))
        }
    }
    
    /// The SDK falls back to the well-known when the homeserver lacks the MSC4143 endpoint; neither
    /// answering is none.
    func rtcTransportsJSON() async throws(ElementCallMatrixBackendError) -> String {
        try await send("rtcTransportsJSON") {
            try await SDKMappings.transportsJSON(client.discoverRtcTransports() ?? [])
        }
    }
    
    // MARK: - Private
    
    private static let delayedEventsNotSupported = ElementCallMatrixBackendError(errorCode: "M_UNRECOGNIZED",
                                                                                 reason: "Delayed events are not exposed by the SDK bindings")
    
    /// Taken per send rather than kept: a handle is cheap, and one held across calls outlives the
    /// room if we leave it.
    private func room(_ roomID: String) throws(ElementCallMatrixBackendError) -> Room {
        guard let room = try? client.getRoom(roomId: roomID) else {
            // Final, and no Matrix code says so: inventing one would be a lie about the homeserver.
            throw ElementCallMatrixBackendError(isPermanent: true, reason: "Not a joined room: \(roomID)")
        }
        return room
    }
    
    /// Logged on entry, and failing as the core reads failures: which refusals retire a feature for
    /// the session is the core's decision, made from the error code and status, never ours.
    private func send<T>(_ description: String, _ body: () async throws -> T) async throws(ElementCallMatrixBackendError) -> T {
        logger?.log(.info, "backend: \(description)")
        do {
            return try await body()
        } catch {
            logger?.log(.warning, "backend: \(description) failed: \(error)")
            throw SDKMappings.backendError(error)
        }
    }
}
