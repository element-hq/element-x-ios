//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum ExpiringTaskRunnerError: Error {
    case timeout
}

actor ExpiringTaskRunner<T> {
    private var continuation: CheckedContinuation<T, Error>?
    
    private var task: () async throws -> T
    
    init(_ task: @escaping () async throws -> T) {
        self.task = task
    }
    
    func run(timeout: Duration) async throws -> T {
        try await withCheckedThrowingContinuation {
            continuation = $0
            
            Task {
                try? await Task.sleep(for: timeout)
                continuation?.resume(with: .failure(ExpiringTaskRunnerError.timeout))
                continuation = nil
            }
            
            Task {
                do {
                    let result = try await task()
                    continuation?.resume(with: .success(result))
                } catch {
                    continuation?.resume(with: .failure(error))
                }
                continuation = nil
            }
        }
    }
}
