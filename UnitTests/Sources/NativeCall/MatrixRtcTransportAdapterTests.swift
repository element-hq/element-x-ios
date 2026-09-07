//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRtcKit
import Testing

/// The parts of the transport adapter that survive the widget-driver stopgap: how bridge failures are
/// classified for the core, and the session-long to-device relay.
@Suite(.timeLimit(.minutes(1)))
struct MatrixRtcTransportAdapterTests {
    @Test
    func permanentRefusalsRetireTheFeature() {
        #expect(MatrixRtcRoomBridgeError.matrixAPI(errcode: "M_UNRECOGNIZED", httpStatus: 404, message: "Unrecognized request").transportError
            == .notSupported("Unrecognized request"))
        #expect(MatrixRtcRoomBridgeError.matrixAPI(errcode: "M_FORBIDDEN", httpStatus: 403, message: "Sending delayed events has been disallowed").transportError
            == .notSupported("Sending delayed events has been disallowed"))
    }
    
    @Test
    func everythingElseIsRetried() {
        #expect(MatrixRtcRoomBridgeError.matrixAPI(errcode: "M_FORBIDDEN", httpStatus: 403, message: "You don't have permission").transportError
            == .failed("You don't have permission"))
        #expect(MatrixRtcRoomBridgeError.matrixAPI(errcode: "M_LIMIT_EXCEEDED", httpStatus: 429, message: "Too many requests").transportError
            == .failed("Too many requests"))
        #expect(MatrixRtcRoomBridgeError.timedOut.transportError == .failed("timedOut"))
        #expect(MatrixRtcRoomBridgeError.notRunning.transportError == .failed("notRunning"))
    }
    
    @Test
    func relayFansInByEventTypeUntilUnsubscribed() async throws {
        let relay = ToDeviceRelay()
        var keys = relay.subscribe(eventTypes: ["io.element.call.encryption_keys"]).makeAsyncIterator()
        var both = relay.subscribe(eventTypes: ["io.element.call.encryption_keys", "org.matrix.msc4143.rtc.encryption_key"]).makeAsyncIterator()
        
        relay.publish(message(type: "org.matrix.msc4143.rtc.encryption_key", sender: "@a:example.org"))
        relay.publish(message(type: "io.element.call.encryption_keys", sender: "@b:example.org"))
        
        #expect(try #require(await keys.next()).attestedSenderID == "@b:example.org")
        #expect(try #require(await both.next()).attestedSenderID == "@a:example.org")
        #expect(try #require(await both.next()).attestedSenderID == "@b:example.org")
        
        relay.publish(message(type: "m.other", sender: "@c:example.org"))
        relay.publish(message(type: "io.element.call.encryption_keys", sender: "@d:example.org"))
        #expect(try #require(await keys.next()).attestedSenderID == "@d:example.org")
    }
    
    private func message(type: String, sender: String) -> MatrixRtcToDeviceMessage {
        MatrixRtcToDeviceMessage(eventType: type, attestedSenderID: sender, senderDeviceID: "DEV", isSenderCrossSigned: true, wasEncrypted: true, contentJSON: "{}")
    }
}
