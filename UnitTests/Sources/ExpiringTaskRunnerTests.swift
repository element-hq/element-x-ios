//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct ExpiringTaskRunnerTests {
    enum ExpiringTaskTestError: Error {
        case failed
    }
    
    @Test
    func succedingTask() async throws {
        let runner = ExpiringTaskRunner {
            try? await Task.sleep(for: .milliseconds(300))
            return true
        }
        
        let result = try await runner.run(timeout: .seconds(1))
        #expect(result == true)
    }
    
    @Test
    func failingTask() async {
        let runner: ExpiringTaskRunner<Result<String, ExpiringTaskTestError>> = ExpiringTaskRunner {
            try? await Task.sleep(for: .milliseconds(300))
            return .failure(.failed)
        }
        
        do {
            _ = try await runner.run(timeout: .seconds(1))
        } catch {
            #expect(error as? ExpiringTaskTestError == ExpiringTaskTestError.failed)
        }
    }
    
    @Test
    func timeoutTask() async {
        let runner = ExpiringTaskRunner {
            try? await Task.sleep(for: .milliseconds(300))
            return true
        }

        do {
            _ = try await runner.run(timeout: .milliseconds(100))
        } catch {
            #expect(error as? ExpiringTaskRunnerError == ExpiringTaskRunnerError.timeout)
        }
    }
}
