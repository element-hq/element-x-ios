//
//  LoggingTests.swift
//  UnitTests
//
//  Created by Ismail on 31.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
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
