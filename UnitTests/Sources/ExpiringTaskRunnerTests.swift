//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

import XCTest

@testable import ElementX

class ExpiringTaskRunnerTests: XCTestCase {
    enum ExpiringTaskTestError: Error {
        case failed
    }
    
    func testSuccedingTask() async {
        let runner = ExpiringTaskRunner {
            try? await Task.sleep(for: .milliseconds(300))
            return true
        }
        
        let result = try? await runner.run(timeout: .seconds(1))
        XCTAssertEqual(result, true)
    }
    
    func testFailingTask() async {
        let runner: ExpiringTaskRunner<Result<String, ExpiringTaskTestError>> = ExpiringTaskRunner {
            try? await Task.sleep(for: .milliseconds(300))
            return .failure(.failed)
        }
        
        do {
            _ = try await runner.run(timeout: .seconds(1))
        } catch {
            XCTAssertEqual(error as? ExpiringTaskTestError, ExpiringTaskTestError.failed)
        }
    }
    
    func testTimeoutTask() async {
        let runner = ExpiringTaskRunner {
            try? await Task.sleep(for: .milliseconds(300))
            return true
        }

        do {
            _ = try await runner.run(timeout: .milliseconds(100))
        } catch {
            XCTAssertEqual(error as? ExpiringTaskRunnerError, ExpiringTaskRunnerError.timeout)
        }
    }
}
