//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtcKit

/// Finds out which RTC transports the homeserver offers.
///
/// Two sources, in order: the MSC4143 discovery endpoint (still unstable-only in ruma), then the
/// deprecated `rtc_foci` list in the well-known for servers that answer 404 — matrix.org is one.
/// The Rust SDK does exactly this in `Client::discover_rtc_transports`, with caching, but only
/// exposes a boolean over the FFI; replace this with a call through once the list is exposed.
nonisolated struct RTCTransportDiscovery {
    static let transportsPath = "/_matrix/client/unstable/org.matrix.msc4143/rtc/transports"
    static let wellKnownPath = "/.well-known/matrix/client"
    static let transportsKey = "rtc_transports"
    static let rtcFociKey = "org.matrix.msc4143.rtc_foci"
    static let rtcFociKeyAlias = "m.rtc_foci"
    
    let homeserverURL: String
    let serverName: String?
    /// An authenticated GET; the SDK's `getUrl`.
    let fetch: (String) async throws -> Data
    
    func discover() async -> [MatrixRtcTransport] {
        if let transports = await fromEndpoint() {
            return transports
        }
        return await fromWellKnown()
    }
    
    /// - Returns: nil when the endpoint is unavailable, in which case fall back.
    private func fromEndpoint() async -> [MatrixRtcTransport]? {
        let url = homeserverURL.trimmingCharacters(in: CharacterSet(charactersIn: "/")) + Self.transportsPath
        do {
            let body = try await fetch(url)
            let transports = Self.parseTransports(body, key: Self.transportsKey)
            MXLog.info("MatrixRTC: discovery endpoint advertises \(transports)")
            return transports
        } catch {
            MXLog.info("MatrixRTC: discovery endpoint unavailable (\(error)), falling back to well-known")
            return nil
        }
    }
    
    private func fromWellKnown() async -> [MatrixRtcTransport] {
        guard let serverName else {
            MXLog.warning("MatrixRTC: no server name for the well-known lookup")
            return []
        }
        // Well-known is served from the server name, usually not the homeserver URL.
        let url = "https://\(serverName)\(Self.wellKnownPath)"
        do {
            let body = try await fetch(url)
            var transports = Self.parseTransports(body, key: Self.rtcFociKey)
            if transports.isEmpty {
                transports = Self.parseTransports(body, key: Self.rtcFociKeyAlias)
            }
            MXLog.info("MatrixRTC: well-known advertises \(transports)")
            return transports
        } catch {
            MXLog.warning("MatrixRTC: cannot read well-known from \(url): \(error)")
            return []
        }
    }
    
    static func parseTransports(_ body: Data, key: String) -> [MatrixRtcTransport] {
        guard let root = try? JSONSerialization.jsonObject(with: body) as? [String: Any],
              let transports = root[key] as? [[String: Any]] else {
            return []
        }
        return transports.compactMap { transport in
            guard let type = transport["type"] as? String else { return nil }
            if type == "livekit" {
                guard let urlString = transport["livekit_service_url"] as? String, let url = URL(string: urlString) else { return nil }
                return .liveKit(serviceURL: url)
            }
            return .unsupported(type: type)
        }
    }
}
