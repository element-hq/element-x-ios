//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Synchronization

extension Observable {
    /// Creates an async stream for the specified property on this object. We probably won't need this once SE-0475 is available:
    /// https://github.com/swiftlang/swift-evolution/blob/main/proposals/0475-observed.md
    ///
    /// - Parameter property: The key path to the property you would like to observe.
    func observe<Value>(_ property: KeyPath<Self, Value>) -> AsyncStream<Value> {
        AsyncStream { continuation in
            let isActive = Mutex(true)
            
            @Sendable func observe() {
                let value = withObservationTracking {
                    self[keyPath: property]
                } onChange: {
                    // Handle the update on the next run loop as this is willSet not didSet.
                    DispatchQueue.main.async {
                        guard isActive.withLock({ $0 }) else { return }
                        observe()
                    }
                }
                continuation.yield(value)
            }
            
            continuation.onTermination = { _ in isActive.withLock { $0 = false } }
            
            observe()
        }
    }
}
