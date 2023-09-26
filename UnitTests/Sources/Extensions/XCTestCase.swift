//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
        let deferred = deferFulfillment<P>(publisher, timeout: timeout, message: message) { value in
            let receivedValue = value[keyPath: keyPath]
            if let index = expectedOrder.firstIndex(where: { $0 == receivedValue }), index == 0 {
                expectedOrder.remove(at: index)
            }
            
            return expectedOrder.isEmpty
        }
        
        return deferred
    }
    
    struct DeferredFulfillment<T> {
        let closure: () async throws -> T
        @discardableResult func fulfill() async throws -> T {
            try await closure()
        }
    }
}
