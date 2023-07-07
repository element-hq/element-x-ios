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
    ///
    ///  ```
    /// let collectedEvents = somePublisher.collect(3).first()
    /// let awaitDeferred = deferFulfillment(collectedEvents)
    /// // Do some other work that publishes to somePublisher
    /// XCTAssertEqual(try await awaitDeferred.execute(), [expected, values, here])
    ///  ```
    /// - Parameters:
    ///   - publisher: The publisher to wait on.
    ///   - timeout: A timeout after which we give up.
    /// - Returns: The deferred fulfilment to be executed after some actions and that returns the result of the publisher.
    func deferFulfillment<T: Publisher>(_ publisher: T, timeout: TimeInterval = 10, message: String? = nil) -> DeferredFulfillment<T.Output> {
        var result: Result<T.Output, Error>?
        let expectation = expectation(description: message ?? "Awaiting publisher")
        let cancellable = publisher
            .sink { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }
                expectation.fulfill()
            } receiveValue: { value in
                result = .success(value)
            }
        
        return DeferredFulfillment<T.Output> {
            await self.fulfillment(of: [expectation], timeout: timeout)
            cancellable.cancel()
            let unwrappedResult = try XCTUnwrap(result, "Awaited publisher did not produce any output")
            return try unwrappedResult.get()
        }
    }
    
    struct DeferredFulfillment<T> {
        let closure: () async throws -> T
        @discardableResult func fulfill() async throws -> T {
            try await closure()
        }
    }
}
