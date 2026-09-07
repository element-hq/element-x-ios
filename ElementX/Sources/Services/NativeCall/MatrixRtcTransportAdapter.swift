//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRtcKit
import MatrixRustSDK

/// The Matrix side of the RTC core, over the app's SDK proxies. The only place where the RTC
/// framework meets `MatrixRustSDK` types (through the proxies' Swift wrappers).
///
/// What the released bindings do not expose yet (delayed events, the room-state feed, to-device
/// messaging, room event IDs) goes through a per-room `MatrixRtcRoomBridgeProtocol`, opened in
/// `willJoinRoom` and closed in `didLeaveRoom`.
///
/// Main-actor bound like the proxies it wraps; the core awaits every send, and the feeds hop onto
/// the main actor inside their streams.
@MainActor
final class MatrixRtcTransportAdapter: MatrixRtcMatrixTransport {
    nonisolated let userID: String
    nonisolated let deviceID: String
    
    private let clientProxy: ClientProxyProtocol
    private var bridges = [String: any MatrixRtcRoomBridgeProtocol]()
    private var toDeviceForwarders = [String: Task<Void, Never>]()
    /// The core subscribes once per session; bridges come and go with calls.
    private nonisolated let toDeviceRelay = ToDeviceRelay()
    
    init?(clientProxy: ClientProxyProtocol) {
        guard let deviceID = clientProxy.deviceID else { return nil }
        self.clientProxy = clientProxy
        userID = clientProxy.userID
        self.deviceID = deviceID
    }
    
    // MARK: - Lifecycle
    
    nonisolated func willJoinRoom(roomID: String) async throws {
        try await onMain { adapter in
            guard adapter.bridges[roomID] == nil else { return }
            guard let bridge = try await adapter.room(roomID).matrixRtcRoomBridge() else {
                throw MatrixRtcTransportError.failed("Cannot open a Matrix bridge for \(roomID)")
            }
            if case .failure(let error) = await bridge.start() {
                throw error.transportError
            }
            adapter.bridges[roomID] = bridge
            adapter.toDeviceForwarders[roomID] = Task { [toDeviceRelay = adapter.toDeviceRelay] in
                for await message in bridge.toDeviceMessages() {
                    toDeviceRelay.publish(message)
                }
            }
        }
    }
    
    nonisolated func didLeaveRoom(roomID: String) async {
        let bridge = await Task { @MainActor in
            toDeviceForwarders.removeValue(forKey: roomID)?.cancel()
            return bridges.removeValue(forKey: roomID)
        }.value
        await bridge?.stop()
    }
    
    // MARK: - Sends
    
    // Every witness is nonisolated (async protocol requirements run on the caller), so each hops
    // onto the main actor where the proxies live.
    
    nonisolated func sendStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String) async throws -> String {
        try await onMain { try await $0.room(roomID).sendStateEventRaw(eventType: eventType, stateKey: stateKey, contentJSON: contentJSON).mapTransportError() }
    }
    
    /// Sticky events (MSC4354) need bindings the released SDK lacks; only the state-event compat
    /// mode is joined for now, which never sends one.
    nonisolated func sendStickyEvent(roomID: String, eventType: String, contentJSON: String, durationMs: UInt64) async throws -> String {
        throw MatrixRtcTransportError.notSupported("Sticky events are not available with the released SDK")
    }
    
    nonisolated func sendDelayedEvent(roomID: String, eventType: String, contentJSON: String, delayMs: UInt64) async throws -> String {
        try await bridge(roomID).sendDelayedEvent(eventType: eventType, stateKey: nil, contentJSON: contentJSON, delayMs: delayMs).mapTransportError()
    }
    
    nonisolated func sendDelayedStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String, delayMs: UInt64) async throws -> String {
        try await bridge(roomID).sendDelayedEvent(eventType: eventType, stateKey: stateKey, contentJSON: contentJSON, delayMs: delayMs).mapTransportError()
    }
    
    nonisolated func updateDelayedEvent(roomID: String, delayID: String, action: MatrixRtcDelayedEventAction) async throws {
        try await bridge(roomID).updateDelayedEvent(delayID: delayID, action: action).mapTransportError()
    }
    
    /// The core does not say which room the keys are for, and neither does the bridge need to: it
    /// encrypts whenever its room is encrypted. Only one call runs at a time.
    nonisolated func sendToDeviceMessage(eventType: String, messages: [String: [String: String]]) async throws -> [String: [String]] {
        let bridge = try await onMain { adapter -> any MatrixRtcRoomBridgeProtocol in
            if adapter.bridges.count > 1 {
                MXLog.warning("MatrixRTC: \(adapter.bridges.count) live bridges, sending to-device through the first")
            }
            guard let bridge = adapter.bridges.values.first else {
                throw MatrixRtcTransportError.failed("No live call to send to-device messages through")
            }
            return bridge
        }
        return try await bridge.sendToDeviceMessage(eventType: eventType, messages: messages).mapTransportError()
    }
    
    /// Through the bridge when the room has one, which reports the event ID; the SDK's own `sendRaw`
    /// returns nothing, so the fallback answers an empty string.
    nonisolated func sendRoomEvent(roomID: String, eventType: String, contentJSON: String) async throws -> String {
        if let bridge = await liveBridge(roomID) {
            return try await bridge.sendRoomEvent(eventType: eventType, contentJSON: contentJSON).mapTransportError()
        }
        try await onMain { try await $0.room(roomID).sendRaw(eventType: eventType, contentJSON: contentJSON).mapTransportError() }
        return ""
    }
    
    nonisolated func redactEvent(roomID: String, eventID: String, reason: String?) async throws {
        try await onMain { try await $0.room(roomID).redact(eventID: eventID, reason: reason).mapTransportError() }
    }
    
    nonisolated func requestOpenIDToken() async throws -> MatrixRtcOpenIDToken {
        let token = try await onMain { try await $0.clientProxy.requestOpenIDToken().mapTransportError() }
        return MatrixRtcOpenIDToken(accessToken: token.accessToken,
                                    tokenType: token.tokenType,
                                    matrixServerName: token.matrixServerName,
                                    expiresIn: token.expiresIn)
    }
    
    // MARK: - Feeds
    
    nonisolated func toDeviceMessages(eventTypes: [String]) -> AsyncStream<MatrixRtcToDeviceMessage> {
        toDeviceRelay.subscribe(eventTypes: eventTypes)
    }
    
    nonisolated func roomStateEvents(roomID: String, eventType: String) -> AsyncStream<[MatrixRtcRoomStateEvent]> {
        AsyncStream { continuation in
            let task = Task {
                guard let bridge = await liveBridge(roomID) else {
                    MXLog.error("MatrixRTC: no bridge for \(roomID), the state feed stays empty")
                    continuation.finish()
                    return
                }
                for await events in bridge.stateEvents(eventType: eventType) {
                    continuation.yield(events)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    
    nonisolated func joinedMemberIDs(roomID: String) -> AsyncStream<[String]> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                guard let room = try? await self.room(roomID) else {
                    continuation.finish()
                    return
                }
                // The publisher stays empty until an explicit update; without it nobody would ever be fed.
                await room.updateMembers()
                for await members in room.membersPublisher.values {
                    let joined = members.filter { $0.membership == .join }.map(\.userID)
                    if !joined.isEmpty {
                        continuation.yield(joined)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
    
    nonisolated func isRoomEncrypted(roomID: String) async -> Bool {
        await Task { @MainActor in
            guard let room = try? await self.room(roomID) else { return false }
            return room.infoPublisher.value.isEncrypted
        }.value
    }
    
    // MARK: - Private
    
    private nonisolated func onMain<T: Sendable>(_ body: @escaping @MainActor (MatrixRtcTransportAdapter) async throws -> T) async throws -> T {
        try await Task { @MainActor in try await body(self) }.value
    }
    
    private nonisolated func liveBridge(_ roomID: String) async -> (any MatrixRtcRoomBridgeProtocol)? {
        await Task { @MainActor in bridges[roomID] }.value
    }
    
    private nonisolated func bridge(_ roomID: String) async throws -> any MatrixRtcRoomBridgeProtocol {
        guard let bridge = await liveBridge(roomID) else {
            throw MatrixRtcTransportError.failed("No live bridge for \(roomID)")
        }
        return bridge
    }
    
    private func room(_ roomID: String) async throws -> JoinedRoomProxyProtocol {
        guard case .joined(let room) = await clientProxy.roomForIdentifier(roomID) else {
            throw MatrixRtcTransportError.failed("Not joined to \(roomID)")
        }
        return room
    }
}

// MARK: - Error mapping

nonisolated extension MatrixRtcRoomBridgeError {
    /// A permanent refusal retires the feature for the session; anything else is retried. 404
    /// `M_UNRECOGNIZED` means the homeserver doesn't implement the endpoint; matrix.org answers 403
    /// "Sending delayed events has been disallowed", which the message alone separates from a
    /// genuine power-level rejection that would clear the moment our power level changed.
    var transportError: MatrixRtcTransportError {
        switch self {
        case .matrixAPI(let errcode, _, let message):
            if errcode == "M_UNRECOGNIZED" {
                return .notSupported(message)
            }
            if errcode == "M_FORBIDDEN", message.localizedCaseInsensitiveContains("delayed event") {
                return .notSupported(message)
            }
            return .failed(message)
        case .notRunning, .timedOut, .invalidResponse:
            return .failed("\(self)")
        }
    }
}

private nonisolated extension Result where Failure == MatrixRtcRoomBridgeError {
    func mapTransportError() throws -> Success {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error.transportError
        }
    }
}

private nonisolated extension Result where Failure == RoomProxyError {
    func mapTransportError() throws -> Success {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error.transportError
        }
    }
}

private nonisolated extension Result where Failure == ClientProxyError {
    func mapTransportError() throws -> Success {
        switch self {
        case .success(let value): return value
        case .failure(let error): throw error.transportError
        }
    }
}

private nonisolated extension RoomProxyError {
    var transportError: MatrixRtcTransportError {
        if case .sdkError(let error) = self {
            return error.transportError
        }
        return .failed("\(self)")
    }
}

private nonisolated extension ClientProxyError {
    var transportError: MatrixRtcTransportError {
        if case .sdkError(let error) = self {
            return error.transportError
        }
        return .failed("\(self)")
    }
}

private nonisolated extension Error {
    /// Same classification as `MatrixRtcRoomBridgeError.transportError`, for the proxy paths.
    var transportError: MatrixRtcTransportError {
        if let clientError = self as? ClientError, case .MatrixApi(let kind, _, let message, _) = clientError {
            switch kind {
            case .unrecognized:
                return .notSupported(message)
            case .forbidden where message.localizedCaseInsensitiveContains("delayed event"):
                return .notSupported(message)
            default:
                break
            }
        }
        return .failed("\(self)")
    }
}
