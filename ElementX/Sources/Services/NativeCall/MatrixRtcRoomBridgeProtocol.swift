//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtcKit

nonisolated enum MatrixRtcRoomBridgeError: Error, Sendable, Equatable {
    /// The bridge is not (or no longer) running for the room.
    case notRunning
    case timedOut
    /// The bridge answered, but not with what the operation needs.
    case invalidResponse(String)
    /// The homeserver refused the request; `errcode` when the bridge could tell.
    case matrixAPI(errcode: String?, httpStatus: Int?, message: String)
}

/// Exactly the Matrix operations the released SDK bindings do not expose yet for a room: delayed
/// events, room event IDs, the room-state feed and to-device messaging. `MatrixRtcTransportAdapter`
/// routes those through whatever implements this; everything else goes straight to the SDK proxies.
///
/// Today's implementation is `WidgetMatrixBridge`, driving the SDK widget driver in-process because
/// the released bindings lack delayed events, a room-state feed and to-device messaging. Once they
/// gain those entry points, an SDK-backed implementation replaces it and the adapter does not change.
nonisolated protocol MatrixRtcRoomBridgeProtocol: AnyObject, Sendable {
    var roomID: String { get }
    
    /// Returns once the bridge can serve requests.
    func start() async -> Result<Void, MatrixRtcRoomBridgeError>
    func stop() async
    
    /// - Returns: the MSC4140 delay ID.
    func sendDelayedEvent(eventType: String, stateKey: String?, contentJSON: String, delayMs: UInt64) async -> Result<String, MatrixRtcRoomBridgeError>
    func updateDelayedEvent(delayID: String, action: MatrixRtcDelayedEventAction) async -> Result<Void, MatrixRtcRoomBridgeError>
    /// - Returns: the event ID.
    func sendRoomEvent(eventType: String, contentJSON: String) async -> Result<String, MatrixRtcRoomBridgeError>
    /// `messages` is user ID → device ID → content JSON.
    /// - Returns: the recipients that were **not** served, user ID → device IDs.
    func sendToDeviceMessage(eventType: String, messages: [String: [String: String]]) async -> Result<[String: [String]], MatrixRtcRoomBridgeError>
    
    /// The full current list of state events of that type, immediately when there are any, and on every change.
    func stateEvents(eventType: String) -> AsyncStream<[MatrixRtcRoomStateEvent]>
    /// Every to-device message the bridge is allowed to receive, for as long as it runs.
    func toDeviceMessages() -> AsyncStream<MatrixRtcToDeviceMessage>
}
