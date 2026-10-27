//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import ElementCall
import Foundation
import MatrixRustSDK

/// What ``SdkMatrixBackend`` turns SDK values into, kept apart from the listeners so every mapping can
/// be tested without a client.
nonisolated enum SdkMappings {
    // MARK: Events
    
    /// Under the subscribed type rather than the event's own: the SDK hands it back as ruma's enum,
    /// whose custom variant has no readable string. Ruma treats `m.call.member` and
    /// `org.matrix.msc3401.call.member` as one type, which is harmless because the room-state dialect
    /// subscribes to one spelling only. Stripped state (an invited room) has no event ID or timestamp
    /// and is dropped. State is never encrypted.
    static func event(_ event: RoomStateEvent, subscribedAs eventType: String) -> FfiEventIn? {
        guard let eventID = event.eventId, let timestamp = event.timestamp else { return nil }
        return FfiEventIn(eventId: eventID,
                          sender: event.sender,
                          eventType: eventType,
                          stateKey: event.stateKey,
                          originServerTs: timestamp,
                          contentJson: event.contentJson,
                          encryption: encryption(nil))
    }
    
    /// As for state, under the subscribed type.
    static func event(_ event: RoomMessageLikeEvent, subscribedAs eventType: String) -> FfiEventIn {
        FfiEventIn(eventId: event.eventId,
                   sender: event.sender,
                   eventType: eventType,
                   stateKey: nil,
                   originServerTs: event.timestamp,
                   contentJson: event.contentJson,
                   encryption: encryption(event.encryptionInfo))
    }
    
    /// A sticky event carries the whole event as JSON, and its type on the wire, which for an unstable
    /// type may differ from the key's. Nil when it is malformed.
    static func event(_ event: StickyEvent) -> FfiEventIn? {
        guard let object = jsonObject(event.eventJson),
              let content = object["content"] as? [String: Any],
              let timestamp = (object["origin_server_ts"] as? NSNumber)?.uint64Value,
              let contentData = try? JSONSerialization.data(withJSONObject: content),
              let contentJSON = String(data: contentData, encoding: .utf8) else {
            return nil
        }
        return FfiEventIn(eventId: event.eventId,
                          sender: event.key.sender,
                          eventType: object["type"] as? String ?? event.key.eventType,
                          stateKey: nil,
                          originServerTs: timestamp,
                          contentJson: contentJSON,
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
    static func encryption(_ info: EventEncryptionInfo?) -> FfiEventEncryption {
        guard let info else {
            return FfiEventEncryption(encrypted: false, senderDeviceId: nil, senderConfirmed: nil)
        }
        let isRed = if case .red = info.shieldState {
            true
        } else {
            false
        }
        return FfiEventEncryption(encrypted: true, senderDeviceId: info.senderDeviceId, senderConfirmed: !isRed)
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
    static func toDeviceMessage(_ message: ToDeviceMessage) -> FfiToDeviceMessageIn {
        FfiToDeviceMessageIn(sender: message.encryptionInfo?.senderId ?? message.senderId,
                             eventType: message.eventType,
                             contentJson: message.content,
                             encryption: encryption(message.encryptionInfo))
    }
    
    /// One verdict per recipient, from the SDK's user ID → device IDs it could not serve: the core
    /// re-sends only to those.
    static func deliveries(to recipients: [FfiToDeviceRecipient], failures: [String: [String]]) -> [FfiToDeviceDelivery] {
        recipients.map { recipient in
            let failed = failures[recipient.userId]?.contains(recipient.deviceId) ?? false
            return FfiToDeviceDelivery(userId: recipient.userId,
                                       deviceId: recipient.deviceId,
                                       error: failed ? "The message could not be delivered to this device" : nil)
        }
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
    
    /// A failure as the core classifies it, which it does on the Matrix errcode. The bindings do not
    /// carry the HTTP status. The server's retry-after is passed on so the core waits that long
    /// rather than its own backoff step, though the SDK has usually spent it already, retrying a
    /// rate limit itself before the call returns.
    static func backendError(_ error: any Error) -> FfiBackendError {
        switch error {
        case let error as FfiBackendError:
            error
        case ClientError.MatrixApi(.limitExceeded(let retryAfterMs), let code, let message, _):
            .Failed(errcode: code, status: nil, retryAfterMs: retryAfterMs, permanent: false, reason: message)
        case ClientError.MatrixApi(_, let code, let message, _):
            .Failed(errcode: code, status: nil, retryAfterMs: nil, permanent: false, reason: message)
        default:
            .Failed(errcode: nil, status: nil, retryAfterMs: nil, permanent: false, reason: "\(error)")
        }
    }
    
    private static func jsonObject(_ json: String) -> [String: Any]? {
        guard let data = json.data(using: .utf8) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }
}

/// The live sticky events, by key, in the order they arrived.
nonisolated struct SdkStickyEventSet {
    private var keys = [StickyKey]()
    private var events = [StickyKey: FfiEventIn]()
    
    mutating func apply(_ update: StickyEventsUpdate) -> [FfiEventIn] {
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
        guard let ffiEvent = SdkMappings.event(event) else {
            remove(event.key)
            return
        }
        if events.updateValue(ffiEvent, forKey: event.key) == nil {
            keys.append(event.key)
        }
    }
    
    private mutating func remove(_ key: StickyKey) {
        if events.removeValue(forKey: key) != nil {
            keys.removeAll { $0 == key }
        }
    }
}
