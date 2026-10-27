//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
import Foundation
import MatrixRustSDK

/// The RTC core's `MatrixBackend` over a Rust SDK `Client`, for a host that has an SDK client to hand
/// to `ElementCallController`. The reference a host copies, so the package carries no SDK dependency and
/// never holds back a host's SDK bump. The example itself has no client and runs on fakes, so this is
/// compiled and its mappings are unit-tested, but it is never run here.
///
/// One per Matrix session, alive between calls. The core calls it from its own threads, and the SDK
/// calls the listeners below from its own; the core's sinks only post to a channel, so events are
/// delivered straight from the SDK's callbacks, with nothing buffered in between.
///
/// Every type in these files is marked `nonisolated` although this target does not need it: a host
/// whose default isolation is the main actor, as Element X's is, must be able to copy them unchanged.
final nonisolated class SdkMatrixBackend: MatrixBackend {
    static let redactionEventType = "m.room.redaction"
    /// The core retries a failed send itself, within its own budget, so the SDK must not retry underneath it.
    static let noRetry = RequestConfigOverride(retryLimit: 0, timeout: nil)
    
    private let client: Client
    private let userID: String
    private let deviceID: String
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
    
    func ownUserId() -> String {
        userID
    }
    
    func ownDeviceId() -> String {
        deviceID
    }
    
    // MARK: - Sends
    
    func sendStickyEvent(roomId: String, eventType: String, contentJson: String, durationMs: UInt64) async throws -> String {
        try await send("sendStickyEvent(\(eventType))") {
            try await room(roomId).sendStickyRaw(eventType: eventType, content: contentJson, durationMs: durationMs, requestConfigOverride: Self.noRetry)
        }
    }
    
    /// The bindings have no delayed events (matrix-rust-sdk#6973), so this answers as a homeserver
    /// without MSC4140: the core joins without a dead man's switch, never asks again this session, and
    /// shortens the membership's lifetime instead.
    func sendDelayedStateEvent(roomId: String, eventType: String, stateKey: String, contentJson: String, delayMs: UInt64) async throws -> String {
        throw Self.delayedEventsNotSupported
    }
    
    func sendDelayedStickyEvent(roomId: String, eventType: String, contentJson: String, stickyDurationMs: UInt64, delayMs: UInt64) async throws -> String {
        throw Self.delayedEventsNotSupported
    }
    
    // Never called: no delayed event was ever scheduled.
    func restartDelayedEvent(roomId: String, delayId: String) async throws {
        throw Self.delayedEventsNotSupported
    }
    
    func cancelDelayedEvent(roomId: String, delayId: String) async throws {
        throw Self.delayedEventsNotSupported
    }
    
    func sendStateEvent(roomId: String, eventType: String, stateKey: String, contentJson: String) async throws -> String {
        try await send("sendStateEvent(\(eventType))") {
            try await room(roomId).sendStateEventRaw(eventType: eventType, stateKey: stateKey, content: contentJson, requestConfigOverride: Self.noRetry)
        }
    }
    
    func sendRoomEvent(roomId: String, eventType: String, contentJson: String) async throws -> String {
        try await send("sendRoomEvent(\(eventType))") {
            try await room(roomId).sendRaw(eventType: eventType, content: contentJson, requestConfigOverride: Self.noRetry)
        }
    }
    
    func redactEvent(roomId: String, eventId: String, reason: String?) async throws {
        try await send("redactEvent") {
            try await room(roomId).redact(eventId: eventId, reason: reason)
        }
    }
    
    /// Media keys never go out in the clear, and every recipient gets a verdict: one reported as
    /// delivered is never re-sent to, so a failure reported as a success leaves a member keyless.
    func sendToDeviceMessage(recipients: [FfiToDeviceRecipient], messageType: String, contentJson: String) async throws -> [FfiToDeviceDelivery] {
        try await send("sendToDeviceMessage(\(messageType) to \(recipients.map { "\($0.userId)/\($0.deviceId)" }))") {
            let devices = Dictionary(grouping: recipients, by: \.userId).mapValues { $0.map(\.deviceId) }
            let failures = try await client.sendEncryptedToDeviceMessage(eventType: messageType, recipients: devices, content: contentJson).failures
            if !failures.isEmpty {
                logger?.log(.warning, "to-device \(messageType) not delivered to \(failures)")
            }
            return SdkMappings.deliveries(to: recipients, failures: failures)
        }
    }
    
    // MARK: - Reads
    
    /// Each subject on its own listener, so one that fails ends only itself. The room handle is held
    /// by the listeners until the core cancels.
    func subscribeRoom(roomId: String, subjects: FfiRoomSubjects, sink: RoomSink) throws -> BackendSubscription {
        let room = try room(roomId)
        logger?.log(.info, "subscribing \(roomId) to state \(subjects.stateEventTypes), timeline \(subjects.timelineEventTypes)")
        
        var handles = [TaskHandle]()
        handles.append(room.subscribeToStickyEvents(listener: SdkStickyEventsListener(sink: sink)))
        // The SDK answers at once from the store, an empty set included, which is the first delivery
        // the core waits on. Only the state the sync asks for is stored, which is why the call keeps
        // to the room-state format: `m.rtc.slot` is not in sliding sync's `required_state`, so the
        // store reads every room as slotless.
        for eventType in subjects.stateEventTypes {
            handles.append(room.subscribeToStateEvents(eventType: stateEventTypeFromString(s: eventType),
                                                       listener: SdkStateEventsListener { events in
                                                           sink.onStateEvents(eventType: eventType, events: events.compactMap { SdkMappings.event($0, subscribedAs: eventType) })
                                                       }))
        }
        for eventType in subjects.timelineEventTypes where eventType != Self.redactionEventType {
            handles.append(room.subscribeToMessageLikeEvents(eventType: messageLikeEventTypeFromString(s: eventType),
                                                             listener: SdkMessageLikeEventsListener { event in
                                                                 sink.onTimelineEvents(events: [SdkMappings.event(event, subscribedAs: eventType)])
                                                             }))
        }
        handles.append(room.subscribeToMessageLikeEvents(eventType: messageLikeEventTypeFromString(s: Self.redactionEventType),
                                                         listener: SdkMessageLikeEventsListener { event in
                                                             if let redacted = SdkMappings.redactedEventID(fromContent: event.contentJson) {
                                                                 sink.onRedaction(eventId: redacted)
                                                             }
                                                         }))
        
        let roomInfo = SdkRoomInfoFeed(room: room, logger: logger)
        let tasks = [Task { await roomInfo.deliverEncryption(into: sink) },
                     Task { await roomInfo.deliverJoinedMembers(into: sink) }]
        
        return SdkSubscription(handles: handles + [roomInfo.handle], tasks: tasks)
    }
    
    func subscribeToDevice(eventTypes: [String], sink: ToDeviceSink) throws -> BackendSubscription {
        logger?.log(.info, "subscribing to to-device \(eventTypes)")
        let handle = client.subscribeToCustomToDeviceMessages(eventTypes: eventTypes, listener: SdkToDeviceListener { message in
            sink.onToDeviceMessage(message: SdkMappings.toDeviceMessage(message))
        })
        return SdkSubscription(handles: [handle], tasks: [])
    }
    
    /// The SDK's relations come back as typed content, with neither raw JSON nor encryption info, so
    /// a hand raised before we joined shows only once it changes. None rather than a failure, which
    /// is how the core asks a backend that cannot serve them to say so.
    func relations(roomId: String, eventId: String, relType: String, eventType: String) async throws -> [FfiEventIn] {
        []
    }
    
    func openidToken() async throws -> FfiOpenIdToken {
        try await send("openidToken") {
            let token = try await client.requestOpenidToken()
            return FfiOpenIdToken(accessToken: token.accessToken,
                                  tokenType: token.tokenType,
                                  matrixServerName: token.matrixServerName,
                                  expiresInSecs: token.expiresInSeconds)
        }
    }
    
    /// The SDK falls back to the well-known when the homeserver lacks the MSC4143 endpoint; neither
    /// answering is none.
    func rtcTransports() async throws -> String {
        try await send("rtcTransports") {
            try await SdkMappings.transportsJSON(client.discoverRtcTransports() ?? [])
        }
    }
    
    // MARK: - Private
    
    private static let delayedEventsNotSupported = FfiBackendError.Failed(errcode: "M_UNRECOGNIZED",
                                                                          status: nil,
                                                                          retryAfterMs: nil,
                                                                          permanent: false,
                                                                          reason: "Delayed events are not exposed by the SDK bindings")
    
    /// Taken per send rather than kept: a handle is cheap, and one held across calls outlives the
    /// room if we leave it.
    private func room(_ roomID: String) throws(FfiBackendError) -> Room {
        guard let room = try? client.getRoom(roomId: roomID) else {
            // Final, and no Matrix code says so: inventing one would be a lie about the homeserver.
            throw FfiBackendError.Failed(errcode: nil, status: nil, retryAfterMs: nil, permanent: true, reason: "Not a joined room: \(roomID)")
        }
        return room
    }
    
    /// Logged on entry, and failing as the core reads failures: which refusals retire a feature for
    /// the session is the core's decision, made from the `errcode` and status, never ours.
    private func send<T>(_ description: String, _ body: () async throws -> T) async throws(FfiBackendError) -> T {
        logger?.log(.info, "backend: \(description)")
        do {
            return try await body()
        } catch {
            logger?.log(.warning, "backend: \(description) failed: \(error)")
            throw SdkMappings.backendError(error)
        }
    }
}

/// Cancels every listener and task of one subscription. Idempotent, as the core requires.
private final nonisolated class SdkSubscription: BackendSubscription {
    private let handles: [TaskHandle]
    private let tasks: [Task<Void, Never>]
    
    init(handles: [TaskHandle], tasks: [Task<Void, Never>]) {
        self.handles = handles
        self.tasks = tasks
    }
    
    func cancel() {
        handles.forEach { $0.cancel() }
        tasks.forEach { $0.cancel() }
    }
}
