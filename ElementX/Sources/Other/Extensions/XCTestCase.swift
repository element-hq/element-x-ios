//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

extension XCTestCase {
    /// XCTest utility that assists in subscribing to a publisher and deferring the fulfilment and results until some other actions have been performed.
    /// - Parameters:
    ///   - publisher: The publisher to wait on.
    ///   - timeout: A timeout after which we give up.
    ///   - message: An optional custom expectation message
    ///   - until: callback that evaluates outputs until some condition is reached
    /// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the publisher.
    func deferFulfillment<P: Publisher>(_ publisher: P,
                                        timeout: TimeInterval = 10,
                                        message: String? = nil,
                                        until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<P.Output> {
        var result: Result<P.Output, Error>?
        let expectation = expectation(description: message ?? "Awaiting publisher")
        var hasFullfilled = false
        let cancellable = publisher
            .sink { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                    expectation.fulfill()
                case .finished:
                    break
                }
            } receiveValue: { value in
                if condition(value), !hasFullfilled {
                    result = .success(value)
                    expectation.fulfill()
                    hasFullfilled = true
                }
            }
        
        return DeferredFulfillment<P.Output> {
            await self.fulfillment(of: [expectation], timeout: timeout)
            cancellable.cancel()
            let unwrappedResult = try XCTUnwrap(result, "Awaited publisher did not produce any output")
            return try unwrappedResult.get()
        }
    }
    
    /// XCTest utility that assists in observing an async sequence, deferring the fulfilment and results until some condition has been met.
    /// - Parameters:
    ///   - asyncSequence: The sequence to wait on.
    ///   - timeout: A timeout after which we give up.
    ///   - message: An optional custom expectation message
    ///   - until: callback that evaluates outputs until some condition is reached
    /// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the sequence.
    func deferFulfillment<Value>(_ asyncSequence: any AsyncSequence<Value, Never>,
                                 timeout: TimeInterval = 10,
                                 message: String? = nil,
                                 until condition: @escaping (Value) -> Bool) -> DeferredFulfillment<Value> {
        var result: Result<Value, Error>?
        let expectation = expectation(description: message ?? "Awaiting sequence")
        var hasFulfilled = false
        
        let task = Task {
            for await value in asyncSequence {
                if condition(value), !hasFulfilled {
                    result = .success(value)
                    expectation.fulfill()
                    hasFulfilled = true
                }
            }
        }
        
        return DeferredFulfillment<Value> {
            await self.fulfillment(of: [expectation], timeout: timeout)
            task.cancel()
            let unwrappedResult = try XCTUnwrap(result, "Awaited sequence did not produce any output")
            return try unwrappedResult.get()
        }
    }
    
    /// XCTest utility that assists in subscribing to a publisher and deferring the fulfilment and results until some other actions have been performed.
    /// - Parameters:
    ///   - publisher: The publisher to wait on.
    ///   - keyPath: the key path for the expected values
    ///   - transitionValues: the values through which the keypath needs to transition through
    ///   - timeout: A timeout after which we give up.
    ///   - message: An optional custom expectation message
    /// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the publisher.
    func deferFulfillment<P: Publisher, K: KeyPath<P.Output, V>, V: Equatable>(_ publisher: P,
                                                                               keyPath: K,
                                                                               transitionValues: [V],
                                                                               timeout: TimeInterval = 10,
                                                                               message: String? = nil) -> DeferredFulfillment<P.Output> {
        var expectedOrder = transitionValues
        let deferred = deferFulfillment(publisher, timeout: timeout, message: message) { value in
            let receivedValue = value[keyPath: keyPath]
            if let index = expectedOrder.firstIndex(where: { $0 == receivedValue }), index == 0 {
                expectedOrder.remove(at: index)
            }
            
            return expectedOrder.isEmpty
        }
        
        return deferred
    }
    
    /// XCTest utility that assists in subscribing to an async sequence and deferring the fulfilment and results until some other actions have been performed.
    /// - Parameters:
    ///   - asyncSequence: The sequence to wait on.
    ///   - transitionValues: the values through which the sequence needs to transition through
    ///   - timeout: A timeout after which we give up.
    ///   - message: An optional custom expectation message
    /// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the sequence.
    func deferFulfillment<Value: Equatable>(_ asyncSequence: any AsyncSequence<Value, Never>,
                                            transitionValues: [Value],
                                            timeout: TimeInterval = 10,
                                            message: String? = nil) -> DeferredFulfillment<Value> {
        var expectedOrder = transitionValues
        let deferred = deferFulfillment(asyncSequence, timeout: timeout, message: message) { value in
            if let index = expectedOrder.firstIndex(where: { $0 == value }), index == 0 {
                expectedOrder.remove(at: index)
            }
            
            return expectedOrder.isEmpty
        }
        
        return deferred
    }
    
    /// XCTest utility that assists in subscribing to a publisher and deferring the failure for a particular value until some other actions have been performed.
    /// - Parameters:
    ///   - publisher: The publisher to wait on.
    ///   - timeout: A timeout after which we give up.
    ///   - message: An optional custom expectation message
    ///   - until: callback that evaluates outputs until some condition is reached
    /// - Returns: The deferred fulfilment to be executed after some actions. The publisher's result is not returned from this fulfilment.
    func deferFailure<P: Publisher>(_ publisher: P,
                                    timeout: TimeInterval,
                                    message: String? = nil,
                                    until condition: @escaping (P.Output) -> Bool) -> DeferredFulfillment<Void> where P.Failure == Never {
        let expectation = expectation(description: message ?? "Awaiting publisher")
        expectation.isInverted = true
        var hasFulfilled = false
        let cancellable = publisher
            .sink { value in
                if condition(value), !hasFulfilled {
                    expectation.fulfill()
                    hasFulfilled = true
                }
            }
        
        return DeferredFulfillment<Void> {
            await self.fulfillment(of: [expectation], timeout: timeout)
            cancellable.cancel()
        }
    }
    
    /// XCTest utility that assists in subscribing to an async sequence and deferring the failure for a particular value until some other actions have been performed.
    /// - Parameters:
    ///   - asyncSequence: The sequence to wait on.
    ///   - timeout: A timeout after which we give up.
    ///   - message: An optional custom expectation message
    ///   - until: callback that evaluates outputs until some condition is reached
    /// - Returns: The deferred fulfilment to be executed after some actions. The sequence's result is not returned from this fulfilment.
    func deferFailure<Value>(_ asyncSequence: any AsyncSequence<Value, Never>,
                             timeout: TimeInterval,
                             message: String? = nil,
                             until condition: @escaping (Value) -> Bool) -> DeferredFulfillment<Void> {
        let expectation = expectation(description: message ?? "Awaiting sequence")
        expectation.isInverted = true
        var hasFulfilled = false
        
        let task = Task {
            for await value in asyncSequence {
                if condition(value), !hasFulfilled {
                    expectation.fulfill()
                    hasFulfilled = true
                }
            }
        }
        
        return DeferredFulfillment<Void> {
            await self.fulfillment(of: [expectation], timeout: timeout)
            task.cancel()
        }
    }
    
    struct DeferredFulfillment<T> {
        let closure: () async throws -> T
        @discardableResult func fulfill() async throws -> T {
            try await closure()
        }
    }
}
