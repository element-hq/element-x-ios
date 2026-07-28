//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

/// These tests pin the LOOP SHAPE and nothing more.
///
/// They cannot show that a single message becomes searchable: the chain from `paginateBackwards`
/// through the SDK event cache into the index has no app-level observation point, and no index API is
/// exposed over FFI. A fully green file here means the loop iterated correctly over mocks. It is not
/// evidence the feature works and must never be cited as such.
@MainActor
struct SearchBackfillRunnerTests {
    @Test
    func eachRoomIsPaginatedUntilItReportsTheStartOfTheRoom() async {
        let room = makeRoom(reachStartAfter: 3)
        let runner = makeRunner(rooms: ["!a:server": room])
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(room.timelineMock.paginateBackwardsRequestSizeCallsCount == 3)
        #expect(cursor.outcomes["!a:server"] == .reachedStart)
        #expect(cursor.isDrained)
    }
    
    @Test
    func theRoomIsNeverSubscribedForUpdates() async {
        // The one-way-door regression test. `subscribeForUpdates()` registers the room with the room
        // list service, which exposes no way to unsubscribe, so a sweep that subscribed would
        // permanently grow the session's subscription set.
        let room = makeRoom(reachStartAfter: 1)
        let runner = makeRunner(rooms: ["!a:server": room])
        
        await runner.runOnce(excludedRoomIDs: [])
        
        #expect(room.proxyMock.subscribeForUpdatesCallsCount == 0)
        #expect(room.timelineMock.subscribeForUpdatesCallsCount == 0)
    }
    
    @Test
    func paginationStopsAtThePerRoomPageCap() async {
        let room = makeRoom(reachStartAfter: .max)
        let runner = makeRunner(rooms: ["!a:server": room], budget: makeBudget(maxPagesPerRoom: 4))
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(room.timelineMock.paginateBackwardsRequestSizeCallsCount == 4)
        #expect(cursor.outcomes["!a:server"] == .pageCap)
    }
    
    @Test
    func theConfiguredPageSizeIsRequested() async {
        let room = makeRoom(reachStartAfter: 2)
        let runner = makeRunner(rooms: ["!a:server": room], budget: makeBudget(pageSize: 99))
        
        await runner.runOnce(excludedRoomIDs: [])
        
        #expect(room.timelineMock.paginateBackwardsRequestSizeReceivedInvocations == [99, 99])
    }
    
    @Test
    func aRoomIsAbandonedAfterRepeatedFailuresAndTheSweepContinues() async {
        let failing = makeRoom(failEveryPage: true)
        let healthy = makeRoom(reachStartAfter: 1)
        let runner = makeRunner(rooms: ["!a:server": failing, "!b:server": healthy],
                                queue: ["!a:server", "!b:server"],
                                budget: makeBudget(maxFailuresPerRoom: 2))
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(failing.timelineMock.paginateBackwardsRequestSizeCallsCount == 2)
        #expect(cursor.outcomes["!a:server"] == .failed)
        #expect(cursor.failures["!a:server"] == 1)
        // The important half: one bad room must not sink the sweep.
        #expect(cursor.outcomes["!b:server"] == .reachedStart)
    }
    
    @Test
    func aRoomThatIsNoLongerJoinedIsSkippedWithoutPaginating() async {
        let runner = makeRunner(rooms: [:], queue: ["!a:server"])
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(cursor.outcomes["!a:server"] == .notJoined)
    }
    
    @Test
    func anExcludedRoomIsNeverEvenResolved() async {
        // The room the user is looking at: a second live timeline paginating it would issue
        // undeduplicated requests and make items jump around underneath them.
        let room = makeRoom(reachStartAfter: 1)
        let clientProxy = ClientProxyMock(.init())
        let runner = makeRunner(rooms: ["!a:server": room], queue: ["!a:server"], clientProxy: clientProxy)
        
        let cursor = await runner.runOnce(excludedRoomIDs: ["!a:server"])
        
        #expect(room.timelineMock.paginateBackwardsRequestSizeCallsCount == 0)
        #expect(!clientProxy.roomForIdentifierReceivedInvocations.contains("!a:server"))
        #expect(cursor.isDrained)
    }
    
    @Test
    func anExcludedRoomIsRetriedLaterInTheSameGenerationRatherThanBeingDropped() async {
        // Regression: consuming the excluded room would make the room the user opens search in the
        // one room that never gets backfilled.
        let excluded = makeRoom(reachStartAfter: 1)
        let other = makeRoom(reachStartAfter: 1)
        let runner = makeRunner(rooms: ["!open:server": excluded, "!other:server": other],
                                queue: ["!open:server", "!other:server"])
        
        let cursor = await runner.runOnce(excludedRoomIDs: ["!open:server"])
        
        // Moved behind the rooms that could be swept, so a later execution still covers it. It stays
        // unpaginated here because the exclusion holds for the whole execution.
        #expect(cursor.queue == ["!open:server", "!other:server", "!open:server"])
        #expect(excluded.timelineMock.paginateBackwardsRequestSizeCallsCount == 0)
        #expect(other.timelineMock.paginateBackwardsRequestSizeCallsCount == 1)
        #expect(cursor.isDrained)
    }
    
    @Test
    func anExcludedRoomIsNotQueuedTwice() async {
        // The re-queue must be idempotent, or a permanently-excluded room would grow the queue on
        // every pass and the sweep would never drain.
        let excluded = makeRoom(reachStartAfter: 1)
        let runner = makeRunner(rooms: ["!open:server": excluded],
                                queue: ["!open:server", "!open:server"])
        
        let cursor = await runner.runOnce(excludedRoomIDs: ["!open:server"])
        
        // Re-queued once, not once per pass — otherwise the sweep would never drain.
        #expect(cursor.queue == ["!open:server", "!open:server", "!open:server"])
        #expect(excluded.timelineMock.paginateBackwardsRequestSizeCallsCount == 0)
        #expect(cursor.isDrained)
    }
    
    @Test
    func theExecutionPageBudgetStopsTheSweepEarlyAndIsRecorded() async {
        var rooms: [String: TestRoom] = [:]
        for index in 1...5 {
            rooms["!room\(index):server"] = makeRoom(reachStartAfter: .max)
        }
        let runner = makeRunner(rooms: rooms,
                                queue: (1...5).map { "!room\($0):server" },
                                budget: makeBudget(maxPagesPerRoom: 10, maxPagesPerExecution: 15))
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(cursor.pagesIssued <= 15)
        #expect(cursor.stoppedByBudget)
        #expect(!cursor.isDrained)
    }
    
    @Test
    func aStoredCursorResumesWhereItStoppedAndDoesNotRevisitEarlierRooms() async {
        let first = makeRoom(reachStartAfter: 1)
        let second = makeRoom(reachStartAfter: 1)
        let store = InMemoryStore(cursor: .init(generation: 1, queue: ["!a:server", "!b:server"], index: 1))
        let rebuildingTheQueue: () -> [String] = {
            Issue.record("must not rebuild the queue while one is in progress")
            return []
        }
        let runner = makeRunner(rooms: ["!a:server": first, "!b:server": second],
                                store: store,
                                queueProvider: rebuildingTheQueue)
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(first.timelineMock.paginateBackwardsRequestSizeCallsCount == 0)
        #expect(second.timelineMock.paginateBackwardsRequestSizeCallsCount == 1)
        #expect(cursor.isDrained)
    }
    
    @Test
    func aDrainedCursorStartsANewGeneration() async {
        let store = InMemoryStore(cursor: .init(generation: 4, queue: ["!a:server"], index: 1))
        let runner = makeRunner(rooms: ["!b:server": makeRoom(reachStartAfter: 1)],
                                queue: ["!b:server"],
                                store: store)
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(cursor.generation == 5)
        #expect(cursor.queue == ["!b:server"])
    }
    
    @Test
    func progressIsPersistedAfterEveryRoom() async {
        let store = InMemoryStore()
        let runner = makeRunner(rooms: ["!a:server": makeRoom(reachStartAfter: 1),
                                        "!b:server": makeRoom(reachStartAfter: 1)],
                                queue: ["!a:server", "!b:server"],
                                store: store)
        
        await runner.runOnce(excludedRoomIDs: [])
        
        // Two rooms plus the final write: process death costs at most one room of progress.
        #expect(store.writes >= 3)
        #expect(await store.cursor()?.isDrained == true)
    }
    
    @Test
    func anEmptyQueueAsksForAnotherExecutionInsteadOfReportingCompletion() async {
        // A headless start right after the caches were cleared can see an empty room list. Reading
        // that as "all done" would park the sweep with nothing indexed.
        let runner = makeRunner(rooms: [:], queue: [])
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(cursor.needsAnotherExecution)
        #expect(cursor.finishedAt != nil)
    }
    
    @Test
    func aDrainedQueueWithVisitedRoomsDoesNotAskForAnotherExecution() async {
        let runner = makeRunner(rooms: ["!a:server": makeRoom(reachStartAfter: 1)])
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(!cursor.needsAnotherExecution)
    }
    
    @Test
    func theExecutionDeadlineStopsTheSweepBetweenRooms() async {
        // Every other test freezes the clock, so without this the time budgets are never exercised at
        // all and a wrong comparison would pass silently.
        var rooms: [String: TestRoom] = [:]
        for index in 1...5 {
            rooms["!room\(index):server"] = makeRoom(reachStartAfter: 1)
        }
        // Advances 40s per reading, so the 60s deadline trips after the first room.
        let clock = SteppingClock(step: 40)
        let runner = makeRunner(rooms: rooms,
                                queue: (1...5).map { "!room\($0):server" },
                                budget: makeBudget(executionDeadline: .seconds(60)),
                                now: clock.now)
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(cursor.stoppedByBudget)
        #expect(!cursor.isDrained)
        // Later rooms must be left untouched for the next execution to resume into.
        #expect(rooms.values.filter { $0.timelineMock.paginateBackwardsRequestSizeCallsCount > 0 }.count < rooms.count)
    }
    
    @Test
    func thePerRoomTimeLimitStopsThatRoomAndMovesOn() async {
        let slow = makeRoom(reachStartAfter: .max)
        let clock = SteppingClock(step: 4)
        let runner = makeRunner(rooms: ["!a:server": slow],
                                budget: makeBudget(maxPagesPerRoom: 100, maxRoomDuration: .seconds(10)),
                                now: clock.now)
        
        let cursor = await runner.runOnce(excludedRoomIDs: [])
        
        #expect(cursor.outcomes["!a:server"] == .pageCap)
        // Time, not the page cap of 100, is what stopped it.
        #expect(slow.timelineMock.paginateBackwardsRequestSizeCallsCount < 100)
    }
    
    // MARK: - Helpers
    
    private func makeBudget(pageSize: UInt16 = 10,
                            maxPagesPerRoom: Int = 200,
                            maxPagesPerExecution: Int = 300,
                            executionDeadline: Duration = .seconds(300),
                            maxRoomDuration: Duration = .seconds(45),
                            maxFailuresPerRoom: Int = 2) -> SearchBackfillBudget {
        // Zero delays: these tests assert page counts, never elapsed time.
        SearchBackfillBudget(pageSize: pageSize,
                             maxPagesPerRoom: maxPagesPerRoom,
                             maxPagesPerExecution: maxPagesPerExecution,
                             executionDeadline: executionDeadline,
                             maxRoomDuration: maxRoomDuration,
                             maxFailuresPerRoom: maxFailuresPerRoom,
                             delayBetweenPages: .zero,
                             delayBetweenRooms: .zero)
    }
    
    private func makeRunner(rooms: [String: TestRoom],
                            queue: [String]? = nil,
                            budget: SearchBackfillBudget? = nil,
                            store: SearchBackfillStoreProtocol = InMemoryStore(),
                            clientProxy: ClientProxyMock? = nil,
                            queueProvider: (() -> [String])? = nil,
                            now: (() -> Date)? = nil) -> SearchBackfillRunner {
        let clientProxy = clientProxy ?? ClientProxyMock(.init())
        clientProxy.roomForIdentifierClosure = { identifier in
            rooms[identifier].map { .joined($0.proxyMock) }
        }
        
        let resolvedQueue = queue ?? Array(rooms.keys)
        
        return SearchBackfillRunner(clientProxy: clientProxy,
                                    store: store,
                                    roomQueueProvider: { queueProvider?() ?? resolvedQueue },
                                    budget: budget ?? makeBudget(),
                                    // Frozen by default: these tests assert page counts, not time.
                                    timeProvider: .init(clock: ContinuousClock(), now: now ?? { .distantPast }))
    }
    
    private func makeRoom(reachStartAfter: Int = 1, failEveryPage: Bool = false) -> TestRoom {
        let timelineMock = TimelineProxyMock(.init())
        let proxyMock = JoinedRoomProxyMock(.init())
        proxyMock.timeline = timelineMock
        
        timelineMock.paginateBackwardsRequestSizeClosure = { _ in
            if failEveryPage {
                return .failure(.sdkError(SearchBackfillTestError.network))
            }
            return .success(timelineMock.paginateBackwardsRequestSizeCallsCount >= reachStartAfter)
        }
        
        return TestRoom(proxyMock: proxyMock, timelineMock: timelineMock)
    }
}

private enum SearchBackfillTestError: Error { case network }

@MainActor
private struct TestRoom {
    let proxyMock: JoinedRoomProxyMock
    let timelineMock: TimelineProxyMock
}

/// Returns a date that jumps forward a fixed number of seconds on every reading, so the time budgets
/// are exercised without sleeping or leaning on a `TestClock` that can be starved on a busy runner.
private final class SteppingClock: @unchecked Sendable {
    private let step: TimeInterval
    private var reading: TimeInterval = 0
    private let lock = NSLock()
    
    init(step: TimeInterval) {
        self.step = step
    }
    
    func now() -> Date {
        lock.withLock {
            let current = reading
            reading += step
            return Date(timeIntervalSinceReferenceDate: current)
        }
    }
}

private final class InMemoryStore: SearchBackfillStoreProtocol, @unchecked Sendable {
    private let lock = NSLock()
    private var stored: SearchBackfillCursor?
    private(set) var writes = 0
    
    init(cursor: SearchBackfillCursor? = nil) {
        stored = cursor
    }
    
    func cursor() async -> SearchBackfillCursor? {
        lock.withLock { stored }
    }
    
    func save(_ cursor: SearchBackfillCursor) async {
        lock.withLock {
            writes += 1
            stored = cursor
        }
    }
    
    func clear() async {
        lock.withLock { stored = nil }
    }
}
