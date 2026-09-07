//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRtc
@testable import MatrixRtcKit
import Testing

/// Pins the outbound bridge: each callback maps to exactly one transport call, cancel and restart
/// are never swapped, failures are classified, and every to-device recipient gets a verdict.
struct MatrixRtcCommandSenderTests {
    @Test
    func cancelAndRestartAreNotSwapped() async throws {
        let transport = RecordingTransport()
        let sender = MatrixRtcCommandSender(transport: transport)
        
        try await sender.cancelDelayedEvent(roomId: "!r", delayId: "d1")
        try await sender.restartDelayedEvent(roomId: "!r", delayId: "d2")
        
        #expect(transport.delayedUpdates == ["d1:cancel", "d2:restart"])
    }
    
    @Test
    func stickyEventPassesContentAndDurationThroughVerbatim() async throws {
        let transport = RecordingTransport()
        let sender = MatrixRtcCommandSender(transport: transport)
        
        let eventID = try await sender.sendStickyEvent(roomId: "!r", eventType: "org.matrix.msc4143.rtc.member", contentJson: "{\"a\":1}", durationMs: 7_200_000)
        
        #expect(eventID == MatrixRtcCommandSender.noEventID)
        #expect(transport.stickyEvents == ["org.matrix.msc4143.rtc.member|{\"a\":1}|7200000"])
    }
    
    @Test
    func permanentRefusalIsNotSupported() async {
        let transport = RecordingTransport()
        transport.delayedEventError = .notSupported("M_UNRECOGNIZED")
        let sender = MatrixRtcCommandSender(transport: transport)
        
        await #expect(throws: CommandSenderError.NotSupported("sendDelayedEvent(m.rtc.member): M_UNRECOGNIZED")) {
            _ = try await sender.sendDelayedEvent(roomId: "!r", eventType: "m.rtc.member", contentJson: "{}", delayMs: 20000)
        }
    }
    
    @Test
    func transientFailureIsSendError() async {
        let transport = RecordingTransport()
        transport.delayedEventError = .failed("timeout")
        let sender = MatrixRtcCommandSender(transport: transport)
        
        await #expect(throws: CommandSenderError.SendError("sendDelayedEvent(m.rtc.member): timeout")) {
            _ = try await sender.sendDelayedEvent(roomId: "!r", eventType: "m.rtc.member", contentJson: "{}", delayMs: 20000)
        }
    }
    
    @Test
    func toDeviceReportsOneVerdictPerRecipient() async throws {
        let transport = RecordingTransport()
        transport.toDeviceFailures = ["@bob:example.org": ["DEV2"]]
        let sender = MatrixRtcCommandSender(transport: transport)
        
        let deliveries = try await sender.sendToDeviceMessage(recipients: [.init(userId: "@bob:example.org", deviceId: "DEV1"),
                                                                           .init(userId: "@bob:example.org", deviceId: "DEV2"),
                                                                           .init(userId: "@carol:example.org", deviceId: "DEV3")],
                                                              messageType: "org.matrix.msc4143.rtc.encryption_key",
                                                              contentJson: "{}")
        
        #expect(deliveries.map(\.deviceId) == ["DEV1", "DEV2", "DEV3"])
        #expect(deliveries.map { $0.error == nil } == [true, false, true])
        #expect(transport.toDeviceMessages == ["@bob:example.org": ["DEV1": "{}", "DEV2": "{}"], "@carol:example.org": ["DEV3": "{}"]])
    }
}

/// Records every send; failures are configurable per kind.
private final nonisolated class RecordingTransport: MatrixRtcMatrixTransport, @unchecked Sendable {
    let userID = "@alice:example.org"
    let deviceID = "ALICE"
    
    var stickyEvents = [String]()
    var delayedUpdates = [String]()
    var toDeviceMessages = [String: [String: String]]()
    var toDeviceFailures = [String: [String]]()
    var delayedEventError: MatrixRtcTransportError?
    
    func sendStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String) async throws -> String {
        "$state"
    }
    
    func sendStickyEvent(roomID: String, eventType: String, contentJSON: String, durationMs: UInt64) async throws -> String {
        stickyEvents.append("\(eventType)|\(contentJSON)|\(durationMs)")
        return ""
    }
    
    func sendDelayedEvent(roomID: String, eventType: String, contentJSON: String, delayMs: UInt64) async throws -> String {
        if let delayedEventError {
            throw delayedEventError
        }
        return "delay"
    }
    
    func sendDelayedStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String, delayMs: UInt64) async throws -> String {
        if let delayedEventError {
            throw delayedEventError
        }
        return "delay"
    }
    
    func updateDelayedEvent(roomID: String, delayID: String, action: MatrixRtcDelayedEventAction) async throws {
        delayedUpdates.append("\(delayID):\(action)")
    }
    
    func sendToDeviceMessage(eventType: String, messages: [String: [String: String]]) async throws -> [String: [String]] {
        toDeviceMessages = messages
        return toDeviceFailures
    }
    
    func sendRoomEvent(roomID: String, eventType: String, contentJSON: String) async throws -> String {
        ""
    }
    
    func redactEvent(roomID: String, eventID: String, reason: String?) async throws { }
    func requestOpenIDToken() async throws -> MatrixRtcOpenIDToken {
        .init(accessToken: "t", tokenType: "Bearer", matrixServerName: "example.org", expiresIn: 60)
    }
    
    func toDeviceMessages(eventTypes: [String]) -> AsyncStream<MatrixRtcToDeviceMessage> {
        AsyncStream { $0.finish() }
    }
    
    func roomStateEvents(roomID: String, eventType: String) -> AsyncStream<[MatrixRtcRoomStateEvent]> {
        AsyncStream { $0.finish() }
    }
    
    func joinedMemberIDs(roomID: String) -> AsyncStream<[String]> {
        AsyncStream { $0.finish() }
    }
    
    func isRoomEncrypted(roomID: String) async -> Bool {
        true
    }
}
