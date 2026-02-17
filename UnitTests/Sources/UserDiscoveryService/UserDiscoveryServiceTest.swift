//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
struct UserDiscoveryServiceTest {
    private var service: UserDiscoveryService
    private var clientProxy: ClientProxyMock
    
    private var searchResults: [UserProfileProxy] {
        [.mockAlice, .mockBob, .mockCharlie]
    }
    
    init() {
        clientProxy = .init(.init(userID: "@foo:matrix.org"))
        service = UserDiscoveryService(clientProxy: clientProxy)
    }
    
    @Test
    func queryShowingResults() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [UserProfileProxy.mockAlice], limited: true))
        
        let results = await (try? testSetup.search(query: "AAA").get()) ?? []
        testSetup.assertSearchResults(results, toBe: 1)
    }
    
    @Test
    func ownerIsFiltered() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: [UserProfileProxy(userID: "@foo:matrix.org")], limited: true))
        
        let results = await (try? testSetup.search(query: "AAA").get()) ?? []
        testSetup.assertSearchResults(results, toBe: 0)
    }
    
    @Test
    func getProfileIsNotCalled() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: testSetup.searchResults, limited: true))
        testSetup.clientProxy.profileForReturnValue = .success(.init(userID: "@alice:matrix.org"))
        
        let results = await (try? testSetup.search(query: "AAA").get()) ?? []
        testSetup.assertSearchResults(results, toBe: 3)
        #expect(!testSetup.clientProxy.profileForCalled)
    }

    @Test
    func getProfileIsNotCalledForAccountOwnerID() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: testSetup.searchResults, limited: true))
        testSetup.clientProxy.profileForReturnValue = .success(.init(userID: "@alice:matrix.org"))
        
        let results = await (try? testSetup.search(query: "foo:matrix.org").get()) ?? []
        testSetup.assertSearchResults(results, toBe: 3)
        #expect(!testSetup.clientProxy.profileForCalled)
    }
    
    @Test
    func localResultShows() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: testSetup.searchResults, limited: true))
        testSetup.clientProxy.profileForReturnValue = .success(.init(userID: "@some:matrix.org"))
        
        let results = await (try? testSetup.search(query: "@a:b.com").get()) ?? []
        
        testSetup.assertSearchResults(results, toBe: 4)
        #expect(testSetup.clientProxy.profileForCalled)
    }
    
    @Test
    func localResultShowsOnSearchError() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        testSetup.clientProxy.profileForReturnValue = .success(.init(userID: "@some:matrix.org"))
        
        let results = await (try? testSetup.search(query: "@a:b.com").get()) ?? []
        
        testSetup.assertSearchResults(results, toBe: 1)
        #expect(testSetup.clientProxy.profileForCalled)
    }
    
    @Test
    func searchErrorTriggers() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        testSetup.clientProxy.profileForReturnValue = .success(.init(userID: "@some:matrix.org"))
        
        switch await testSetup.search(query: "some query") {
        case .success:
            Issue.record("Search users must fail")
        case .failure(let error):
            #expect(error == UserDiscoveryErrorType.failedSearchingUsers)
        }
        
        #expect(!testSetup.clientProxy.profileForCalled)
    }
    
    @Test
    func localResultWithDuplicates() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: testSetup.searchResults, limited: true))
        testSetup.clientProxy.profileForReturnValue = .success(.init(userID: "@bob:matrix.org"))
        
        let results = await (try? testSetup.search(query: "@a:b.com").get()) ?? []
        
        testSetup.assertSearchResults(results, toBe: 3)
        let firstUserID = results.first?.userID
        #expect(firstUserID == "@bob:matrix.org")
        #expect(testSetup.clientProxy.profileForCalled)
    }
    
    @Test
    func searchResultsShowWhenGetProfileFails() async {
        var testSetup = self
        testSetup.clientProxy.searchUsersSearchTermLimitReturnValue = .success(.init(results: testSetup.searchResults, limited: true))
        testSetup.clientProxy.profileForReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        
        let results = await (try? testSetup.search(query: "@a:b.com").get()) ?? []
        
        let firstUserID = results.first?.userID
        #expect(firstUserID == "@a:b.com")
        #expect(testSetup.clientProxy.profileForCalled)
    }
    
    // MARK: - Private
    
    private func assertSearchResults(_ results: [UserProfileProxy], toBe count: Int) {
        #expect(count >= 0)
        #expect(results.count == count)
        #expect(results.isEmpty == (count == 0))
    }
    
    private func search(query: String) async -> Result<[UserProfileProxy], UserDiscoveryErrorType> {
        await service.searchProfiles(with: query)
    }
}
