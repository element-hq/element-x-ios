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

struct RTCTransportDiscoveryTests {
    @Test
    func parsesLiveKitAndUnsupportedTransports() throws {
        let body = Data("""
        {"rtc_transports": [{"type": "livekit", "livekit_service_url": "https://livekit.example.org"}, {"type": "sfu2"}]}
        """.utf8)
        
        let transports = RTCTransportDiscovery.parseTransports(body, key: RTCTransportDiscovery.transportsKey)
        
        #expect(try transports == [.liveKit(serviceURL: #require(URL(string: "https://livekit.example.org"))), .unsupported(type: "sfu2")])
    }
    
    @Test
    func fallsBackToWellKnownWhenTheEndpointFails() async throws {
        let discovery = RTCTransportDiscovery(homeserverURL: "https://matrix.example.org/", serverName: "example.org") { url in
            if url == "https://matrix.example.org/_matrix/client/unstable/org.matrix.msc4143/rtc/transports" {
                throw MatrixRtcTransportError.failed("404")
            }
            #expect(url == "https://example.org/.well-known/matrix/client")
            return Data("""
            {"m.rtc_foci": [{"type": "livekit", "livekit_service_url": "https://focus.example.org"}]}
            """.utf8)
        }
        
        let transports = await discovery.discover()
        
        #expect(try transports == [.liveKit(serviceURL: #require(URL(string: "https://focus.example.org")))])
    }
    
    @Test
    func unparseableBodyYieldsNothing() {
        #expect(RTCTransportDiscovery.parseTransports(Data("nope".utf8), key: RTCTransportDiscovery.transportsKey).isEmpty)
    }
}
