//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct HomeserverHistoryManagerTests {
    @Test
    func matchExistingServer() {
        // given a configured manager
        let manager = createManager(withServerHistory: [
            "matrix.org",
            "example.com"
        ])
        
        // when querying a value that matches something in the list
        // then it returns that value without case sensitiveity
        #expect(manager.server(matchingPrefix: "ma") == "matrix.org")
        #expect(manager.server(matchingPrefix: "Ma") == "matrix.org")
    }
    
    @Test
    func matchExistingServerinLRUOrder() {
        // given a configured manager with multiple values with similar prefixes
        let manager = createManager(withServerHistory: [
            "matrix.org",
            "mandibles.chomp"
        ])
        
        // when querying the common portions of the prefix
        // then the result is the most recent addition to the list
        #expect(manager.server(matchingPrefix: "m") == "matrix.org")
        #expect(manager.server(matchingPrefix: "ma") == "matrix.org")
        #expect(manager.server(matchingPrefix: "man") == "mandibles.chomp")
    }
    
    @Test
    func serversAreAddedInLRUOrder() {
        // given a configured manager
        let manager = createManager(withServerHistory: [
            "matrix.org",
            "mandibles.chomp"
        ])
        
        // when adding a new server
        manager.addServerToList("merch.com")
        
        // then querying gives priority to the latest addition
        #expect(manager.server(matchingPrefix: "m") == "merch.com")
        #expect(manager.server(matchingPrefix: "ma") == "matrix.org")
        #expect(manager.server(matchingPrefix: "man") == "mandibles.chomp")
    }
    
    @Test
    func serversAreUpdatedInLRUOrder() {
        // given a configured manager
        let manager = createManager(withServerHistory: [
            "matrix.org",
            "mandibles.chomp",
            "merch.com"
        ])
        
        // then querying has its given priority
        #expect(manager.server(matchingPrefix: "m") == "matrix.org")
        #expect(manager.server(matchingPrefix: "me") == "merch.com")
        #expect(manager.server(matchingPrefix: "ma") == "matrix.org")
        #expect(manager.server(matchingPrefix: "man") == "mandibles.chomp")
        
        // when adding an existing server (case insensitive)
        manager.addServerToList("MERCH.com")
        
        // then querying is updated to give the latest prioity
        #expect(manager.server(matchingPrefix: "m") == "merch.com")
        #expect(manager.server(matchingPrefix: "me") == "merch.com")
        #expect(manager.server(matchingPrefix: "ma") == "matrix.org")
        #expect(manager.server(matchingPrefix: "man") == "mandibles.chomp")
    }
    
    @Test func matchNothingOnMiss() {
        // given a configured manager
        let manager = createManager(withServerHistory: [
            "matrix.org",
            "example.com"
        ])
        
        // when making a query that matches nothing in its list, then there are no matches
        #expect(manager.server(matchingPrefix: "mi") == nil)
        #expect(manager.server(matchingPrefix: "g") == nil)
    }
    
    @Test func additionalServerIncludedInResults() {
        // given a configured manager
        let manager = createManager(withServerHistory: [
            "matrix.org",
            "example.com"
        ])
        #expect(manager.server(matchingPrefix: "f") == nil)
        
        // when adding a new server
        manager.addServerToList("FOO.bar")
        
        // then it will become available with subsequent matching queries
        #expect(manager.server(matchingPrefix: "f") == "foo.bar")
        #expect(manager.server(matchingPrefix: "F") == "foo.bar")
    }
    
    @Test func removingServerIsGone() {
        // given a configured manager
        let manager = createManager(withServerHistory: [
            "matrix.org",
            "example.com"
        ])
        
        // when removing a server
        manager.removeServerFromList("example.com")
        
        // then it is no longer available in query results
        #expect(manager.server(matchingPrefix: "e") == nil)
        // and doesn't affect the other server entries
        #expect(manager.server(matchingPrefix: "m") == "matrix.org")
    }
    
    private func createManager(withServerHistory history: [String]) -> HomeserverHistoryManager {
        let appSettings = AppSettings.volatile()
        appSettings.previousServers = history
        
        return HomeserverHistoryManager(appSettings: appSettings)
    }
}
