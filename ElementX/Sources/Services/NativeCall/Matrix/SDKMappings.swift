//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
import Foundation
import MatrixRustSDK

/// What ``SDKMatrixBackend`` turns SDK values into, kept apart from the listeners so every mapping can
/// be tested without a client.
nonisolated enum SDKMappings {
    // MARK: Events
    
    /// Under the subscribed type rather than the event's own: the SDK hands it back as ruma's enum,
    /// whose custom variant has no readable string. Ruma treats `m.call.member` and
    /// `org.matrix.msc3401.call.member` as one type, which is harmless because the room-state dialect
    /// subscribes to one spelling only. Stripped state (an invited room) has no event ID or timestamp
    /// and is dropped. State is never encrypted.
    static func event(_ event: RoomStateEvent, subscribedAs eventType: String) -> ElementCallMatrixEvent? {
        guard let eventID = event.eventId, let timestamp = event.timestamp else { return nil }
        return ElementCallMatrixEvent(eventID: eventID,
                                      sender: event.sender,
                                      eventType: eventType,
                                      stateKey: event.stateKey,
                                      originServerTimestamp: date(milliseconds: timestamp),
                                      contentJSON: event.contentJson,
                                      encryption: encryption(nil))
    }
    
    /// As for state, under the subscribed type.
    static func event(_ event: RoomMessageLikeEvent, subscribedAs eventType: String) -> ElementCallMatrixEvent {
        ElementCallMatrixEvent(eventID: event.eventId,
                               sender: event.sender,
                               eventType: eventType,
                               originServerTimestamp: date(milliseconds: event.timestamp),
                               contentJSON: event.contentJson,
                               encryption: encryption(event.encryptionInfo))
    }
    
    /// A sticky event carries the whole event as JSON, and its type on the wire, which for an unstable
    /// type may differ from the key's. Nil when it is malformed.
    static func event(_ event: StickyEvent) -> ElementCallMatrixEvent? {
        guard let object = jsonObject(event.eventJson),
              let content = object["content"] as? [String: Any],
              let timestamp = (object["origin_server_ts"] as? NSNumber)?.uint64Value,
              let contentData = try? JSONSerialization.data(withJSONObject: content),
              let contentJSON = String(data: contentData, encoding: .utf8) else {
            return nil
        }
        return ElementCallMatrixEvent(eventID: event.eventId,
                                      sender: event.key.sender,
                                      eventType: object["type"] as? String ?? event.key.eventType,
                                      originServerTimestamp: date(milliseconds: timestamp),
                                      contentJSON: contentJSON,
                                      encryption: encryption(event.encryptionInfo))
    }
    
    /// Room version 11 moved `redacts` into the content, and the SDK hands over the content only, so a
    /// redaction in an older room is missed.
    static func redactedEventID(fromContent contentJSON: String) -> String? {
        jsonObject(contentJSON)?["redacts"] as? String
    }
    
    // MARK: Encryption and trust
    
    /// How the SDK says an event arrived; no encryption info is cleartext.
    ///
    /// Whether to vouch for the sender is the client's threat model, and the SDK has already applied
    /// it: an event or to-device message whose sender fails the client's
    /// `DecryptionSettings.senderDeviceTrustRequirement` is never delivered. Of what remains, the
    /// sender is confirmed unless its shield is red.
    static func encryption(_ info: EventEncryptionInfo?) -> ElementCallEventEncryption {
        guard let info else { return .cleartext }
        let isRed = if case .red = info.shieldState {
            true
        } else {
            false
        }
        return .encrypted(senderDeviceID: info.senderDeviceId, isSenderConfirmed: !isRed)
    }
    
    /// Nil while the client does not know, never a guess.
    static func isEncrypted(_ state: EncryptionState) -> Bool? {
        switch state {
        case .encrypted: true
        case .notEncrypted: false
        case .unknown: nil
        }
    }
    
    // MARK: Members
    
    /// Whether a freshly read, sorted membership is worth delivering. Compared whole, never by count.
    /// An empty list is never delivered: we are in the room, so it is the store not having loaded the
    /// members yet, and the core would ignore a set without us.
    static func shouldDeliver(_ members: [String], lastDelivered: [String]?) -> Bool {
        !members.isEmpty && members != lastDelivered
    }
    
    // MARK: To-device
    
    /// The claimed sender is unauthenticated; an encrypted message's attested one is what counts.
    static func toDeviceMessage(_ message: ToDeviceMessage) -> ElementCallToDeviceMessage {
        ElementCallToDeviceMessage(sender: message.encryptionInfo?.senderId ?? message.senderId,
                                   eventType: message.eventType,
                                   contentJSON: message.content,
                                   encryption: encryption(message.encryptionInfo))
    }
    
    /// The recipients the SDK could not serve, from its user ID → device IDs: the core re-sends only to
    /// those.
    static func undelivered(_ recipients: [ElementCallDevice], failures: [String: [String]]) -> [ElementCallDevice: String] {
        let failed = recipients.filter { failures[$0.userID]?.contains($0.deviceID) ?? false }
        return Dictionary(failed.map { ($0, "The message could not be delivered to this device") }) { first, _ in first }
    }
    
    // MARK: Transports and failures
    
    /// The MSC4143 `rtc_transports` array the core parses, rebuilt from the SDK's typed transports.
    static func transportsJSON(_ transports: [RtcTransport]) -> String {
        let objects: [[String: Any]] = transports.map { transport in
            switch transport {
            case .liveKit(let serviceURL):
                return ["type": "livekit", "livekit_service_url": serviceURL]
            case .custom(let type, let data):
                var fields = jsonObject(data) ?? [:]
                fields["type"] = type
                return fields
            }
        }
        guard let data = try? JSONSerialization.data(withJSONObject: objects, options: .sortedKeys) else { return "[]" }
        return String(data: data, encoding: .utf8) ?? "[]"
    }
    
    /// A failure as the core classifies it, which it does on the Matrix error code. The bindings do not
    /// carry the HTTP status. The server's retry-after is passed on so the core waits that long
    /// rather than its own backoff step, though the SDK has usually spent it already, retrying a
    /// rate limit itself before the call returns.
    static func backendError(_ error: any Error) -> ElementCallMatrixBackendError {
        switch error {
        case let error as ElementCallMatrixBackendError:
            error
        case ClientError.MatrixApi(.limitExceeded(let retryAfter), let code, let message, _):
            ElementCallMatrixBackendError(errorCode: code, retryAfter: retryAfter.map { .milliseconds($0) }, reason: message)
        case ClientError.MatrixApi(_, let code, let message, _):
            ElementCallMatrixBackendError(errorCode: code, reason: message)
        default:
            ElementCallMatrixBackendError(reason: "\(error)")
        }
    }
    
    private static func date(milliseconds: UInt64) -> Date {
        Date(timeIntervalSince1970: Double(milliseconds) / 1000)
    }
    
    private static func jsonObject(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

/// The live sticky events, by key, in the order they arrived.
nonisolated struct SDKStickyEventSet {
    private var keys = [StickyKey]()
    private var events = [StickyKey: ElementCallMatrixEvent]()
    
    mutating func apply(_ update: StickyEventsUpdate) -> [ElementCallMatrixEvent] {
        switch update {
        case .reset(let live):
            keys.removeAll()
            events.removeAll()
            live.forEach { put($0) }
        case .changes(let added, let updated, let removed):
            added.forEach { put($0) }
            updated.forEach { put($0) }
            removed.forEach { remove($0.key) }
        }
        return keys.compactMap { events[$0] }
    }
    
    /// A malformed event takes its key's place away rather than leaving the one it replaced live.
    private mutating func put(_ event: StickyEvent) {
        guard let mappedEvent = SDKMappings.event(event) else {
            remove(event.key)
            return
        }
        if events.updateValue(mappedEvent, forKey: event.key) == nil {
            keys.append(event.key)
        }
    }
    
    private mutating func remove(_ key: StickyKey) {
        if events.removeValue(forKey: key) != nil {
            keys.removeAll { $0 == key }
        }
    }
}
