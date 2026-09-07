//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtcKit

extension NativeCallController {
    /// A controller with stubbed dependencies for previews and snapshot tests. Never joins.
    static func preview(connection: NativeCallConnection) -> NativeCallController {
        let controller = NativeCallController(rtcService: MatrixRtcService(transport: PreviewMatrixTransport()),
                                              clientProxy: ClientProxyMock(.init()),
                                              elementCallService: ElementCallServiceMock(.init()))
        controller.setPreviewState(callData: .init(roomID: "!room:example.org",
                                                   roomDisplayName: "Product | Lobby",
                                                   isDirect: false,
                                                   isAudioCall: false,
                                                   isStartingCall: true),
                                   connection: connection)
        return controller
    }
}

/// Answers every Matrix call with nothing; enough for a controller that never joins.
private final nonisolated class PreviewMatrixTransport: MatrixRtcMatrixTransport {
    let userID = "@alice:example.org"
    let deviceID = "PREVIEW"
    
    func sendStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String) async throws -> String {
        "$event"
    }
    
    func sendStickyEvent(roomID: String, eventType: String, contentJSON: String, durationMs: UInt64) async throws -> String {
        ""
    }
    
    func sendDelayedEvent(roomID: String, eventType: String, contentJSON: String, delayMs: UInt64) async throws -> String {
        "delay"
    }
    
    func sendDelayedStateEvent(roomID: String, eventType: String, stateKey: String, contentJSON: String, delayMs: UInt64) async throws -> String {
        "delay"
    }
    
    func updateDelayedEvent(roomID: String, delayID: String, action: MatrixRtcDelayedEventAction) async throws { }
    func sendToDeviceMessage(eventType: String, messages: [String: [String: String]]) async throws -> [String: [String]] {
        [:]
    }
    
    func sendRoomEvent(roomID: String, eventType: String, contentJSON: String) async throws -> String {
        "$event"
    }
    
    func redactEvent(roomID: String, eventID: String, reason: String?) async throws { }
    func requestOpenIDToken() async throws -> MatrixRtcOpenIDToken {
        .init(accessToken: "", tokenType: "Bearer", matrixServerName: "example.org", expiresIn: 3600)
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
