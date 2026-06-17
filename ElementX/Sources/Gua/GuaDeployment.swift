//
// Copyright 2025 Gua
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Foundation

/// The Gua backend deployment a build talks to. Bundles the environment-specific service endpoints
/// (resolver + identity-service) so the rest of the app never hardcodes a host.
///
/// The active deployment is chosen at **build time**, so the same source ships to every environment:
/// - **Release** archives use `.production`.
/// - **Debug** builds (and any build that defines the `GUA_DEVELOPMENT` compilation condition — e.g. a
///   dev TestFlight scheme) use `.development`.
///
/// Production endpoints are the project's own `gua.global` domain and are safe to commit. **Development**
/// endpoints are read from the injected `Secrets` (the Pkl secrets pipeline), so the non-public dev host
/// is supplied per-machine / per-CI and never committed to this (public) repo.
enum GuaDeployment {
    case development
    case production

    static var current: GuaDeployment {
        #if GUA_DEVELOPMENT
        return .development
        #elseif DEBUG
        return .development
        #else
        return .production
        #endif
    }

    /// Federation resolver base URL. Gua phone auth requires this to route users to the correct
    /// homeserver/MAS.
    var resolverBaseURL: URL? {
        switch self {
        case .production:
            return URL(string: "https://resolver.gua.global")
        case .development:
            return Self.url(from: Secrets.resolverBaseURL)
        }
    }

    /// identity-service base URL (phone/OTP IdP), or `nil` when unconfigured.
    var identityServiceBaseURL: URL? {
        switch self {
        case .production:
            return URL(string: "https://identity.gua.global")
        case .development:
            return Self.url(from: Secrets.identityServiceBaseURL)
        }
    }

    private static func url(from raw: String?) -> URL? {
        guard let raw, !raw.isEmpty else { return nil }
        return URL(string: raw)
    }
}
