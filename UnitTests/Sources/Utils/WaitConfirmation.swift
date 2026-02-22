//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Synchronization
import Testing

/// A class that provides a mechanism to confirm that a specific action or event
/// has occurred a given number of times within an async context.
///
/// `WaitConfirmation` is used in conjunction with ``waitConfirmation(_:expectedCount:isolation:sourceLocation:_:)``
/// to synchronize async test expectations. It bridges between your test code and
/// Swift Testing's `confirmation` mechanism using an `AsyncStream` under the hood.
///
/// You typically interact with this type via its `callAsFunction()` sugar:
/// ```swift
/// await waitConfirmation { confirmation in
///     sut.onEvent = { confirmation() }
///     sut.triggerEvent()
/// }
/// ```
final class WaitConfirmation: Sendable {
    private let continuation: AsyncStream<Void>.Continuation
    private let expectedCount: Int
    private let confirmationsCount: Mutex<Int>
    
    fileprivate init(continuation: AsyncStream<Void>.Continuation, expectedCount: Int) {
        self.continuation = continuation
        self.expectedCount = expectedCount
        confirmationsCount = .init(0)
    }
    
    /// Confirms that the expected event has occurred once.
    ///
    /// Each call yields a value into the underlying stream, incrementing the confirmation count.
    /// When the count reaches `expectedCount`, the stream is finished, unblocking ``waitConfirmation``.
    ///
    /// This method is thread-safe — the count increment and the finish check are performed
    /// atomically inside a `Mutex` lock.
    func confirm() {
        confirmationsCount.withLock { value in
            continuation.yield()
            value += 1
            if value == expectedCount {
                continuation.finish()
            }
        }
    }
    
    /// Allows the instance to be called directly as a function, forwarding to ``confirm()``.
    ///
    /// This enables the ergonomic shorthand `confirmation()` instead of `confirmation.confirm()`.
    func callAsFunction() {
        confirm()
    }
}

/// Waits for a confirmation to be triggered an expected number of times within a synchronous body.
///
/// This is a wrapper around Swift Testing's `confirmation` that removes the need to manually
/// manage an `AsyncStream` at the call site. The body receives a ``WaitConfirmation`` instance
/// which can be called directly to signal that the expected event occurred.
///
/// The body is synchronous by design — it is intended for setting up mocks and triggering
/// actions that schedule async work, rather than performing async work itself. The async
/// waiting happens internally once the body returns, by draining the stream until all
/// confirmations are received.
///
/// Unlike the timeout variant, this overload does not escape the body closure, which means
/// you can safely capture mutable structs — a common pattern in Swift Testing.
///
/// > Warning: This overload has no timeout. If ``WaitConfirmation/confirm()`` is never called,
/// > the test will hang indefinitely. Prefer the timeout variant when the confirmation
/// > depends on asynchronous work that could silently fail.
///
/// Example:
/// ```swift
/// await waitConfirmation(expectedCount: 2) { confirmation in
///     sut.onEvent = {
///         confirmation()
///     }
///     sut.triggerEvent()
///     sut.triggerEvent()
/// }
/// ```
///
/// - Parameters:
///   - comment: An optional comment to attach to the confirmation for test reporting.
///   - expectedCount: The number of times ``WaitConfirmation/confirm()`` must be called.
///                    Must be greater than 0, otherwise a test failure is recorded and execution stops.
///                    Defaults to `1`.
///   - isolation: The actor isolation context. Defaults to the caller's isolation via `#isolation`.
///   - sourceLocation: The source location for failure reporting. Defaults to the call site via `#_sourceLocation`.
///   - body: A synchronous closure receiving a ``WaitConfirmation`` instance used to signal
///           event occurrences. The closure may throw, and any thrown errors are rethrown to the caller.
///           Typically used to configure mocks and trigger the action under test.
/// - Returns: The value returned by `body`.
func waitConfirmation<R>(_ comment: Comment? = nil,
                         expectedCount: Int = 1,
                         isolation: isolated (any Actor)? = #isolation,
                         sourceLocation: SourceLocation = #_sourceLocation,
                         _ body: (WaitConfirmation) throws -> sending R) async rethrows -> R {
    guard expectedCount > 0 else {
        // Or may run indefinitely
        Issue.record("Expected count must be greater than 0", sourceLocation: sourceLocation)
        preconditionFailure()
    }
    
    let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
    return try await confirmation(comment,
                                  expectedCount: expectedCount,
                                  isolation: isolation,
                                  sourceLocation: sourceLocation) { confirmation in
        let result = try body(.init(continuation: continuation,
                                    expectedCount: expectedCount))
        for await _ in stream {
            confirmation()
        }
        return result
    }
}

/// Waits for a confirmation to be triggered an expected number of times within a synchronous body,
/// with a timeout.
///
/// This overload behaves like ``waitConfirmation(_:expectedCount:isolation:sourceLocation:_:)``
/// but races the stream against a timeout. If the timeout expires before all confirmations
/// are received, the stream is forcefully finished and Swift Testing records whatever
/// confirmations were received up to that point — which will cause a test failure if
/// `expectedCount` was not reached.
///
/// The body is synchronous by design — it is intended for setting up mocks and triggering
/// actions that schedule async work, rather than performing async work itself. The async
/// waiting and timeout racing happen internally once the body returns.
///
/// > Note: Because this overload uses `withTaskGroup` internally to race the stream against
/// > the timeout, the `body` closure is implicitly `@escaping`. This is why this is a separate
/// > overload rather than a single function with an optional timeout — keeping them separate
/// > allows the non-timeout variant to avoid `@escaping`, which lets you capture mutable structs
/// > in `body` as is common in Swift Testing.
///
/// Example:
/// ```swift
/// await waitConfirmation(expectedCount: 1, timeout: .seconds(2)) { confirmation in
///     sut.onNetworkResponse = { confirmation() }
///     sut.startRequest()
/// }
/// ```
///
/// - Parameters:
///   - comment: An optional comment to attach to the confirmation for test reporting.
///   - expectedCount: The number of times ``WaitConfirmation/confirm()`` must be called.
///                    Must be equal to or greater than 0, otherwise a test failure is recorded
///                    and execution stops. Defaults to `1`.
///                    Pass `0` to assert that the event never fires within the timeout window —
///                    useful for verifying that a function does NOT trigger under specific conditions.
///   - timeout: The maximum duration to wait for all confirmations before finishing the stream.
///   - isolation: The actor isolation context. Defaults to the caller's isolation via `#isolation`.
///   - sourceLocation: The source location for failure reporting. Defaults to the call site via `#_sourceLocation`.
///   - body: A synchronous closure receiving a ``WaitConfirmation`` instance used to signal
///           event occurrences. The closure may throw, and any thrown errors are rethrown to the caller.
///           Typically used to configure mocks and trigger the action under test.
/// - Returns: The value returned by `body`.
func waitConfirmation<R>(_ comment: Comment? = nil,
                         expectedCount: Int = 1,
                         timeout: Duration,
                         isolation: isolated (any Actor)? = #isolation,
                         sourceLocation: SourceLocation = #_sourceLocation,
                         _ body: (WaitConfirmation) throws -> sending R) async rethrows -> R {
    guard expectedCount >= 0 else {
        // Or may run indefinitely
        Issue.record("Expected count must be equal or greater than 0", sourceLocation: sourceLocation)
        preconditionFailure()
    }
    
    let (stream, continuation) = AsyncStream.makeStream(of: Void.self)
    return try await confirmation(comment,
                                  expectedCount: expectedCount,
                                  isolation: isolation,
                                  sourceLocation: sourceLocation) { confirmation in
        let result = try body(.init(continuation: continuation,
                                    expectedCount: expectedCount))
        
        // The reason why I don't add to the task group directly the non timeout implementation
        // is that I do not want the body to be marked as @escaping and thus to be able to capture
        // even mutable structs which is common in Swift Testing.
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for await _ in stream {
                    confirmation()
                }
            }
            group.addTask {
                try? await Task.sleep(for: timeout)
                continuation.finish()
            }
            await group.next()
            group.cancelAll()
        }
        
        return result
    }
}
