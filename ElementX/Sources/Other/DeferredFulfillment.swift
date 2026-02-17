//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

struct DeferredFulfillment<T> {
    let closure: () async throws -> T
    
    @discardableResult
    func fulfill() async throws -> T {
        try await closure()
    }
}

/// Utility that assists in subscribing to a publisher and deferring the fulfilment and results until some other actions have been performed.
/// - Parameters:
///   - publisher: The publisher to wait on.
///   - timeout: A timeout after which we give up.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the publisher.
func deferFulfillment<P: Publisher>(_ publisher: P,
                                    timeout: Duration = .seconds(10),
                                    until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<P.Output> {
    var result: Result<P.Output, Error>?
    var hasFulfilled = false
    
    let cancellable = publisher
        .sink { completion in
            switch completion {
            case .failure(let error):
                result = .failure(error)
                hasFulfilled = true
            case .finished:
                break
            }
        } receiveValue: { value in
            if condition(value), !hasFulfilled {
                result = .success(value)
                hasFulfilled = true
            }
        }
    
    return DeferredFulfillment<P.Output> {
        let startTime = ContinuousClock.now
        
        while !hasFulfilled {
            try await Task.sleep(for: .milliseconds(10))
            if ContinuousClock.now - startTime >= timeout {
                break
            }
        }
        
        cancellable.cancel()
        
        guard let unwrappedResult = result else {
            throw DeferredFulfillmentError.noOutput
        }
        return try unwrappedResult.get()
    }
}

/// Utility that assists in observing an async sequence, deferring the fulfilment and results until some condition has been met.
/// - Parameters:
///   - asyncSequence: The sequence to wait on.
///   - timeout: A timeout after which we give up.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the sequence.
func deferFulfillment<Value>(_ asyncSequence: any AsyncSequence<Value, Never>,
                             timeout: Duration = .seconds(10),
                             until condition: @escaping (Value) -> Bool) -> DeferredFulfillment<Value> {
    var result: Result<Value, Error>?
    var hasFulfilled = false
    
    let task = Task {
        for await value in asyncSequence {
            if condition(value), !hasFulfilled {
                result = .success(value)
                hasFulfilled = true
            }
        }
    }
    
    return DeferredFulfillment<Value> {
        let startTime = ContinuousClock.now
        
        while !hasFulfilled {
            try await Task.sleep(for: .milliseconds(10))
            if ContinuousClock.now - startTime >= timeout {
                break
            }
        }
        
        task.cancel()
        
        guard let unwrappedResult = result else {
            throw DeferredFulfillmentError.noOutput
        }
        return try unwrappedResult.get()
    }
}

/// Utility that assists in subscribing to a publisher and deferring the fulfilment and results until some other actions have been performed.
/// - Parameters:
///   - publisher: The publisher to wait on.
///   - keyPath: the key path for the expected values
///   - transitionValues: the values through which the keypath needs to transition through
///   - timeout: A timeout after which we give up.
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the publisher.
func deferFulfillment<P: Publisher, K: KeyPath<P.Output, V>, V: Equatable>(_ publisher: P,
                                                                           keyPath: K,
                                                                           transitionValues: [V],
                                                                           timeout: Duration = .seconds(10)) -> DeferredFulfillment<P.Output> {
    var expectedOrder = transitionValues
    return deferFulfillment(publisher, timeout: timeout) { value in
        let receivedValue = value[keyPath: keyPath]
        if let index = expectedOrder.firstIndex(where: { $0 == receivedValue }), index == 0 {
            expectedOrder.remove(at: index)
        }
        
        return expectedOrder.isEmpty
    }
}

/// Utility that assists in subscribing to an async sequence and deferring the fulfilment and results until some other actions have been performed.
/// - Parameters:
///   - asyncSequence: The sequence to wait on.
///   - transitionValues: the values through which the sequence needs to transition through
///   - timeout: A timeout after which we give up.
/// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the sequence.
func deferFulfillment<Value: Equatable>(_ asyncSequence: any AsyncSequence<Value, Never>,
                                        transitionValues: [Value],
                                        timeout: Duration = .seconds(10)) -> DeferredFulfillment<Value> {
    var expectedOrder = transitionValues
    return deferFulfillment(asyncSequence, timeout: timeout) { value in
        if let index = expectedOrder.firstIndex(where: { $0 == value }), index == 0 {
            expectedOrder.remove(at: index)
        }
        
        return expectedOrder.isEmpty
    }
}

/// Utility that assists in subscribing to a publisher and deferring the failure for a particular value until some other actions have been performed.
/// - Parameters:
///   - publisher: The publisher to wait on.
///   - timeout: A timeout after which we give up.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions. The publisher's result is not returned from this fulfilment.
func deferFailure<P: Publisher>(_ publisher: P,
                                timeout: Duration,
                                until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<Void> where P.Failure == Never {
    var hasFulfilled = false
    let cancellable = publisher
        .sink { value in
            if condition(value), !hasFulfilled {
                hasFulfilled = true
            }
        }
    
    return DeferredFulfillment<Void> {
        let startTime = ContinuousClock.now
        
        while !hasFulfilled {
            try await Task.sleep(for: .milliseconds(10))
            if ContinuousClock.now - startTime >= timeout {
                break
            }
        }
        
        cancellable.cancel()
        
        // For deferFailure, if hasFulfilled is true, it means the condition was met (which is a failure)
        if hasFulfilled {
            throw DeferredFulfillmentError.unexpectedFulfillment
        }
    }
}

/// Utility that assists in subscribing to an async sequence and deferring the failure for a particular value until some other actions have been performed.
/// - Parameters:
///   - asyncSequence: The sequence to wait on.
///   - timeout: A timeout after which we give up.
///   - until: callback that evaluates outputs until some condition is reached
/// - Returns: The deferred fulfilment to be executed after some actions. The sequence's result is not returned from this fulfilment.
func deferFailure<Value>(_ asyncSequence: any AsyncSequence<Value, Never>,
                         timeout: Duration,
                         until condition: @escaping (Value) -> Bool) -> DeferredFulfillment<Void> {
    var hasFulfilled = false
    
    let task = Task {
        for await value in asyncSequence {
            if condition(value), !hasFulfilled {
                hasFulfilled = true
            }
        }
    }
    
    return DeferredFulfillment<Void> {
        let startTime = ContinuousClock.now
        
        while !hasFulfilled {
            try await Task.sleep(for: .milliseconds(10))
            if ContinuousClock.now - startTime >= timeout {
                break
            }
        }
        
        task.cancel()
        
        // For deferFailure, if hasFulfilled is true, it means the condition was met (which is a failure)
        if hasFulfilled {
            throw DeferredFulfillmentError.unexpectedFulfillment
        }
    }
}

enum DeferredFulfillmentError: Error {
    case noOutput
    case unexpectedFulfillment
}
