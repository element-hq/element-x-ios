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
                                                     until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<P.Output> {
    let (stream, continuation) = AsyncStream<P.Output>.makeStream()
    
    let cancellable = publisher
        .sink { _ in
            continuation.finish()
        } receiveValue: { value in
            guard condition(value) else { return }
            continuation.yield(value)
            continuation.finish()
        }
    
    return DeferredFulfillment {
        defer { cancellable.cancel() }
        
        return try await withThrowingTaskGroup(of: P.Output.self) { group in
            group.addTask {
                for await result in stream {
                    return result
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
            return try #require(try await group.next())
        }
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
func deferFulfillment<Value>(_ asyncSequence: any AsyncSequence<Value, Never>,
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
            
            return try #require(try await group.next())
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
                                                                                            sourceLocation: SourceLocation = #_sourceLocation) -> DeferredFulfillment<P.Output> {
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
func deferFulfillment<Value: Equatable>(_ asyncSequence: any AsyncSequence<Value, Never>,
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
                                                 until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<Void> where P.Failure == Never {
    let (stream, continuation) = AsyncStream<Void>.makeStream()
    
    let cancellable = publisher
        .sink { value in
            guard condition(value) else { return }
            continuation.yield(())
            continuation.finish()
        }
    
    return DeferredFulfillment {
        defer { cancellable.cancel() }
        
        try await withThrowingTaskGroup(of: Void.self) { group in
            // If the condition fires before timeout, that's the unexpected failure.
            group.addTask {
                for await _ in stream {
                    throw DeferredFulfillmentError.unexpectedFulfillment(message: message, sourceLocation: sourceLocation)
                }
                // Stream finished without condition firing — this shouldn't happen
                // but is safe to treat as success.
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
