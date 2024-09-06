//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class UserDiscoveryServiceTest: XCTestCase {
    var service: UserDiscoveryService!
    var clientProxy: ClientProxyMock!
    
    override func setUpWithError() throws {
        clientProxy = .init(.init(userID: "@foo:matrix.org"))
        service = UserDiscoveryService(clientProxy: clientProxy)
    }
    
    func testQueryShowingResults() async throws {
        clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [UserProfileProxy.mockAlice], limited: true))
        
        let results = await (try? search(query: "AAA").get()) ?? []
        assertSearchResults(results, toBe: 1)
    }
    
    func testOwnerIsFiltered() async throws {
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
    
    // MARK: - Private
    
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
