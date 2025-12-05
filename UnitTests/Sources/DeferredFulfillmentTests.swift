//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class DeferredFulfillmentTests: XCTestCase {
    private let observable = SomeObservable()
    
    func testObservableWithoutUpdate() async throws {
        // Given a deferred fulfilment on a value that already matches the expected value.
        let initialValue = observable.counter
        let deferred = deferFulfillment(observable.observe(\.counter)) { $0 == initialValue }
        
        // Then the test should be fulfilled by the initial value and shouldn't timeout whilst waiting for a update.
        try await deferred.fulfill()
    }
    
    func testObservableWithSynchronousUpdate() async throws {
        // Given a deferred fulfilment for an expected value.
        let newValue = 100
        let deferred = deferFulfillment(observable.observe(\.counter)) { $0 == newValue }
        
        // When that value is changed synchronously.
        observable.counter = newValue
        XCTAssertEqual(observable.counter, newValue)
        
        // Then the test should be fulfilled.
        try await deferred.fulfill()
        XCTAssertEqual(observable.counter, newValue)
    }
    
    func testObservableAsynchronousUpdate() async throws {
        // Given a deferred fulfilment for an expected value.
        let newValue = 100
        let deferred = deferFulfillment(observable.observe(\.counter)) { $0 == newValue }
        
        // When that value is changed asynchronously.
        Task { try await observable.setCounter(newValue, delay: .seconds(1)) }
        XCTAssertEqual(observable.counter, 0)
        
        // Then the test should be fulfilled once the update has taken place.
        try await deferred.fulfill()
        XCTAssertEqual(observable.counter, newValue)
    }
    
    func testObservableMultipleUpdates() async throws {
        // Given a deferred fulfilment for an expected value.
        let finalValue = 500
        let deferred = deferFulfillment(observable.observe(\.counter)) { $0 == finalValue }
        
        // When that value is changed asynchronously with some intermediate values before it is reached.
        Task {
            try await observable.setCounter(100, delay: .seconds(.random(in: 1.0...2.0)))
            try await observable.setCounter(250, delay: .seconds(.random(in: 1.0...2.0)))
            try await observable.setCounter(finalValue, delay: .seconds(.random(in: 1.0...2.0)))
        }
        XCTAssertEqual(observable.counter, 0)
        
        // Then the test should be fulfilled once the expected update has taken place.
        try await deferred.fulfill()
        XCTAssertEqual(observable.counter, finalValue)
    }
}

// MARK: - Helpers

@Observable
@MainActor private class SomeObservable {
    var counter = 0
    
    func setCounter(_ newValue: Int, delay: Duration? = nil) async throws {
        if let delay {
            try await Task.sleep(for: delay)
        }
        counter = newValue
    }
}
