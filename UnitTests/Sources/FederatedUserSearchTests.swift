//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

final class FederatedUserSearchTests: XCTestCase {
    // MARK: - Bare handle detection

    func testBareHandleAcceptsPlainUsername() {
        XCTAssertEqual(FederatedUserSearch.bareHandle(from: "ana-souza"), "ana-souza")
    }

    func testBareHandleStripsSigilAndLowercases() {
        XCTAssertEqual(FederatedUserSearch.bareHandle(from: "@Ana-Souza"), "ana-souza")
    }

    func testBareHandleTrimsWhitespace() {
        XCTAssertEqual(FederatedUserSearch.bareHandle(from: "  ana.souza_2\n"), "ana.souza_2")
    }

    func testBareHandleAcceptsFullLocalpartCharset() {
        XCTAssertEqual(FederatedUserSearch.bareHandle(from: "a-b.c_d=e/f0"), "a-b.c_d=e/f0")
    }

    func testBareHandleRejectsShortQueries() {
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "ab"))
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "@ab"))
        XCTAssertNil(FederatedUserSearch.bareHandle(from: ""))
    }

    func testBareHandleRejectsFullAddresses() {
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "@ana-souza:gua.example"))
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "ana-souza:gua.example"))
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "@ana-souza:"))
    }

    func testBareHandleRejectsInvalidCharacters() {
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "ana souza"))
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "ana!"))
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "an@a"))
        XCTAssertNil(FederatedUserSearch.bareHandle(from: "año-souza"))
    }

    // MARK: - Roster parsing

    func testRosterDecodingIgnoresUnknownFieldsAndKeepsPolicy() throws {
        let roster = try JSONDecoder().decode(FederationRoster.self, from: Data(rosterJSON.utf8))

        XCTAssertEqual(roster.entries.count, 3)

        let first = roster.entries[0].homeserver
        XCTAssertEqual(first.serverName, "br.gua.example")
        XCTAssertNil(first.searchVisibility)
        XCTAssertNil(first.searchGroups)
        XCTAssertTrue(roster.entries[0].isActive)

        let second = roster.entries[1].homeserver
        XCTAssertEqual(second.serverName, "edu.gua.example")
        XCTAssertEqual(second.searchVisibility, "GROUP")
        XCTAssertEqual(second.searchGroups, ["edu"])

        XCTAssertFalse(roster.entries[2].isActive)
    }

    // MARK: - Search visibility

    func testAbsentVisibilityIsGlobal() {
        XCTAssertEqual(RosterSearchVisibility(rawValue: nil), .global)
    }

    func testKnownVisibilityValues() {
        XCTAssertEqual(RosterSearchVisibility(rawValue: "global"), .global)
        XCTAssertEqual(RosterSearchVisibility(rawValue: "group"), .group)
        XCTAssertEqual(RosterSearchVisibility(rawValue: "server"), .server)
    }

    func testVisibilityMatchingIsCaseInsensitive() {
        // The resolver serializes the policy uppercase, like the entry status.
        XCTAssertEqual(RosterSearchVisibility(rawValue: "GLOBAL"), .global)
        XCTAssertEqual(RosterSearchVisibility(rawValue: "GROUP"), .group)
        XCTAssertEqual(RosterSearchVisibility(rawValue: "SERVER"), .server)
    }

    func testUnrecognizedVisibilityIsPreserved() {
        XCTAssertEqual(RosterSearchVisibility(rawValue: "invite"), .unrecognized("invite"))
    }

    // MARK: - Candidate construction

    func testCandidatesSkipOwnServerAndFollowRosterOrder() {
        let roster = makeRoster([
            .init(serverName: "br.gua.example", searchVisibility: nil, searchGroups: nil),
            .init(serverName: "ca.gua.example", searchVisibility: "global", searchGroups: nil)
        ])

        let candidates = FederatedUserSearch.candidates(forHandle: "ana-souza", roster: roster, ownServerName: "br.gua.example")

        XCTAssertEqual(candidates, ["@ana-souza:ca.gua.example"])
    }

    func testCandidatesSkipInactiveEntries() {
        let roster = FederationRoster(entries: [
            .init(homeserver: .init(serverName: "ca.gua.example", searchVisibility: nil, searchGroups: nil), status: "ACTIVE"),
            .init(homeserver: .init(serverName: "old.gua.example", searchVisibility: nil, searchGroups: nil), status: "RETIRED"),
            .init(homeserver: .init(serverName: "new.gua.example", searchVisibility: nil, searchGroups: nil), status: "PENDING")
        ])

        let candidates = FederatedUserSearch.candidates(forHandle: "ana-souza", roster: roster, ownServerName: "br.gua.example")

        XCTAssertEqual(candidates, ["@ana-souza:ca.gua.example"])
    }

    func testCandidatesSkipServerVisibility() {
        let roster = makeRoster([
            .init(serverName: "ca.gua.example", searchVisibility: "GLOBAL", searchGroups: []),
            .init(serverName: "private.gua.example", searchVisibility: "SERVER", searchGroups: nil)
        ])

        let candidates = FederatedUserSearch.candidates(forHandle: "ana-souza", roster: roster, ownServerName: "br.gua.example")

        XCTAssertEqual(candidates, ["@ana-souza:ca.gua.example"])
    }

    func testCandidatesSkipUnrecognizedVisibility() {
        let roster = makeRoster([
            .init(serverName: "beta.gua.example", searchVisibility: "invite", searchGroups: nil)
        ])

        let candidates = FederatedUserSearch.candidates(forHandle: "ana-souza", roster: roster, ownServerName: "br.gua.example")

        XCTAssertEqual(candidates, [])
    }

    func testGroupVisibilityRequiresASharedGroup() {
        let roster = makeRoster([
            .init(serverName: "br.gua.example", searchVisibility: nil, searchGroups: ["edu", "partners"]),
            .init(serverName: "edu.gua.example", searchVisibility: "group", searchGroups: ["edu"]),
            .init(serverName: "gov.gua.example", searchVisibility: "group", searchGroups: ["gov"]),
            .init(serverName: "closed.gua.example", searchVisibility: "group", searchGroups: nil)
        ])

        let candidates = FederatedUserSearch.candidates(forHandle: "ana-souza", roster: roster, ownServerName: "br.gua.example")

        XCTAssertEqual(candidates, ["@ana-souza:edu.gua.example"])
    }

    func testGroupVisibilityExcludesSearcherWithoutGroups() {
        let roster = makeRoster([
            .init(serverName: "br.gua.example", searchVisibility: nil, searchGroups: nil),
            .init(serverName: "edu.gua.example", searchVisibility: "group", searchGroups: ["edu"])
        ])

        let candidates = FederatedUserSearch.candidates(forHandle: "ana-souza", roster: roster, ownServerName: "br.gua.example")

        XCTAssertEqual(candidates, [])
    }

    func testGroupVisibilityExcludesSearcherAbsentFromRoster() {
        let roster = makeRoster([
            .init(serverName: "ca.gua.example", searchVisibility: nil, searchGroups: nil),
            .init(serverName: "edu.gua.example", searchVisibility: "group", searchGroups: ["edu"])
        ])

        let candidates = FederatedUserSearch.candidates(forHandle: "ana-souza", roster: roster, ownServerName: "nowhere.example")

        XCTAssertEqual(candidates, ["@ana-souza:ca.gua.example"])
    }

    // MARK: - Roster cache

    func testRosterIsCachedWithinTimeToLive() async {
        let fetcher = RosterFetcherStub(results: [.success(rosterA), .success(rosterB)])
        let cache = FederationRosterCache(fetcher: fetcher, timeToLive: 300)

        let first = await cache.currentRoster()
        let second = await cache.currentRoster()

        XCTAssertEqual(first, rosterA)
        XCTAssertEqual(second, rosterA)
        let fetchCount = await fetcher.fetchCount
        XCTAssertEqual(fetchCount, 1)
    }

    func testRosterRefreshesAfterExpiry() async {
        let fetcher = RosterFetcherStub(results: [.success(rosterA), .success(rosterB)])
        let cache = FederationRosterCache(fetcher: fetcher, timeToLive: 0)

        let first = await cache.currentRoster()
        let second = await cache.currentRoster()

        XCTAssertEqual(first, rosterA)
        XCTAssertEqual(second, rosterB)
        let fetchCount = await fetcher.fetchCount
        XCTAssertEqual(fetchCount, 2)
    }

    func testStaleRosterIsServedWhenRefreshFails() async {
        let fetcher = RosterFetcherStub(results: [.success(rosterA), .failure(.malformedResponse)])
        let cache = FederationRosterCache(fetcher: fetcher, timeToLive: 0)

        let first = await cache.currentRoster()
        let second = await cache.currentRoster()

        XCTAssertEqual(first, rosterA)
        XCTAssertEqual(second, rosterA)
    }

    func testMissingFetcherReturnsNoRoster() async {
        let cache = FederationRosterCache(fetcher: nil, timeToLive: 300)

        let roster = await cache.currentRoster()

        XCTAssertNil(roster)
    }

    // MARK: - Private

    private func makeRoster(_ servers: [FederationRosterServer]) -> FederationRoster {
        FederationRoster(entries: servers.map { FederationRosterEntry(homeserver: $0, status: "ACTIVE") })
    }

    private var rosterA: FederationRoster {
        makeRoster([.init(serverName: "a.gua.example", searchVisibility: nil, searchGroups: nil)])
    }

    private var rosterB: FederationRoster {
        makeRoster([.init(serverName: "b.gua.example", searchVisibility: nil, searchGroups: nil)])
    }

    /// A realistic resolver payload: the client only decodes what it needs and ignores the rest.
    private let rosterJSON = """
    {
      "version": 12,
      "generatedAt": "2025-08-14T12:00:00Z",
      "entries": [
        {
          "homeserver": {
            "id": "hs-br",
            "serverName": "br.gua.example",
            "baseUrl": "https://matrix.br.gua.example",
            "masIssuer": "https://auth.br.gua.example",
            "region": "br",
            "weight": 100,
            "acceptsNew": true,
            "signingKey": "ed25519:aaaa"
          },
          "status": "ACTIVE"
        },
        {
          "homeserver": {
            "id": "hs-edu",
            "serverName": "edu.gua.example",
            "baseUrl": "https://matrix.edu.gua.example",
            "masIssuer": "https://auth.edu.gua.example",
            "region": "ca",
            "weight": 10,
            "acceptsNew": false,
            "signingKey": "ed25519:bbbb",
            "searchVisibility": "GROUP",
            "searchGroups": ["edu"]
          },
          "status": "ACTIVE"
        },
        {
          "homeserver": {
            "id": "hs-old",
            "serverName": "old.gua.example",
            "baseUrl": "https://matrix.old.gua.example",
            "signingKey": "ed25519:cccc",
            "searchVisibility": "GLOBAL"
          },
          "status": "RETIRED"
        }
      ]
    }
    """
}

private actor RosterFetcherStub: FederationRosterFetching {
    private var results: [Result<FederationRoster, ResolverError>]
    private(set) var fetchCount = 0

    init(results: [Result<FederationRoster, ResolverError>]) {
        self.results = results
    }

    func fetchRoster() async throws -> FederationRoster {
        fetchCount += 1
        guard !results.isEmpty else { throw ResolverError.malformedResponse }
        return try results.removeFirst().get()
    }
}
