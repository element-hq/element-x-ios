//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtcKit
import MatrixRustSDK

// Temporary: part of the widget-driver stopgap that stands in for SDK bindings the released
// package lacks (delayed events, a room-state feed, to-device messaging). Retired once the bindings
// expose them.

/// The two ends of the widget driver's message pipe, as a protocol so the bridge can be tested
/// without the SDK.
nonisolated protocol WidgetDriverChannel: Sendable {
    /// The next message for the widget; nil once the driver has stopped.
    func recv() async -> String?
    /// False once the driver has stopped.
    func send(msg: String) async -> Bool
}

extension WidgetDriverHandle: WidgetDriverChannel { }

/// The capabilities the bridge grants itself: only what the RTC core needs. Not Element Call's set,
/// which also reads `m.room.member` and would push the whole member list through the pipe.
///
/// The machine stores whatever `acquireCapabilities` returns, so the strings answered to the
/// `capabilities` request and the value returned here describe the same set.
final nonisolated class WidgetCapabilityGrant: WidgetCapabilitiesProvider, Sendable {
    static let stateEventTypes = [MatrixRtcEventTypes.legacyStateMember]
    static let toDeviceEventTypes = [MatrixRtcEventTypes.encryptionKey, MatrixRtcEventTypes.legacyEncryptionKey]
    static let roomEventTypes = ["org.matrix.msc4075.call.notify",
                                 "org.matrix.msc4310.rtc.notification",
                                 "m.rtc.notification",
                                 "io.element.call.reaction",
                                 "m.reaction"]
    
    /// MSC2762 / MSC3819 / MSC4157 capability strings for the same set.
    static let capabilityStrings: [String] =
        stateEventTypes.flatMap { ["org.matrix.msc2762.receive.state_event:\($0)", "org.matrix.msc2762.send.state_event:\($0)"] }
            + toDeviceEventTypes.flatMap { ["org.matrix.msc3819.receive.to_device:\($0)", "org.matrix.msc3819.send.to_device:\($0)"] }
            + roomEventTypes.map { "org.matrix.msc2762.send.event:\($0)" }
            + ["org.matrix.msc4157.send.delayed_event", "org.matrix.msc4157.update_delayed_event"]
    
    /// Called by the SDK on a blocking thread, once, during negotiation.
    func acquireCapabilities(capabilities: WidgetCapabilities) -> WidgetCapabilities {
        let stateFilters = Self.stateEventTypes.map { WidgetEventFilter.stateWithType(eventType: $0) }
        let toDeviceFilters = Self.toDeviceEventTypes.map { WidgetEventFilter.toDevice(eventType: $0) }
        return WidgetCapabilities(read: stateFilters + toDeviceFilters,
                                  send: stateFilters + toDeviceFilters + Self.roomEventTypes.map { .messageLikeWithType(eventType: $0) },
                                  requiresClient: false,
                                  updateDelayedEvent: true,
                                  sendDelayedEvent: true,
                                  downloadFiles: false,
                                  rtcTransports: false)
    }
}
