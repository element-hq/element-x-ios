//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Foundation

/// A homeserver as advertised by the Gua resolver: where a phone's account lives (login) or should be
/// created (register). The homeserver is identified by its Matrix `serverName`; the client configures OIDC
/// against that and discovers the base URL + MAS issuer via well-known, exactly as it would for any
/// account provider.
struct ResolvedHomeserver: Equatable, Sendable {
    let serverName: String
    let baseURL: String
    let masIssuer: String?
    let region: String?
}

/// Outcome of resolving a phone number against the Gua resolver.
struct HomeserverResolution: Equatable, Sendable {
    /// `true` when an account already exists for this phone (→ login); `false` when it does not (→ register).
    let exists: Bool
    /// The homeserver to authenticate against (login) or create the account on (register).
    let homeserver: ResolvedHomeserver
}

enum ResolverError: Error, LocalizedError {
    case notConfigured
    case invalidURL
    case malformedResponse
    case server(status: Int)
    case transport(Error)
    case decoding(Error)

    var errorDescription: String? {
        switch self {
        case .notConfigured: "The routing service is not configured."
        case .invalidURL: "The routing service URL is invalid."
        case .malformedResponse: "The routing service returned an unexpected response."
        case let .server(status): "Routing service error (\(status))."
        case let .transport(error): error.localizedDescription
        case let .decoding(error): "Could not parse the routing service response: \(error.localizedDescription)"
        }
    }
}

protocol ResolverClientProtocol: Sendable {
    /// Resolve a verified phone number to the homeserver it belongs to (or should be created on).
    func resolve(phoneNumber: String) async throws -> HomeserverResolution
}

/// Talks to the Gua resolver (`POST /resolve`) — the federation front door that maps a phone number to a
/// homeserver, so the client never hardcodes one. See `gua-resolver`.
final class ResolverClient: ResolverClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.session = session
    }

    /// Convenience initializer using the active `GuaDeployment`'s resolver URL. Returns `nil` when the
    /// resolver is not configured.
    convenience init?() {
        guard let url = GuaDeployment.current.resolverBaseURL else { return nil }
        self.init(baseURL: url)
    }

    func resolve(phoneNumber: String) async throws -> HomeserverResolution {
        struct RequestBody: Encodable { let phone: String }
        struct HomeserverRef: Decodable {
            let serverName: String
            let baseUrl: String
            let masIssuer: String?
            let region: String?
        }
        struct Response: Decodable {
            let exists: Bool
            let homeserver: HomeserverRef?
            let registerAt: HomeserverRef?
        }

        guard let url = URL(string: "/resolve", relativeTo: baseURL) else { throw ResolverError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        do {
            request.httpBody = try encoder.encode(RequestBody(phone: phoneNumber))
        } catch {
            throw ResolverError.decoding(error)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw ResolverError.transport(error)
        }
        guard let httpResponse = response as? HTTPURLResponse else { throw ResolverError.malformedResponse }
        guard httpResponse.statusCode == 200 else { throw ResolverError.server(status: httpResponse.statusCode) }

        let parsed: Response
        do {
            parsed = try decoder.decode(Response.self, from: data)
        } catch {
            throw ResolverError.decoding(error)
        }

        guard let ref = parsed.exists ? parsed.homeserver : parsed.registerAt else {
            throw ResolverError.malformedResponse
        }
        return HomeserverResolution(exists: parsed.exists,
                                    homeserver: ResolvedHomeserver(serverName: ref.serverName,
                                                                   baseURL: ref.baseUrl,
                                                                   masIssuer: ref.masIssuer,
                                                                   region: ref.region))
    }
}
