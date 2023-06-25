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
