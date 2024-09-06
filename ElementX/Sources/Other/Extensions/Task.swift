//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

public extension Task where Success == Never, Failure == Never {
    /// Dispatches the given closure onto the given queue, wrapped within
    /// a continuation to make it non-blocking and awaitable.
    ///
    /// Use this method to `await` blocking calls to the SDK from a `Task`.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the closure on.
    ///   - function: A string identifying the declaration that is the notional
    ///     source for the continuation, used to identify the continuation in
    ///     runtime diagnostics related to misuse of this continuation.
    ///   - body: A sendable closure. Use of sendable won't work as it isn't
    ///     async, but is added to enforce actor semantics.
    static func dispatch<T>(on queue: DispatchQueue, function: String = #function, _ body: @escaping @Sendable () -> T) async -> T {
        await withCheckedContinuation(function: function) { continuation in
            queue.async {
                continuation.resume(returning: body())
            }
        }
    }

    /// Dispatches the given throwing closure onto the given queue, wrapped within
    /// a continuation to make it non-blocking and awaitable.
    ///
    /// Use this method to `await` blocking calls to the SDK from a `Task`.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the closure on.
    ///   - function: A string identifying the declaration that is the notional
    ///     source for the continuation, used to identify the continuation in
    ///     runtime diagnostics related to misuse of this continuation.
    ///   - body: A sendable closure. Use of sendable won't work as it isn't
    ///     async, but is added to enforce actor semantics.
    static func dispatch<T>(on queue: DispatchQueue, function: String = #function, _ body: @escaping @Sendable () throws -> T) async throws -> T {
        try await withCheckedThrowingContinuation(function: function) { continuation in
            queue.async {
                do {
                    try continuation.resume(returning: body())
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}

extension Task {
    func store(in cancellables: inout Set<AnyCancellable>) {
        asCancellable().store(in: &cancellables)
    }

    func asCancellable() -> AnyCancellable {
        AnyCancellable(cancel)
    }
}
