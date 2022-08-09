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

@testable import ElementX
import XCTest

class LoggingTests: XCTestCase {
    private enum Constants {
        static let genericFailure = "Test failed"
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFileLogging() throws {
        MXLogger.deleteLogFiles()
        guard let logFiles = MXLogger.logFiles() else {
            XCTFail(Constants.genericFailure)
            return
        }
        XCTAssertTrue(logFiles.isEmpty)

        let log = UUID().uuidString

        let configuration = MXLogConfiguration()
        configuration.redirectLogsToFiles = true
        MXLog.configure(configuration)
        MXLog.debug(log)
        guard let logFile = MXLogger.logFiles().first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOfFile: logFile)
        XCTAssert(content.contains(log))
    }

    func testLogLevels() throws {
        MXLogger.deleteLogFiles()
        guard let logFiles = MXLogger.logFiles() else {
            XCTFail(Constants.genericFailure)
            return
        }
        XCTAssert(logFiles.isEmpty)

        let log = UUID().uuidString

        let configuration = MXLogConfiguration()
        configuration.logLevel = .error
        configuration.redirectLogsToFiles = true
        MXLog.configure(configuration)
        MXLog.debug(log)
        guard let logFile = MXLogger.logFiles().first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOfFile: logFile)
        XCTAssertFalse(content.contains(log))
    }

    func testSubLogName() {
        MXLogger.deleteLogFiles()
        guard let logFiles = MXLogger.logFiles() else {
            XCTFail(Constants.genericFailure)
            return
        }
        XCTAssert(logFiles.isEmpty)

        let subLogName = "nse"

        let configuration = MXLogConfiguration()
        configuration.subLogName = subLogName
        configuration.redirectLogsToFiles = true
        MXLog.configure(configuration)
        MXLog.debug(UUID().uuidString)
        guard let logFile = MXLogger.logFiles().first else {
            XCTFail(Constants.genericFailure)
            return
        }

        XCTAssertTrue(logFile.contains(subLogName))
    }
}
