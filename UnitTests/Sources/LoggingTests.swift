//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
@testable import MatrixRustSDK
import XCTest

class LoggingTests: XCTestCase {
    private enum Constants {
        static let genericFailure = "Test failed"
    }
    
    override func tearDown() async throws {
        Tracing.logsDirectoryOverride = nil
        try reloadTracingFileWriter(configuration: .init(path: URL.appGroupLogsDirectory.path(percentEncoded: false),
                                                         filePrefix: "console-tests",
                                                         fileSuffix: "log",
                                                         maxFiles: 100))
    }
    
    func testFileLogging() throws {
        try setupTest()
        
        let infoLog = UUID().uuidString
        MXLog.info(infoLog)
        
        guard let logFile = Tracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        try XCTAssertTrue(String(contentsOf: logFile).contains(infoLog))
    }
        
    func testLogLevels() throws {
        try setupTest()
        
        let verboseLog = UUID().uuidString
        MXLog.verbose(verboseLog)
        
        guard let logFile = Tracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        try XCTAssertFalse(String(contentsOf: logFile).contains(verboseLog))
    }
    
    /// This is meant to test the `Target.tests.configure(…)`, but at this stage the test is somewhat pointless
    /// as it is unlikely to have been called before `tearDown` has manually set the file prefix 😕.
    func testTargetName() throws {
        MXLog.info(UUID().uuidString)
        guard let logFile = Tracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        let target = "tests"
        XCTAssertTrue(logFile.lastPathComponent.contains(target))
    }
    
    func testRoomSummaryContentIsRedacted() throws {
        try setupTest()
        
        // Given a room summary that contains sensitive information
        let roomName = "Private Conversation"
        let lastMessage = "Secret information"
        let heroName = "Pseudonym"
        let roomSummary = RoomSummary(room: .init(noPointer: .init()),
                                      id: "myroomid",
                                      joinRequestType: nil,
                                      name: roomName,
                                      isDirect: true,
                                      avatarURL: nil,
                                      heroes: [.init(userID: "", displayName: heroName)],
                                      activeMembersCount: 0,
                                      lastMessage: AttributedString(lastMessage),
                                      lastMessageDate: .mock,
                                      unreadMessagesCount: 0,
                                      unreadMentionsCount: 0,
                                      unreadNotificationsCount: 0,
                                      notificationMode: nil,
                                      canonicalAlias: nil,
                                      alternativeAliases: [],
                                      hasOngoingCall: false,
                                      isMarkedUnread: false,
                                      isFavourite: false,
                                      isTombstoned: false)
        
        // When logging that value
        MXLog.info(roomSummary)
        
        // Then the log file should not include the sensitive information
        guard let logFile = Tracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        let content = try String(contentsOf: logFile)
        XCTAssertTrue(content.contains(roomSummary.id))
        XCTAssertFalse(content.contains(roomName))
        XCTAssertFalse(content.contains(lastMessage))
        XCTAssertFalse(content.contains(heroName))
    }
        
    func testTimelineContentIsRedacted() async throws {
        try setupTest()
        
        // Given timeline items that contain text
        let textAttributedString = "TextAttributed"
        let textMessage = TextRoomTimelineItem(id: .randomEvent,
                                               timestamp: .mock,
                                               isOutgoing: false,
                                               isEditable: false,
                                               canBeRepliedTo: true,
                                               sender: .init(id: "sender"),
                                               content: .init(body: "TextString", formattedBody: AttributedString(textAttributedString)))
        let noticeAttributedString = "NoticeAttributed"
        let noticeMessage = NoticeRoomTimelineItem(id: .randomEvent,
                                                   timestamp: .mock,
                                                   isOutgoing: false,
                                                   isEditable: false,
                                                   canBeRepliedTo: true,
                                                   sender: .init(id: "sender"),
                                                   content: .init(body: "NoticeString", formattedBody: AttributedString(noticeAttributedString)))
        let emoteAttributedString = "EmoteAttributed"
        let emoteMessage = EmoteRoomTimelineItem(id: .randomEvent,
                                                 timestamp: .mock,
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 canBeRepliedTo: true,
                                                 sender: .init(id: "sender"),
                                                 content: .init(body: "EmoteString", formattedBody: AttributedString(emoteAttributedString)))
        let imageMessage = ImageRoomTimelineItem(id: .randomEvent,
                                                 timestamp: .mock,
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 canBeRepliedTo: true,
                                                 sender: .init(id: "sender"),
                                                 content: .init(filename: "ImageString",
                                                                caption: "ImageString",
                                                                imageInfo: .mockImage,
                                                                thumbnailInfo: nil))
        let videoMessage = VideoRoomTimelineItem(id: .randomEvent,
                                                 timestamp: .mock,
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 canBeRepliedTo: true,
                                                 sender: .init(id: "sender"),
                                                 content: .init(filename: "VideoString",
                                                                caption: "VideoString",
                                                                videoInfo: .mockVideo,
                                                                thumbnailInfo: nil))
        let fileMessage = FileRoomTimelineItem(id: .randomEvent,
                                               timestamp: .mock,
                                               isOutgoing: false,
                                               isEditable: false,
                                               canBeRepliedTo: true,
                                               sender: .init(id: "sender"),
                                               content: .init(filename: "FileString",
                                                              caption: "FileString",
                                                              source: nil,
                                                              fileSize: nil,
                                                              thumbnailSource: nil,
                                                              contentType: nil))
        
        // When logging that value
        MXLog.info(textMessage)
        MXLog.info(noticeMessage)
        MXLog.info(emoteMessage)
        MXLog.info(imageMessage)
        MXLog.info(videoMessage)
        MXLog.info(fileMessage)
        
        // Then the log file should not include the text content
        guard let logFile = Tracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        let content = try String(contentsOf: logFile)
        XCTAssertTrue(content.contains(textMessage.id.uniqueID.value))
        XCTAssertFalse(content.contains(textMessage.body))
        XCTAssertFalse(content.contains(textAttributedString))
        
        XCTAssertTrue(content.contains(noticeMessage.id.uniqueID.value))
        XCTAssertFalse(content.contains(noticeMessage.body))
        XCTAssertFalse(content.contains(noticeAttributedString))
        
        XCTAssertTrue(content.contains(emoteMessage.id.uniqueID.value))
        XCTAssertFalse(content.contains(emoteMessage.body))
        XCTAssertFalse(content.contains(emoteAttributedString))
        
        XCTAssertTrue(content.contains(imageMessage.id.uniqueID.value))
        XCTAssertFalse(content.contains(imageMessage.body))
        
        XCTAssertTrue(content.contains(videoMessage.id.uniqueID.value))
        XCTAssertFalse(content.contains(videoMessage.body))
        
        XCTAssertTrue(content.contains(fileMessage.id.uniqueID.value))
        XCTAssertFalse(content.contains(fileMessage.body))
    }
        
    func testRustMessageContentIsRedacted() throws {
        try setupTest()
        
        // Given message content that contain text
        let textString = "TextString"
        let rustTextMessage = TextMessageContent(body: "",
                                                 formatted: FormattedBody(format: .html, body: "<b>\(textString)</b>"))
        let noticeString = "NoticeString"
        let rustNoticeMessage = NoticeMessageContent(body: noticeString,
                                                     formatted: FormattedBody(format: .html, body: "<b>\(noticeString)</b>"))
        let emoteString = "EmoteString"
        let rustEmoteMessage = EmoteMessageContent(body: emoteString,
                                                   formatted: FormattedBody(format: .html, body: "<b>\(emoteString)</b>"))
        
        let rustImageMessage = ImageMessageContent(filename: "ImageString",
                                                   caption: "ImageString",
                                                   formattedCaption: nil,
                                                   source: MediaSource(noPointer: .init()),
                                                   info: nil)
        
        let rustVideoMessage = VideoMessageContent(filename: "VideoString",
                                                   caption: "VideoString",
                                                   formattedCaption: nil,
                                                   source: MediaSource(noPointer: .init()),
                                                   info: nil)
        
        let rustFileMessage = FileMessageContent(filename: "FileString",
                                                 caption: "FileString",
                                                 formattedCaption: nil,
                                                 source: MediaSource(noPointer: .init()),
                                                 info: nil)
        
        // When logging that value
        MXLog.info(rustTextMessage)
        MXLog.info(rustNoticeMessage)
        MXLog.info(rustEmoteMessage)
        MXLog.info(rustImageMessage)
        MXLog.info(rustVideoMessage)
        MXLog.info(rustFileMessage)
        
        // Then the log file should not include the text content
        guard let logFile = Tracing.logFiles.first else {
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
        XCTAssertFalse(content.contains(rustImageMessage.filename))
        
        XCTAssertTrue(content.contains(String(describing: VideoMessageContent.self)))
        XCTAssertFalse(content.contains(rustVideoMessage.filename))
        
        XCTAssertTrue(content.contains(String(describing: FileMessageContent.self)))
        XCTAssertFalse(content.contains(rustFileMessage.filename))
    }
    
    func testLogFileSorting() async throws {
        try setupTest(redirectTracingFileWriter: false)
        
        // Given a collection of log files.
        XCTAssertTrue(Tracing.logFiles.isEmpty)
        
        // When creating new logs.
        let logsFileDirectory = Tracing.logsDirectory
        for i in 1...5 {
            let filename = "console.\(i).log"
            try "console".write(to: logsFileDirectory.appending(path: filename), atomically: true, encoding: .utf8)
        }
        
        for i in 1...5 {
            let nseFilename = "console-nse.\(i).log"
            try "nse".write(to: logsFileDirectory.appending(path: nseFilename), atomically: true, encoding: .utf8)
        }
        
        // Then the logs should be sorted chronologically (newest first) and not alphabetically.
        XCTAssertEqual(Tracing.logFiles.map(\.lastPathComponent),
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
        try fileHandle.write(contentsOf: Data("newline".utf8))
        try fileHandle.close()
        
        // Then that file should now be the first log file.
        XCTAssertEqual(Tracing.logFiles.map(\.lastPathComponent),
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
    
    // MARK: - Helpers
    
    /// There is something weird with Rust logging where the file writing handle won't notice that the file it is writing
    /// to has been deleted. So in order to run the tests that validate the file output, we must use a new directory
    /// to start with a fresh state (as calling ``Tracing.deleteLogFiles`` would trigger the bug).
    private func setupTest(name: String = #function, redirectTracingFileWriter: Bool = true) throws {
        let testDirectory = URL.appGroupLogsDirectory.appending(component: name, directoryHint: .isDirectory)
        Tracing.logsDirectoryOverride = testDirectory
        try? FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        // Make an assertion before redirecting the logs as it the SDK is likely to put an empty file
        // in the directory, ready to be written to.
        XCTAssertTrue(Tracing.logFiles.isEmpty)
        
        if redirectTracingFileWriter {
            try reloadTracingFileWriter(configuration: .init(path: testDirectory.path(percentEncoded: false),
                                                             filePrefix: "console",
                                                             fileSuffix: "log",
                                                             maxFiles: 100))
        }
    }
}
