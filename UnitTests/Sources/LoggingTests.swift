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
        MXLogger.deleteLogFiles()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFileLogging() throws {
        XCTAssertTrue(MXLogger.logFiles.isEmpty)

        let log = UUID().uuidString

        let configuration = MXLogConfiguration()
        configuration.redirectLogsToFiles = true
        MXLog.configure(configuration)
        MXLog.debug(log)
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOf: logFile)
        XCTAssert(content.contains(log))
    }
    
    func testFileRotationOnLaunch() throws {
        // Given a fresh launch with no logs.
        XCTAssertTrue(MXLogger.logFiles.isEmpty)
        
        // When launching the app 5 times.
        let launchCount = 5
        for index in 0..<launchCount {
            let configuration = MXLogConfiguration()
            configuration.redirectLogsToFiles = true
            MXLog.configure(configuration) // This call is only made at app launch.
            MXLog.debug("Launch \(index + 1)")
        }
        
        // Then 5 log files should be created each with the correct contents.
        let logFiles = MXLogger.logFiles
        
        XCTAssertEqual(logFiles.count, launchCount, "The number of log files should match the number of launches.")
        try verifyContents(of: logFiles, after: launchCount)
    }
    
    func testMaxLogFileCount() throws {
        // Given a fresh launch with no logs.
        XCTAssertTrue(MXLogger.logFiles.isEmpty)
        
        // When launching the app 10 times, with a maxLogCount of 5.
        let launchCount = 10
        let logFileCount = 5
        for index in 0..<launchCount {
            let configuration = MXLogConfiguration()
            configuration.maxLogFilesCount = UInt(logFileCount)
            configuration.redirectLogsToFiles = true
            MXLog.configure(configuration) // This call is only made at app launch.
            MXLog.debug("Launch \(index + 1)")
        }
        
        // Then only 5 log files should be stored on disk, with the contents of launches 6 to 10.
        let logFiles = MXLogger.logFiles
        
        XCTAssertEqual(logFiles.count, logFileCount, "The number of log files should match the number of launches.")
        try verifyContents(of: logFiles, after: launchCount)
    }
    
    func testLogFileSizeLimit() throws {
        // Given a fresh launch with no logs.
        XCTAssertTrue(MXLogger.logFiles.isEmpty)
        
        // When launching the app 10 times, with a max total log size of 25KB and logging ~5KB data each time.
        let launchCount = 10
        let logFileSizeLimit = 25 * 1024
        for index in 0..<launchCount {
            let configuration = MXLogConfiguration()
            configuration.logFilesSizeLimit = UInt(logFileSizeLimit)
            configuration.redirectLogsToFiles = true
            MXLog.configure(configuration) // This call is only made at app launch.
            MXLog.debug("Launch \(index + 1)")
            
            // Add ~5KB of logs
            for _ in 0..<5 {
                let string = [String](repeating: "a", count: 1024).joined()
                MXLog.debug(string)
            }
        }
        
        // Then only the most recent log files should be stored on disk.
        let logFiles = MXLogger.logFiles
        
        XCTAssertGreaterThan(logFiles.count, 0, "There should be at least one log file created.")
        XCTAssertLessThan(logFiles.count, launchCount, "Some of the log files should have been removed trimmed.")
        try verifyContents(of: logFiles, after: launchCount)
    }
    
    /// Verifies that the log files all contain the correct `Launch #` based on the index
    /// in the file name and the number of launches of the app.
    func verifyContents(of logFiles: [URL], after launchCount: Int) throws {
        for logFile in logFiles {
            let regex = /\d+/
            let fileIndex = logFile.lastPathComponent.firstMatch(of: regex)?.0 ?? "0"
            
            guard let index = Int(fileIndex) else {
                XCTFail(Constants.genericFailure)
                return
            }
            
            let content = try String(contentsOf: logFile)
            XCTAssertTrue(content.contains("Launch \(launchCount - index)"), "The log files should be for the most recent launches in reverse chronological order.")
        }
    }

    func testLogLevels() throws {
        XCTAssert(MXLogger.logFiles.isEmpty)

        let log = UUID().uuidString

        let configuration = MXLogConfiguration()
        configuration.logLevel = .error
        configuration.redirectLogsToFiles = true
        MXLog.configure(configuration)
        MXLog.debug(log)
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOf: logFile)
        XCTAssertFalse(content.contains(log))
    }

    func testSubLogName() {
        XCTAssert(MXLogger.logFiles.isEmpty)

        let subLogName = "nse"

        let configuration = MXLogConfiguration()
        configuration.subLogName = subLogName
        configuration.redirectLogsToFiles = true
        MXLog.configure(configuration)
        MXLog.debug(UUID().uuidString)
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        XCTAssertTrue(logFile.lastPathComponent.contains(subLogName))
    }
}
