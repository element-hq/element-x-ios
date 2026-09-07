//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtc

/// The outbound bridge: the core decides *what* goes on the Matrix wire, this is *how*.
///
/// Every body is passed through verbatim (the core emits the unstable types itself) and every
/// failure is turned into a `CommandSenderError` — anything else crossing the FFI aborts the process.
/// Cancellation stays a cancellation: dressing it as a send failure would tell the core the command
/// was attempted when its session is simply gone.
final nonisolated class MatrixRtcCommandSender: CommandSenderCallback, Sendable {
    /// The released SDK's `sendStickyRaw` returns nothing, so a sticky send has no event ID to report.
    static let noEventID = ""
    
    private let transport: MatrixRtcMatrixTransport
    
    init(transport: MatrixRtcMatrixTransport) {
        self.transport = transport
    }
    
    func sendStickyEvent(roomId: String, eventType: String, contentJson: String, durationMs: UInt64) async throws -> String {
        // The lifetime is the core's to choose: it knows when it will next refresh the membership.
        try await command("sendStickyEvent(\(eventType), \(durationMs)ms)") {
            _ = try await transport.sendStickyEvent(roomID: roomId, eventType: eventType, contentJSON: contentJson, durationMs: durationMs)
            return Self.noEventID
        }
    }
    
    func sendStateEvent(roomId: String, eventType: String, stateKey: String, contentJson: String) async throws -> String {
        try await command("sendStateEvent(\(eventType))") {
            try await transport.sendStateEvent(roomID: roomId, eventType: eventType, stateKey: stateKey, contentJSON: contentJson)
        }
    }
    
    /// Failing the dead man's switch is not fatal: the core shortens the membership lifetime instead.
    /// What matters is the classification — `NotSupported` retires it for the session, `SendError` re-probes.
    func sendDelayedEvent(roomId: String, eventType: String, contentJson: String, delayMs: UInt64) async throws -> String {
        try await command("sendDelayedEvent(\(eventType))") {
            try await transport.sendDelayedEvent(roomID: roomId, eventType: eventType, contentJSON: contentJson, delayMs: delayMs)
        }
    }
    
    func sendDelayedStateEvent(roomId: String, eventType: String, stateKey: String, contentJson: String, delayMs: UInt64) async throws -> String {
        try await command("sendDelayedStateEvent(\(eventType))") {
            try await transport.sendDelayedStateEvent(roomID: roomId, eventType: eventType, stateKey: stateKey, contentJSON: contentJson, delayMs: delayMs)
        }
    }
    
    // Cancel and restart differ only by the action; swapping them retires the membership the switch
    // protects, dropping us out of a live call minutes later. Pinned by tests.
    func cancelDelayedEvent(roomId: String, delayId: String) async throws {
        try await command("cancelDelayedEvent") {
            try await transport.updateDelayedEvent(roomID: roomId, delayID: delayId, action: .cancel)
        }
    }
    
    func restartDelayedEvent(roomId: String, delayId: String) async throws {
        try await command("restartDelayedEvent") {
            try await transport.updateDelayedEvent(roomID: roomId, delayID: delayId, action: .restart)
        }
    }
    
    /// Media keys never go out in the clear, and every recipient gets a verdict: one reported as
    /// delivered is never re-sent to, so a failure reported as a success leaves a member keyless.
    func sendToDeviceMessage(recipients: [FfiToDeviceRecipient], messageType: String, contentJson: String) async throws -> [FfiToDeviceDelivery] {
        var messages = [String: [String: String]]()
        for recipient in recipients {
            messages[recipient.userId, default: [:]][recipient.deviceId] = contentJson
        }
        
        MatrixRtcLog.info("sendToDeviceMessage(\(messageType)) to \(recipients.map { "\($0.userId)/\($0.deviceId)" })")
        
        return try await command("sendToDeviceMessage(\(messageType))") {
            let failures = try await transport.sendToDeviceMessage(eventType: messageType, messages: messages)
            return recipients.map { recipient in
                let failed = failures[recipient.userId]?.contains(recipient.deviceId) ?? false
                return FfiToDeviceDelivery(userId: recipient.userId,
                                           deviceId: recipient.deviceId,
                                           error: failed ? "Not delivered by the homeserver" : nil)
            }
        }
    }
    
    func sendRoomEvent(roomId: String, eventType: String, contentJson: String) async throws -> String {
        try await command("sendRoomEvent(\(eventType))") {
            try await transport.sendRoomEvent(roomID: roomId, eventType: eventType, contentJSON: contentJson)
        }
    }
    
    func redactEvent(roomId: String, eventId: String, reason: String?) async throws {
        try await command("redactEvent") {
            try await transport.redactEvent(roomID: roomId, eventID: eventId, reason: reason)
        }
    }
    
    // MARK: - Private
    
    private func command<T>(_ description: String, _ body: () async throws -> T) async throws -> T {
        do {
            return try await body()
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as MatrixRtcTransportError {
            switch error {
            case .notSupported(let message):
                MatrixRtcLog.warning("\(description) refused by the homeserver: \(message)")
                throw CommandSenderError.NotSupported("\(description): \(message)")
            case .failed(let message):
                MatrixRtcLog.error("\(description) failed: \(message)")
                throw CommandSenderError.SendError("\(description): \(message)")
            }
        } catch {
            MatrixRtcLog.error("\(description) failed: \(error)")
            throw CommandSenderError.SendError("\(description): \(error)")
        }
    }
}
