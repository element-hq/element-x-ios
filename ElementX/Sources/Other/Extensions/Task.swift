//
// Copyright 2022 New Vector Ltd
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
