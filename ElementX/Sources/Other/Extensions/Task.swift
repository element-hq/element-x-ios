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

extension Task where Failure == Never {
    /// Runs the given nonthrowing **blocking** operation asynchronously
    /// on the given dispatch queue and awaits the result in a new top-level task.
    ///
    /// This avoids blocking all of the available Task workers with blocking operations,
    /// but still allows us to await the operation.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the operation on.
    ///   - priority: The priority of the task.
    ///   - operation: The operation to perform.
    ///
    /// - Returns: A reference to the task.
    static func dispatched(on queue: DispatchQueue,
                           priority: TaskPriority? = nil,
                           operation: @escaping @Sendable () -> Success) -> Task<Success, Failure> {
        Task.detached(priority: priority) {
            await withCheckedContinuation { continuation in
                queue.async {
                    continuation.resume(returning: operation())
                }
            }
        }
    }
}

extension Task where Failure == Error {
    /// Runs the given throwing **blocking** operation asynchronously
    /// on the given dispatch queue and awaits the result in a new top-level task.
    ///
    /// If the operation throws an error, this method propagates that error.
    ///
    /// This avoids blocking all of the available Task workers with blocking operations,
    /// but still allows us to await the operation.
    ///
    /// - Parameters:
    ///   - queue: The queue to run the operation on.
    ///   - priority: The priority of the task.
    ///   - operation: The operation to perform.
    ///
    /// - Returns: A reference to the task.
    static func dispatched(on queue: DispatchQueue,
                           priority: TaskPriority? = nil,
                           operation: @escaping @Sendable () throws -> Success) -> Task<Success, Failure> {
        Task.detached(priority: priority) {
            try await withCheckedThrowingContinuation { continuation in
                queue.async {
                    do {
                        let result = try operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}
