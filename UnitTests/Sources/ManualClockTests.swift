//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Testing

@MainActor
final class ManualClockTests {
    private let clock = ManualClock()
    
    @Test
    func sleepFinishesOnlyOnceItsDeadlineHasPassed() async throws {
        let (sleepFinished, sleepFinishedContinuation) = AsyncStream<Void>.makeStream()
        let sleeper = Task {
            try await clock.sleep(for: .seconds(10))
            sleepFinishedContinuation.yield()
        }
        
        await clock.waitForScheduledSleep()
        
        let deferredFailure = deferFailure(sleepFinished, timeout: .milliseconds(200)) { _ in true }
        clock.advance(by: .seconds(9))
        try await deferredFailure.fulfill()
        
        clock.advance(by: .seconds(1))
        try await sleeper.value
    }
    
    @Test
    func waitForScheduledSleepReportsTheRequestedDurations() async {
        let firstSleeper = Task { try await clock.sleep(for: .seconds(30)) }
        #expect(await clock.waitForScheduledSleep() == .seconds(30))
        firstSleeper.cancel()
        
        // Cancelling the first sleep frees the clock up to schedule another one.
        let secondSleeper = Task { try await clock.sleep(for: .seconds(90)) }
        #expect(await clock.waitForScheduledSleep() == .seconds(90))
        secondSleeper.cancel()
    }
    
    @Test
    func cancellingASleepingTaskThrows() async {
        let sleeper = Task { try await clock.sleep(for: .seconds(10)) }
        await clock.waitForScheduledSleep()
        
        sleeper.cancel()
        
        await #expect(throws: CancellationError.self) {
            try await sleeper.value
        }
    }
    
    @Test
    func sleepingUntilAPastDeadlineFinishesImmediately() async throws {
        clock.advance(by: .seconds(10))
        #expect(clock.now == ManualClock.Instant(offset: .seconds(10)))
        
        try await clock.sleep(until: ManualClock.Instant(offset: .seconds(5)))
    }
}
