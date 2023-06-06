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
@testable import MatrixRustSDK
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

        MXLog.configure(redirectToFiles: true)
        
        MXLog.info(log)
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
            MXLog.configure(redirectToFiles: true)
            MXLog.info("Launch \(index + 1)")
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
            MXLog.configure(redirectToFiles: true, maxLogFileCount: UInt(logFileCount))
            MXLog.info("Launch \(index + 1)")
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
        let logFileSizeLimit: UInt = 25 * 1024
        for index in 0..<launchCount {
            MXLog.configure(redirectToFiles: true, logFileSizeLimit: logFileSizeLimit)
            MXLog.info("Launch \(index + 1)")
            
            // Add ~5KB of logs
            for _ in 0..<5 {
                let string = [String](repeating: "a", count: 1024).joined()
                MXLog.info(string)
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

        MXLog.configure(redirectToFiles: true)
        
        MXLog.verbose(log)
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOf: logFile)
        XCTAssertFalse(content.contains(log))
    }

    func testSubLogName() {
        XCTAssert(MXLogger.logFiles.isEmpty)

        let target = "nse"

        MXLog.configure(target: target, redirectToFiles: true)
        
        MXLog.info(UUID().uuidString)
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        XCTAssertTrue(logFile.lastPathComponent.contains(target))
    }
    
    func testLogFileSorting() async throws {
        // Given a collection of log files.
        XCTAssertTrue(MXLogger.logFiles.isEmpty)
        
        // When creating new logs.
        let logsFileDirectory = URL.appGroupContainerDirectory
        for i in 1...5 {
            let filename = "console.\(i).log"
            try "console".write(to: logsFileDirectory.appending(path: filename), atomically: true, encoding: .utf8)
        }
        
        for i in 1...5 {
            let nseFilename = "console-nse.\(i).log"
            try "nse".write(to: logsFileDirectory.appending(path: nseFilename), atomically: true, encoding: .utf8)
        }
        
        // Then the logs should be sorted chronologically (newest first) and not alphabetically.
        XCTAssertEqual(MXLogger.logFiles.map(\.lastPathComponent),
                       ["console-nse.5.log",
                        "console-nse.4.log",
                        "console-nse.3.log",
                        "console-nse.2.log",
                        "console-nse.1.log",
                        "console.5.log",
                        "console.4.log",
                        "console.3.log",
                        "console.2.log",
                        "console.1.log"])
        
        // When updating the oldest log file.
        let currentLogFile = logsFileDirectory.appending(path: "console.1.log")
        let fileHandle = try FileHandle(forWritingTo: currentLogFile)
        try fileHandle.seekToEnd()
        guard let newLineData = "newline".data(using: .utf8) else {
            XCTFail("Couldn't create data to write to disk.")
            return
        }
        
        try fileHandle.write(contentsOf: newLineData)
        try fileHandle.close()
        
        // Then that file should now be the first log file.
        XCTAssertEqual(MXLogger.logFiles.map(\.lastPathComponent),
                       ["console.1.log",
                        "console-nse.5.log",
                        "console-nse.4.log",
                        "console-nse.3.log",
                        "console-nse.2.log",
                        "console-nse.1.log",
                        "console.5.log",
                        "console.4.log",
                        "console.3.log",
                        "console.2.log"])
    }
    
    func testRoomSummaryContentIsRedacted() throws {
        // Given a room summary that contains sensitive information
        let roomName = "Private Conversation"
        let lastMessage = "Secret information"
        let roomSummary = RoomSummaryDetails(id: "myroomid",
                                             name: roomName,
                                             isDirect: true,
                                             avatarURL: nil,
                                             lastMessage: AttributedString(lastMessage),
                                             lastMessageFormattedTimestamp: "Now",
                                             unreadNotificationCount: 0,
                                             canonicalAlias: nil)
        
        // When logging that value
        XCTAssert(MXLogger.logFiles.isEmpty)
        
        MXLog.configure(redirectToFiles: true)
        
        MXLog.info(roomSummary)
        
        // Then the log file should not include the sensitive information
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        let content = try String(contentsOf: logFile)
        XCTAssertTrue(content.contains(roomSummary.id))
        XCTAssertFalse(content.contains(roomName))
        XCTAssertFalse(content.contains(lastMessage))
    }
    
    // swiftlint:disable:next function_body_length
    func testTimelineContentIsRedacted() throws {
        // Given timeline items that contain text
        let textAttributedString = "TextAttributed"
        let textMessage = TextRoomTimelineItem(id: "mytextmessage",
                                               timestamp: "",
                                               isOutgoing: false,
                                               isEditable: false,
                                               sender: .init(id: "sender"),
                                               content: .init(body: "TextString", formattedBody: AttributedString(textAttributedString)))
        let noticeAttributedString = "NoticeAttributed"
        let noticeMessage = NoticeRoomTimelineItem(id: "mynoticemessage",
                                                   timestamp: "",
                                                   isOutgoing: false,
                                                   isEditable: false,
                                                   sender: .init(id: "sender"),
                                                   content: .init(body: "NoticeString", formattedBody: AttributedString(noticeAttributedString)))
        let emoteAttributedString = "EmoteAttributed"
        let emoteMessage = EmoteRoomTimelineItem(id: "myemotemessage",
                                                 timestamp: "",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "sender"),
                                                 content: .init(body: "EmoteString", formattedBody: AttributedString(emoteAttributedString)))
        let imageMessage = ImageRoomTimelineItem(id: "myimagemessage",
                                                 timestamp: "",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "sender"),
                                                 content: .init(body: "ImageString", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/gif"), thumbnailSource: nil))
        let videoMessage = VideoRoomTimelineItem(id: "myvideomessage",
                                                 timestamp: "",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "sender"),
                                                 content: .init(body: "VideoString", duration: 0, source: nil, thumbnailSource: nil))
        let fileMessage = FileRoomTimelineItem(id: "myfilemessage",
                                               timestamp: "",
                                               isOutgoing: false,
                                               isEditable: false,
                                               sender: .init(id: "sender"),
                                               content: .init(body: "FileString", source: nil, thumbnailSource: nil, contentType: nil))
        
        // When logging that value
        XCTAssert(MXLogger.logFiles.isEmpty)
        
        MXLog.configure(redirectToFiles: true)
        
        MXLog.info(textMessage)
        MXLog.info(noticeMessage)
        MXLog.info(emoteMessage)
        MXLog.info(imageMessage)
        MXLog.info(videoMessage)
        MXLog.info(fileMessage)
        
        // Then the log file should not include the text content
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOf: logFile)
        XCTAssertTrue(content.contains(textMessage.id))
        XCTAssertFalse(content.contains(textMessage.body))
        XCTAssertFalse(content.contains(textAttributedString))
        
        XCTAssertTrue(content.contains(noticeMessage.id))
        XCTAssertFalse(content.contains(noticeMessage.body))
        XCTAssertFalse(content.contains(noticeAttributedString))
        
        XCTAssertTrue(content.contains(emoteMessage.id))
        XCTAssertFalse(content.contains(emoteMessage.body))
        XCTAssertFalse(content.contains(emoteAttributedString))
        
        XCTAssertTrue(content.contains(imageMessage.id))
        XCTAssertFalse(content.contains(imageMessage.body))
        
        XCTAssertTrue(content.contains(videoMessage.id))
        XCTAssertFalse(content.contains(videoMessage.body))
        
        XCTAssertTrue(content.contains(fileMessage.id))
        XCTAssertFalse(content.contains(fileMessage.body))
    }
    
    func testRustMessageContentIsRedacted() throws {
        // Given message content that contain text
        let textString = "TextString"
        let textMessage = TextMessageContent(body: "",
                                             formatted: FormattedBody(format: .html, body: "<b>\(textString)</b>"))
        let noticeString = "NoticeString"
        let noticeMessage = NoticeMessageContent(body: noticeString,
                                                 formatted: FormattedBody(format: .html, body: "<b>\(noticeString)</b>"))
        let emoteString = "EmoteString"
        let emoteMessage = EmoteMessageContent(body: emoteString,
                                               formatted: FormattedBody(format: .html, body: "<b>\(emoteString)</b>"))
        
        let pointer = Unmanaged.passRetained(NSURL(fileURLWithPath: "/tmp/file")).toOpaque()
        let imageMessage = ImageMessageContent(body: "ImageString", source: MediaSource(unsafeFromRawPointer: pointer), info: nil)
        let videoMessage = VideoMessageContent(body: "VideoString", source: MediaSource(unsafeFromRawPointer: pointer), info: nil)
        let fileMessage = FileMessageContent(body: "FileString", source: MediaSource(unsafeFromRawPointer: pointer), info: nil)
        
        // When logging that value
        XCTAssert(MXLogger.logFiles.isEmpty)
        
        MXLog.configure(redirectToFiles: true)
        
        MXLog.info(textMessage)
        MXLog.info(noticeMessage)
        MXLog.info(emoteMessage)
        MXLog.info(imageMessage)
        MXLog.info(videoMessage)
        MXLog.info(fileMessage)
        
        // Then the log file should not include the text content
        guard let logFile = MXLogger.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOf: logFile)
        XCTAssertTrue(content.contains(String(describing: TextMessageContent.self)))
        XCTAssertFalse(content.contains(textString))
        
        XCTAssertTrue(content.contains(String(describing: NoticeMessageContent.self)))
        XCTAssertFalse(content.contains(noticeString))
        
        XCTAssertTrue(content.contains(String(describing: EmoteMessageContent.self)))
        XCTAssertFalse(content.contains(emoteString))
        
        XCTAssertTrue(content.contains(String(describing: ImageMessageContent.self)))
        XCTAssertFalse(content.contains(imageMessage.body))
        
        XCTAssertTrue(content.contains(String(describing: VideoMessageContent.self)))
        XCTAssertFalse(content.contains(videoMessage.body))
        
        XCTAssertTrue(content.contains(String(describing: FileMessageContent.self)))
        XCTAssertFalse(content.contains(fileMessage.body))
    }
}
