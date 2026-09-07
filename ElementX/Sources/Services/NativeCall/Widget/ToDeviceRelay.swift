//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRtcKit
import Synchronization

// Temporary: part of the widget-driver stopgap. Only needed because a widget driver is per room
// and per call while the core subscribes to to-device messages once per Matrix session; it goes
// with the bridge once the SDK exposes to-device messaging directly.

/// Fans to-device messages from whichever room bridges are live into session-long streams.
final nonisolated class ToDeviceRelay: Sendable {
    private struct Subscriber {
        let eventTypes: Set<String>
        let continuation: AsyncStream<MatrixRtcToDeviceMessage>.Continuation
    }
    
    private let subscribers = Mutex<[UUID: Subscriber]>([:])
    
    /// Messages of the given types for as long as the stream is iterated, whichever bridge delivers them.
    func subscribe(eventTypes: [String]) -> AsyncStream<MatrixRtcToDeviceMessage> {
        let (stream, continuation) = AsyncStream<MatrixRtcToDeviceMessage>.makeStream()
        let id = UUID()
        subscribers.withLock { $0[id] = Subscriber(eventTypes: Set(eventTypes), continuation: continuation) }
        continuation.onTermination = { [weak self] _ in
            self?.subscribers.withLock { _ = $0.removeValue(forKey: id) }
        }
        return stream
    }
    
    func publish(_ message: MatrixRtcToDeviceMessage) {
        let continuations = subscribers.withLock { subscribers in
            subscribers.values.filter { $0.eventTypes.contains(message.eventType) }.map(\.continuation)
        }
        for continuation in continuations {
            continuation.yield(message)
        }
    }
}
