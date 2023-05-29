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
