//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class UserDiscoveryServiceTest: XCTestCase {
    var service: UserDiscoveryService!
    var clientProxy: ClientProxyMock!
    
    override func setUpWithError() throws {
        clientProxy = .init(.init(userID: "@foo:matrix.org"))
        service = UserDiscoveryService(clientProxy: clientProxy, federationRosterProvider: nil)
    }
    
    func testQueryShowingResults() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [UserProfileProxy.mockAlice], limited: true))
        
        let results = await (try? search(query: "AAA").get()) ?? []
        assertSearchResults(results, toBe: 1)
    }
    
    func testOwnerIsFiltered() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [UserProfileProxy(userID: "@foo:matrix.org")], limited: true))
        
        let results = await (try? search(query: "AAA").get()) ?? []
        assertSearchResults(results, toBe: 0)
    }
    
    func testGetProfileIsNotCalled() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: searchResults, limited: true))
        clientProxy.profileForReturnValue = .success(.init(userID: "@alice:matrix.org"))
        
        let results = await (try? search(query: "AAA").get()) ?? []
        assertSearchResults(results, toBe: 3)
        XCTAssertFalse(clientProxy.profileForCalled)
    }

    func testGetProfileIsNotCalledForAccountOwnerID() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: searchResults, limited: true))
        clientProxy.profileForReturnValue = .success(.init(userID: "@alice:matrix.org"))
        
        let results = await (try? search(query: "foo:matrix.org").get()) ?? []
        assertSearchResults(results, toBe: 3)
        XCTAssertFalse(clientProxy.profileForCalled)
    }
    
    func testLocalResultShows() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: searchResults, limited: true))
        clientProxy.profileForReturnValue = .success(.init(userID: "@some:matrix.org"))
        
        let results = await (try? search(query: "@a:b.com").get()) ?? []
        
        assertSearchResults(results, toBe: 4)
        XCTAssertTrue(clientProxy.profileForCalled)
    }
    
    func testLocalResultShowsOnSearchError() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        clientProxy.profileForReturnValue = .success(.init(userID: "@some:matrix.org"))
        
        let results = await (try? search(query: "@a:b.com").get()) ?? []
        
        assertSearchResults(results, toBe: 1)
        XCTAssertTrue(clientProxy.profileForCalled)
    }
    
    func testSearchErrorTriggers() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        clientProxy.profileForReturnValue = .success(.init(userID: "@some:matrix.org"))
        
        switch await search(query: "some query") {
        case .success:
            XCTFail("Search users must fail")
        case .failure(let error):
            XCTAssertEqual(error, UserDiscoveryErrorType.failedSearchingUsers)
        }
        
        XCTAssertFalse(clientProxy.profileForCalled)
    }
    
    func testLocalResultWithDuplicates() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: searchResults, limited: true))
        clientProxy.profileForReturnValue = .success(.init(userID: "@bob:matrix.org"))
        
        let results = await (try? search(query: "@a:b.com").get()) ?? []
        
        assertSearchResults(results, toBe: 3)
        let firstUserID = results.first?.userID
        XCTAssertEqual(firstUserID, "@bob:matrix.org")
        XCTAssertTrue(clientProxy.profileForCalled)
    }
    
    func testSearchResultsShowWhenGetProfileFails() async {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: searchResults, limited: true))
        clientProxy.profileForReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        
        let results = await (try? search(query: "@a:b.com").get()) ?? []
        
        let firstUserID = results.first?.userID
        XCTAssertEqual(firstUserID, "@a:b.com")
        XCTAssertTrue(clientProxy.profileForCalled)
    }
    
    // MARK: - Gua federated bare-handle search

    func testBareHandleFansOutAcrossFederationSkippingOwnServer() async {
        makeFederatedService(entries: [("matrix.org", "ACTIVE"), ("ca.gua.example", "ACTIVE"), ("br.gua.example", "ACTIVE")])
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [.mockAlice], limited: false))
        clientProxy.profileForClosure = { userID in .success(.init(userID: userID)) }

        let results = await (try? search(query: "ana-souza").get()) ?? []

        XCTAssertEqual(results.map(\.userID), ["@alice:matrix.org",
                                               "@ana-souza:ca.gua.example",
                                               "@ana-souza:br.gua.example"])
    }

    func testFederatedLookupFailuresAreDropped() async {
        makeFederatedService(entries: [("matrix.org", "ACTIVE"), ("ca.gua.example", "ACTIVE"), ("br.gua.example", "ACTIVE")])
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [.mockAlice], limited: false))
        clientProxy.profileForClosure = { userID in
            userID == "@ana-souza:br.gua.example" ? .success(.init(userID: userID, displayName: "Ana")) : .failure(.sdkError(ClientProxyMockError.generic))
        }

        let results = await (try? search(query: "ana-souza").get()) ?? []

        XCTAssertEqual(results.map(\.userID), ["@alice:matrix.org", "@ana-souza:br.gua.example"])
    }

    func testFederatedMatchesAreDeduplicatedAgainstLocalResults() async {
        makeFederatedService(entries: [("matrix.org", "ACTIVE"), ("ca.gua.example", "ACTIVE")])
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [.init(userID: "@ana-souza:ca.gua.example")], limited: false))
        clientProxy.profileForClosure = { userID in .success(.init(userID: userID)) }

        let results = await (try? search(query: "ana-souza").get()) ?? []

        XCTAssertEqual(results.map(\.userID), ["@ana-souza:ca.gua.example"])
    }

    func testFederatedMatchesShowWhenLocalSearchFails() async {
        makeFederatedService(entries: [("matrix.org", "ACTIVE"), ("ca.gua.example", "ACTIVE")])
        clientProxy.searchUsersSearchTermLimitReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        clientProxy.profileForClosure = { userID in .success(.init(userID: userID)) }

        let results = await (try? search(query: "ana-souza").get()) ?? []

        XCTAssertEqual(results.map(\.userID), ["@ana-souza:ca.gua.example"])
    }

    func testSlowFederatedLookupIsDroppedAfterTimeout() async {
        makeFederatedService(entries: [("matrix.org", "ACTIVE"), ("ca.gua.example", "ACTIVE"), ("br.gua.example", "ACTIVE")],
                             lookupTimeout: .milliseconds(50))
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [.mockAlice], limited: false))
        clientProxy.profileForClosure = { userID in
            if userID == "@ana-souza:ca.gua.example" {
                try? await Task.sleep(for: .seconds(10))
            }
            return .success(.init(userID: userID))
        }

        let results = await (try? search(query: "ana-souza").get()) ?? []

        XCTAssertEqual(results.map(\.userID), ["@alice:matrix.org", "@ana-souza:br.gua.example"])
    }

    func testNonHandleQueryDoesNotFanOut() async {
        makeFederatedService(entries: [("matrix.org", "ACTIVE"), ("ca.gua.example", "ACTIVE")])
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [.mockAlice], limited: false))

        let results = await (try? search(query: "ana souza").get()) ?? []

        assertSearchResults(results, toBe: 1)
        XCTAssertFalse(clientProxy.profileForCalled)
    }

    // MARK: - Private

    private func makeFederatedService(entries: [(serverName: String, status: String)], lookupTimeout: Duration = .seconds(3)) {
        let roster = FederationRoster(entries: entries.map { entry in
            FederationRosterEntry(homeserver: .init(serverName: entry.serverName, searchVisibility: nil, searchGroups: nil),
                                  status: entry.status)
        })
        service = UserDiscoveryService(clientProxy: clientProxy,
                                       federationRosterProvider: StaticRosterProvider(roster: roster),
                                       federatedLookupTimeout: lookupTimeout)
    }

    private func assertSearchResults(_ results: [UserProfileProxy], toBe count: Int) {
        XCTAssertTrue(count >= 0)
        XCTAssertEqual(results.count, count)
        XCTAssertEqual(results.isEmpty, count == 0)
    }
    
    private func search(query: String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        await service.searchProfiles(with: query)
    }
    
    private var searchResults: [UserProfileProxy] {
        [
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
    }
}

private struct StaticRosterProvider: FederationRosterProviding {
    let roster: FederationRoster?

    func currentRoster() async -> FederationRoster? {
        roster
    }
}
