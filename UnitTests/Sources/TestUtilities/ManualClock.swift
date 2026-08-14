//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Synchronization

/// A clock whose sleeps only finish when the test advances it.
final nonisolated class ManualClock: Clock {
    struct Instant: InstantProtocol {
        let offset: Duration
        
        func advanced(by duration: Duration) -> Self {
            Self(offset: offset + duration)
        }
        
        func duration(to other: Self) -> Duration {
            other.offset - offset
        }
        
        static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.offset < rhs.offset
        }
    }
    
    private struct Sleep {
        let deadline: Instant
        let continuation: CheckedContinuation<Void, any Error>
    }
    
    private struct State {
        var now = Instant(offset: .zero)
        /// A test steps through one timer at a time, so a single sleep can be pending.
        var sleep: Sleep?
        var sleepObserver: CheckedContinuation<Duration, Never>?
    }
    
    private let state = Mutex(State())
    
    let minimumResolution: Duration = .zero
    
    var now: Instant {
        state.withLock { $0.now }
    }
    
    /// Suspends until ``advance(by:)`` moves the clock to `deadline`, or the calling task is
    /// cancelled, in which case this throws a `CancellationError`. Deadlines that have already
    /// passed return without suspending. `tolerance` is ignored.
    func sleep(until deadline: Instant, tolerance: Duration? = nil) async throws {
        try await withTaskCancellationHandler {
            try Task.checkCancellation()
            
            try await withCheckedThrowingContinuation { continuation in
                switch schedule(deadline: deadline, continuation: continuation) {
                case .elapsed:
                    continuation.resume()
                case .scheduled(let duration, let observer):
                    observer?.resume(returning: duration)
                    
                    // Cancellation that landed while scheduling found nothing to cancel.
                    if Task.isCancelled {
                        cancelSleep()
                    }
                }
            }
        } onCancel: {
            cancelSleep()
        }
    }
    
    /// Suspends until a sleep is pending and returns how long it has left to run. A sleep that is
    /// already pending returns straight away, so a scheduled sleep can't be missed.
    ///
    /// Await this before advancing a timer that runs in an unstructured task — advancing the clock
    /// before the sleep has been scheduled would leave it sleeping past the new deadline.
    @discardableResult
    func waitForScheduledSleep() async -> Duration {
        await withCheckedContinuation { continuation in
            let duration = state.withLock { state -> Duration? in
                guard let sleep = state.sleep else {
                    state.sleepObserver = continuation
                    return nil
                }
                
                return state.now.duration(to: sleep.deadline)
            }
            
            if let duration {
                continuation.resume(returning: duration)
            }
        }
    }
    
    /// Moves ``now`` forward, resuming the pending sleep if it has come due. Resuming is all this
    /// does — wait on the work the sleep unblocks rather than assuming it has run by the time this
    /// returns.
    func advance(by duration: Duration) {
        let dueSleep = state.withLock { state -> Sleep? in
            state.now = state.now.advanced(by: duration)
            
            guard let sleep = state.sleep, sleep.deadline <= state.now else {
                return nil
            }
            
            state.sleep = nil
            return sleep
        }
        
        dueSleep?.continuation.resume()
    }
    
    // MARK: - Private
    
    private enum Scheduling {
        /// The deadline had already passed, the sleep doesn't suspend.
        case elapsed
        /// The sleep is now pending, along with the ``waitForScheduledSleep()`` caller to notify.
        case scheduled(Duration, observer: CheckedContinuation<Duration, Never>?)
    }
    
    /// Stores the sleep's continuation, handing the caller whatever needs resuming so that it
    /// happens outside of the lock.
    private func schedule(deadline: Instant, continuation: CheckedContinuation<Void, any Error>) -> Scheduling {
        state.withLock { state in
            guard deadline > state.now else {
                return .elapsed
            }
            
            precondition(state.sleep == nil, "The clock only supports a single pending sleep.")
            
            state.sleep = Sleep(deadline: deadline, continuation: continuation)
            
            let observer = state.sleepObserver
            state.sleepObserver = nil
            
            return .scheduled(state.now.duration(to: deadline), observer: observer)
        }
    }
    
    private func cancelSleep() {
        let sleep = state.withLock { state -> Sleep? in
            let sleep = state.sleep
            state.sleep = nil
            return sleep
        }
        
        sleep?.continuation.resume(throwing: CancellationError())
    }
}
