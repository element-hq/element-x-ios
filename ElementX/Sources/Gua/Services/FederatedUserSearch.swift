//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// How a federation homeserver lets its users be found by bare-handle search from other servers.
/// Absent means `global` — the default for roster entries that predate the policy. Values this
/// client doesn't recognize are treated as **not** discoverable, so a stricter policy introduced
/// server-side is never widened by an older client.
enum RosterSearchVisibility: Equatable {
    /// Discoverable from every federation server.
    case global
    /// Discoverable only from servers sharing at least one search group.
    case group
    /// Discoverable only from the user's own server, i.e. never via federated search.
    case server
    case unrecognized(String)

    init(rawValue: String?) {
        // The resolver serializes the policy like the entry status, i.e. uppercase (`GLOBAL`);
        // match case-insensitively so either casing works.
        switch rawValue?.lowercased() {
        case nil, "global": self = .global
        case "group": self = .group
        case "server": self = .server
        case let .some(other): self = .unrecognized(other)
        }
    }
}

/// Pure logic for Gua's federated bare-username search: when someone types a handle with no
/// homeserver (`ana-souza`), the client fans out an exact-match lookup to the other federation
/// servers from the resolver roster, honouring each server's discoverability policy.
enum FederatedUserSearch {
    /// Normalizes a search query into a bare handle, or `nil` when the query isn't one.
    /// A bare handle is an optional leading `@` followed by at least 3 localpart characters —
    /// and crucially no `:`, otherwise the user is already typing a full address.
    static func bareHandle(from query: String) -> String? {
        var handle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !handle.contains(":") else { return nil }
        if handle.hasPrefix("@") {
            handle = String(handle.dropFirst())
        }
        guard handle.range(of: "^[a-z0-9._=/-]{3,}$", options: .regularExpression) != nil else { return nil }
        return handle
    }

    /// The full user IDs to look up for a bare handle: one per ACTIVE roster server that allows
    /// discovery from the searcher's own homeserver, in roster order. The searcher's own server
    /// is skipped — local search already covers it.
    static func candidates(forHandle handle: String, roster: FederationRoster, ownServerName: String) -> [String] {
        let ownGroups = Set(roster.entries.first { $0.homeserver.serverName == ownServerName }?.homeserver.searchGroups ?? [])

        return roster.entries
            .filter { entry in
                guard entry.isActive, entry.homeserver.serverName != ownServerName else { return false }
                switch RosterSearchVisibility(rawValue: entry.homeserver.searchVisibility) {
                case .global:
                    return true
                case .group:
                    return !ownGroups.isDisjoint(with: entry.homeserver.searchGroups ?? [])
                case .server, .unrecognized:
                    return false
                }
            }
            .map { "@\(handle):\($0.homeserver.serverName)" }
    }
}

// MARK: - Roster cache

/// Provides the current federation roster to user search, or `nil` when it isn't available.
/// Unavailability is not an error: federated search silently degrades to local-only.
protocol FederationRosterProviding: Sendable {
    func currentRoster() async -> FederationRoster?
}

/// In-memory roster cache so a burst of searches doesn't hammer the resolver: the roster only
/// changes when servers join or leave the federation, so a short TTL is plenty. Keeps serving
/// the last good roster when a refresh fails.
actor FederationRosterCache: FederationRosterProviding {
    static let shared = FederationRosterCache()

    private let fetcher: FederationRosterFetching?
    private let timeToLive: TimeInterval
    private var cached: (roster: FederationRoster, fetchedAt: Date)?

    /// - Parameters:
    ///   - fetcher: Where the roster comes from; `nil` (an unconfigured resolver) disables federated search.
    ///   - timeToLive: How long a fetched roster stays fresh.
    init(fetcher: FederationRosterFetching? = ResolverClient(), timeToLive: TimeInterval = 5 * 60) {
        self.fetcher = fetcher
        self.timeToLive = timeToLive
    }

    func currentRoster() async -> FederationRoster? {
        if let cached, Date().timeIntervalSince(cached.fetchedAt) < timeToLive {
            return cached.roster
        }
        guard let fetcher else {
            return nil
        }
        guard let roster = try? await fetcher.fetchRoster() else {
            // A transient resolver error shouldn't kill federated search: serve the stale roster if there is one.
            return cached?.roster
        }
        cached = (roster, Date())
        return roster
    }
}
