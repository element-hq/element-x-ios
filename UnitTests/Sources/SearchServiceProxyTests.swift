//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@MainActor
struct SearchServiceProxyTests {
    let searchService = SearchServiceSDKMock()
    
    private func makeProxy(roomID: String? = nil) async -> SearchServiceProxy {
        searchService.paginationStateReturnValue = .idle(endReached: true)
        searchService.subscribeToPaginationStateUpdatesListenerReturnValue = TaskHandleSDKMock()
        searchService.subscribeToResultsListenerReturnValue = TaskHandleSDKMock()
        
        let proxy = SearchServiceProxy(searchService: searchService,
                                       timelineItemFactory: RoomTimelineItemFactory(userID: "@me:hs.tld",
                                                                                    attributedStringBuilder: AttributedStringBuilder(cacheKey: "tests",
                                                                                                                                     mentionBuilder: PlainMentionBuilder()),
                                                                                    stateEventStringBuilder: RoomStateEventStringBuilder(userID: "@me:hs.tld")),
                                       roomID: roomID)
        // The results subscription is lazy — set a query so the listener exists.
        _ = await proxy.setQuery("query")
        return proxy
    }
    
    private var resultsListener: SearchServiceResultsListener {
        searchService.subscribeToResultsListenerReceivedListener!
    }
    
    /// Content the proxy renders. Hits the `.message` branch of `makeResult`.
    private static let supportedContent = TimelineItemContent.msgLike(content: .init(kind: .message(content: .init(msgType: .text(content: .init(body: "hello", formatted: nil)),
                                                                                                                   body: "hello",
                                                                                                                   isEdited: false,
                                                                                                                   mentions: nil)),
                                                                                     reactions: [],
                                                                                     inReplyTo: nil,
                                                                                     threadRoot: nil,
                                                                                     threadSummary: nil))
    
    /// Content the proxy has no rendering for — this used to be dropped, desyncing the list.
    private static let unsupportedContent = TimelineItemContent.callInvite
    
    private func sdkResult(eventID: String, roomID: String = "!room:hs.tld", supported: Bool = true) -> MatrixRustSDK.SearchServiceResult {
        .message(roomId: roomID, result: .init(eventId: eventID,
                                               sender: "@sender:hs.tld",
                                               senderProfile: .pending,
                                               content: supported ? Self.supportedContent : Self.unsupportedContent,
                                               timestamp: 1_721_500_000_000))
    }
    
    @Test func positionalUpdatesStayAlignedWhenContentIsUnsupported() async throws {
        let proxy = await makeProxy()
        
        // Listener delivery hops through an AsyncStream onto the main actor, so always await the
        // published value rather than reading `resultsPublisher.value` straight after `onUpdate`.
        var deferred = deferFulfillment(proxy.resultsPublisher) { $0.count == 3 }
        resultsListener.onUpdate(updates: [.append(values: [sdkResult(eventID: "$1"),
                                                            sdkResult(eventID: "$2", supported: false),
                                                            sdkResult(eventID: "$3")])])
        try await deferred.fulfill()
        
        // The SDK removes ITS index 1 ($2). A compactMap-filtered local list would drop $3 here.
        deferred = deferFulfillment(proxy.resultsPublisher) { $0.count == 2 }
        resultsListener.onUpdate(updates: [.remove(index: 1)])
        try await deferred.fulfill()
        
        #expect(proxy.resultsPublisher.value.map(\.eventID) == ["$1", "$3"])
    }
    
    @Test func unsupportedContentIsRenderedAsPlaceholderNotDropped() async throws {
        let proxy = await makeProxy()
        
        let deferred = deferFulfillment(proxy.resultsPublisher) { $0.count == 1 }
        resultsListener.onUpdate(updates: [.append(values: [sdkResult(eventID: "$1", supported: false)])])
        try await deferred.fulfill()
        
        #expect(proxy.resultsPublisher.value.first?.eventID == "$1")
    }
    
    @Test func truncateDoesNotTrapWhenUnsupportedContentWasDropped() async throws {
        let proxy = await makeProxy()
        
        let deferred = deferFulfillment(proxy.resultsPublisher) { $0.count == 3 }
        resultsListener.onUpdate(updates: [.append(values: [sdkResult(eventID: "$1", supported: false),
                                                            sdkResult(eventID: "$2", supported: false),
                                                            sdkResult(eventID: "$3")])])
        try await deferred.fulfill()
        
        // The SDK truncates ITS list to 2. Against a filtered list of 1 this is an invalid range
        // (2..<1) and traps.
        let truncated = deferFulfillment(proxy.resultsPublisher) { $0.count == 2 }
        resultsListener.onUpdate(updates: [.truncate(length: 2)])
        try await truncated.fulfill()
        
        #expect(proxy.resultsPublisher.value.map(\.eventID) == ["$1", "$2"])
    }
    
    @Test func resetAndClearReplaceTheWholeList() async throws {
        let proxy = await makeProxy()
        
        var deferred = deferFulfillment(proxy.resultsPublisher) { $0.map(\.eventID) == ["$1", "$2"] }
        resultsListener.onUpdate(updates: [.append(values: [sdkResult(eventID: "$1"),
                                                            sdkResult(eventID: "$2", supported: false)])])
        try await deferred.fulfill()
        
        // `.reset` maps the replacement set totally too — an unsupported result in it must still
        // occupy its slot, or the very next positional update is misaddressed.
        deferred = deferFulfillment(proxy.resultsPublisher) { $0.map(\.eventID) == ["$3", "$4", "$5"] }
        resultsListener.onUpdate(updates: [.reset(values: [sdkResult(eventID: "$3", supported: false),
                                                           sdkResult(eventID: "$4"),
                                                           sdkResult(eventID: "$5", supported: false)])])
        try await deferred.fulfill()
        
        deferred = deferFulfillment(proxy.resultsPublisher) { $0.isEmpty }
        resultsListener.onUpdate(updates: [.clear])
        try await deferred.fulfill()
    }
    
    @Test func setQueryResetsPaginationStateBeforeResultsArrive() async {
        // makeProxy seeds the SDK's state as .idle(endReached: true) — what a cursor that has
        // never run a query reports, and what the previous query would have left behind. Setting a
        // query clears that stale "finished" state; it publishes .loading, since a page is about
        // to be fetched.
        let proxy = await makeProxy()
        
        #expect(proxy.paginationStatePublisher.value == .loading)
    }
    
    @Test func queriesAreEscapedBeforeReachingTheSDK() async {
        let proxy = await makeProxy()
        
        _ = await proxy.setQuery("cats AND dogs")
        
        #expect(searchService.setQueryQueryReceivedInvocations.last == "+cats +\\AND +dogs")
    }
    
    @Test func paginateFailuresAreSurfaced() async {
        enum TestError: Error { case dummy }
        
        let proxy = await makeProxy()
        searchService.paginateThrowableError = TestError.dummy
        
        guard case .failure = await proxy.paginate() else {
            Issue.record("A throwing SDK paginate must surface as .failure")
            return
        }
    }
    
    @Test func roomFilterDoesNotBreakIndexParallelism() async throws {
        let proxy = await makeProxy(roomID: "!r1:hs.tld")
        
        var deferred = deferFulfillment(proxy.resultsPublisher) { $0.map(\.eventID) == ["$1", "$3"] }
        resultsListener.onUpdate(updates: [.append(values: [sdkResult(eventID: "$1", roomID: "!r1:hs.tld"),
                                                            sdkResult(eventID: "$2", roomID: "!r2:hs.tld"),
                                                            sdkResult(eventID: "$3", roomID: "!r1:hs.tld"),
                                                            sdkResult(eventID: "$4", roomID: "!r2:hs.tld")])])
        try await deferred.fulfill()
        
        // SDK index 2 addresses $3 in the UNFILTERED list. Had the filter been applied to the list
        // the diffs land in, index 2 would address the wrong row.
        deferred = deferFulfillment(proxy.resultsPublisher) { $0.map(\.eventID) == ["$1", "$3b"] }
        resultsListener.onUpdate(updates: [.set(index: 2, value: sdkResult(eventID: "$3b", roomID: "!r1:hs.tld"))])
        try await deferred.fulfill()
    }
    
    @Test func popsDoNotTrapOnADrainedList() async throws {
        let proxy = await makeProxy()
        
        let deferred = deferFulfillment(proxy.resultsPublisher) { $0.count == 1 }
        resultsListener.onUpdate(updates: [.append(values: [sdkResult(eventID: "$1", supported: false)])])
        try await deferred.fulfill()
        
        // Against a list drained by filtering, these used to crash outright.
        let popped = deferFulfillment(proxy.resultsPublisher) { $0.isEmpty }
        resultsListener.onUpdate(updates: [.popFront])
        try await popped.fulfill()
    }
}
