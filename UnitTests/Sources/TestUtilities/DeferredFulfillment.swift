//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Testing

struct DeferredFulfillment<T> {
    private let closure: () async throws -> T
    
    fileprivate init(_ closure: @escaping () async throws -> T) {
        self.closure = closure
    }
    
    @discardableResult
    func fulfill() async throws -> T {
        try await closure()
    }
}

private struct DeferredFulfillmentError: Error {
    static func noOutput(message: String?, sourceLocation: SourceLocation) -> Self {
        defer { Issue.record(Comment(rawValue: message ?? "No Output"), sourceLocation: sourceLocation) }
        return .init()
    }
    
    static func unexpectedFulfillment(message: String?, sourceLocation: SourceLocation) -> Self {
        defer { Issue.record(Comment(rawValue: message ?? "Unexpected Fulfillment"), sourceLocation: sourceLocation) }
        return .init()
    }
    
    static var empty: Self {
        .init()
    }
}

/// Forwards every value of a publisher into an `AsyncStream` continuation.
///
/// This is intentionally `nonisolated`: the `sink` closures only touch the (thread-safe) continuation,
/// so they can run on whatever queue the publisher emits on — including background queues such as the
/// ones used by `AudioRecorder`/`AudioPlayer`. Filtering against the caller's condition happens on the
/// consuming side, where it can safely run on the caller's actor.
private nonisolated func subscribe<P: Publisher>(_ publisher: P,
                                                 forwardingTo continuation: AsyncStream<P.Output>.Continuation) -> AnyCancellable where P.Failure == Never, P.Output: Sendable {
    publisher.sink { _ in
        continuation.finish()
    } receiveValue: { value in
        continuation.yield(value)
    }
}

/// Test utility that assists in subscribing to a publisher and deferring the fulfilment and results until some other actions have been performed.
/// - Parameters:
///   - publisher: The publisher to wait on.
///   - timeout: A timeout after which we give up.
///   - message: An optional message to include in the error if the condition is never met.
///   - sourceLocation: The source location to attach to any recorded issues.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the publisher.
func deferFulfillment<P: Publisher<P.Output, Never>>(_ publisher: P,
                                                     timeout: Duration = .seconds(10),
                                                     message: String? = nil,
                                                     sourceLocation: SourceLocation = #_sourceLocation,
                                                     until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<P.Output> where P.Output: Sendable {
    let (stream, continuation) = AsyncStream<P.Output>.makeStream()
    let cancellable = subscribe(publisher, forwardingTo: continuation)
    
    return DeferredFulfillment {
        defer { cancellable.cancel() }
        
        let timeoutTask = Task {
            try? await Task.sleep(for: timeout)
            continuation.finish()
        }
        defer { timeoutTask.cancel() }
        
        // `condition` runs on the caller's actor, not the publisher's (possibly background) emission queue.
        for await value in stream where condition(value) {
            return value
        }
        
        guard !Task.isCancelled else {
            // Required to avoid a double recording of the issue in the case where the task is cancelled due to timeout.
            throw DeferredFulfillmentError.empty
        }
        throw DeferredFulfillmentError.noOutput(message: message, sourceLocation: sourceLocation)
    }
}

/// Test utility that assists in observing an async sequence, deferring the fulfilment and results until some condition has been met.
/// - Parameters:
///   - asyncSequence: The sequence to wait on.
///   - timeout: A timeout after which we give up.
///   - message: An optional message to include in the error if the condition is never met.
///   - sourceLocation: The source location to attach to any recorded issues.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the sequence.
func deferFulfillment<Value: Sendable>(_ asyncSequence: any AsyncSequence<Value, Never>,
                                       timeout: Duration = .seconds(10),
                                       message: String? = nil,
                                       sourceLocation: SourceLocation = #_sourceLocation,
                                       until condition: @escaping (Value) -> Bool) -> DeferredFulfillment<Value> {
    let (stream, continuation) = AsyncStream<Value>.makeStream()
    
    let task = Task {
        for await value in asyncSequence where condition(value) {
            continuation.yield(value)
            continuation.finish()
            return
        }
        continuation.finish()
    }
    
    return DeferredFulfillment {
        defer { task.cancel() }
        
        return try await withThrowingTaskGroup(of: Value.self) { group in
            group.addTask {
                for await value in stream {
                    return value
                }
                guard !Task.isCancelled else {
                    // Required to avoid a double recording of the issue in the case where the task is cancelled due to timeout.
                    throw DeferredFulfillmentError.empty
                }
                throw DeferredFulfillmentError.noOutput(message: message, sourceLocation: sourceLocation)
            }
            group.addTask {
                try await Task.sleep(for: timeout)
                throw DeferredFulfillmentError.noOutput(message: message, sourceLocation: sourceLocation)
            }
            
            defer { group.cancelAll() }
            
            return try #require(await group.next())
        }
    }
}

/// Test utility that assists in subscribing to a publisher and deferring the fulfilment and results until some other actions have been performed.
/// - Parameters:
///   - publisher: The publisher to wait on.
///   - keyPath: the key path for the expected values
///   - transitionValues: the values through which the keypath needs to transition through
///   - timeout: A timeout after which we give up.
///   - sourceLocation: The source location to attach to any recorded issues.
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the publisher.
func deferFulfillment<P: Publisher<P.Output, Never>, K: KeyPath<P.Output, V>, V: Equatable>(_ publisher: P,
                                                                                            keyPath: K,
                                                                                            transitionValues: [V],
                                                                                            timeout: Duration = .seconds(10),
                                                                                            message: String? = nil,
                                                                                            sourceLocation: SourceLocation = #_sourceLocation) -> DeferredFulfillment<P.Output> where P.Output: Sendable {
    var expectedOrder = transitionValues
    return deferFulfillment(publisher, timeout: timeout, message: message, sourceLocation: sourceLocation) { value in
        let receivedValue = value[keyPath: keyPath]
        if let index = expectedOrder.firstIndex(where: { $0 == receivedValue }), index == 0 {
            expectedOrder.remove(at: index)
        }
        return expectedOrder.isEmpty
    }
}

/// Test utility that assists in subscribing to an async sequence and deferring the fulfilment and results until some other actions have been performed.
/// - Parameters:
///   - asyncSequence: The sequence to wait on.
///   - transitionValues: the values through which the sequence needs to transition through
///   - timeout: A timeout after which we give up.
///   - sourceLocation: The source location to attach to any recorded issues.
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the sequence.
func deferFulfillment<Value: Equatable & Sendable>(_ asyncSequence: any AsyncSequence<Value, Never>,
                                                   transitionValues: [Value],
                                                   timeout: Duration = .seconds(10),
                                                   message: String? = nil,
                                                   sourceLocation: SourceLocation = #_sourceLocation) -> DeferredFulfillment<Value> {
    var expectedOrder = transitionValues
    return deferFulfillment(asyncSequence, timeout: timeout, message: message, sourceLocation: sourceLocation) { value in
        if let index = expectedOrder.firstIndex(where: { $0 == value }), index == 0 {
            expectedOrder.remove(at: index)
        }
        return expectedOrder.isEmpty
    }
}

/// Test utility that assists in subscribing to a publisher and deferring the failure for a particular value until some other actions have been performed.
/// - Parameters:
///   - publisher: The publisher to wait on.
///   - timeout: A timeout after which we give up.
///   - message: An optional message to include in the error if the condition is unexpectedly met.
///   - sourceLocation: The source location to attach to any recorded issues.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions. The publisher's result is not returned from this fulfilment.
func deferFailure<P: Publisher<P.Output, Never>>(_ publisher: P,
                                                 timeout: Duration,
                                                 message: String? = nil,
                                                 sourceLocation: SourceLocation = #_sourceLocation,
                                                 until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<Void> where P.Failure == Never, P.Output: Sendable {
    let (stream, continuation) = AsyncStream<P.Output>.makeStream()
    let cancellable = subscribe(publisher, forwardingTo: continuation)
    
    return DeferredFulfillment {
        defer { cancellable.cancel() }
        
        let timeoutTask = Task {
            try? await Task.sleep(for: timeout)
            continuation.finish()
        }
        defer { timeoutTask.cancel() }
        
        // `condition` runs on the caller's actor, not the publisher's (possibly background) emission queue.
        // The condition firing before the timeout is the unexpected failure; the timeout elapsing is success.
        for await value in stream where condition(value) {
            throw DeferredFulfillmentError.unexpectedFulfillment(message: message, sourceLocation: sourceLocation)
        }
    }
}

/// Test utility that assists in subscribing to an async sequence and deferring the failure for a particular value until some other actions have been performed.
/// - Parameters:
///   - asyncSequence: The sequence to wait on.
///   - timeout: A timeout after which we give up.
///   - message: An optional message to include in the error if the condition is unexpectedly met.
///   - sourceLocation: The source location to attach to any recorded issues.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions. The sequence's result is not returned from this fulfilment.
func deferFailure<Value>(_ asyncSequence: any AsyncSequence<Value, Never>,
                         timeout: Duration,
                         message: String? = nil,
                         sourceLocation: SourceLocation = #_sourceLocation,
                         until condition: @escaping (Value) -> Bool) -> DeferredFulfillment<Void> {
    let (stream, continuation) = AsyncStream<Void>.makeStream()
    
    let task = Task {
        for await value in asyncSequence where condition(value) {
            continuation.yield(())
            continuation.finish()
            return
        }
        continuation.finish()
    }
    
    return DeferredFulfillment {
        defer { task.cancel() }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // If the condition fires before timeout, that's the unexpected failure.
            group.addTask {
                for await _ in stream {
                    throw DeferredFulfillmentError.unexpectedFulfillment(message: message, sourceLocation: sourceLocation)
                }
            }
            // Timeout elapsing without the condition firing = success.
            group.addTask {
                try await Task.sleep(for: timeout)
            }
            
            defer { group.cancelAll() }
            
            return try #require(try await group.next())
        }
    }
}
