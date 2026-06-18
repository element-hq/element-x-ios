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
    @MainActor func observe<Value: Sendable>(_ property: KeyPath<Self, Value>) -> AsyncStream<Value> {
        let (stream, continuation) = AsyncStream<Value>.makeStream()
        let (changeSignals, changeSignaller) = AsyncStream<Void>.makeStream()
        
        // Read and yield the initial value synchronously at subscription time,
        // otherwise observers miss changes made right after creating the stream.
        let initialValue = withObservationTracking {
            self[keyPath: property]
        } onChange: {
            changeSignaller.yield()
        }
        continuation.yield(initialValue)
        
        let task = Task { @MainActor in
            // The signal is sent on willSet, but as this task runs on the next main
            // executor job the new value will have been set by the time we read it.
            for await _ in changeSignals {
                let value = withObservationTracking {
                    self[keyPath: property]
                } onChange: {
                    changeSignaller.yield()
                }
                continuation.yield(value)
            }
        }
        
        continuation.onTermination = { _ in task.cancel() }
        
        return stream
    }
}
