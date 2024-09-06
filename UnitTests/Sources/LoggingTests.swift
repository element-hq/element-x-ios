//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
@testable import MatrixRustSDK
import XCTest

class LoggingTests: XCTestCase {
    private enum Constants {
        static let genericFailure = "Test failed"
    }

    override func setUpWithError() throws {
        RustTracing.deleteLogFiles()
    }
    
    func testLogging() async throws {
        let target = "tests"
        XCTAssertTrue(RustTracing.logFiles.isEmpty)
        
        MXLog.configure(target: target, logLevel: .info)
        
        // There is something weird with Rust logging where the file writing handle doesn't
        // notice that the file it is writing to was deleted, so we can't run these checks
        // as separate tests. So instead we need to make sure we run all the tests that
        // write logs in this single test case after configuring the log system.
        
        try validateFileLogging()
        try validateLogLevels()
        try validateTargetName(target)
        
        try validateRoomSummaryContentIsRedacted()
        try validateTimelineContentIsRedacted()
        try validateRustMessageContentIsRedacted()
    }
    
    func validateFileLogging() throws {
        let infoLog = UUID().uuidString
        
        MXLog.info(infoLog)
        
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        try XCTAssertTrue(String(contentsOf: logFile).contains(infoLog))
    }
        
    func validateLogLevels() throws {
        let verboseLog = UUID().uuidString
        
        MXLog.verbose(verboseLog)
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        try XCTAssertFalse(String(contentsOf: logFile).contains(verboseLog))
    }
        
    func validateTargetName(_ target: String) throws {
        MXLog.info(UUID().uuidString)
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        XCTAssertTrue(logFile.lastPathComponent.contains(target))
    }
    
    func validateRoomSummaryContentIsRedacted() throws {
        // Given a room summary that contains sensitive information
        let roomName = "Private Conversation"
        let lastMessage = "Secret information"
        let heroName = "Pseudonym"
        let roomSummary = RoomSummary(roomListItem: .init(noPointer: .init()),
                                      id: "myroomid",
                                      isInvite: false,
                                      inviter: nil,
                                      name: roomName,
                                      isDirect: true,
                                      avatarURL: nil,
                                      heroes: [.init(userID: "", displayName: heroName)],
                                      lastMessage: AttributedString(lastMessage),
                                      lastMessageFormattedTimestamp: "Now",
                                      unreadMessagesCount: 0,
                                      unreadMentionsCount: 0,
                                      unreadNotificationsCount: 0,
                                      notificationMode: nil,
                                      canonicalAlias: nil,
                                      hasOngoingCall: false,
                                      isMarkedUnread: false,
                                      isFavourite: false)
        
        // When logging that value
        MXLog.info(roomSummary)
        
        // Then the log file should not include the sensitive information
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        let content = try String(contentsOf: logFile)
        XCTAssertTrue(content.contains(roomSummary.id))
        XCTAssertFalse(content.contains(roomName))
        XCTAssertFalse(content.contains(lastMessage))
        XCTAssertFalse(content.contains(heroName))
    }
        
    func validateTimelineContentIsRedacted() throws {
        // Given timeline items that contain text
        let textAttributedString = "TextAttributed"
        let textMessage = TextRoomTimelineItem(id: .random,
                                               timestamp: "",
                                               isOutgoing: false,
                                               isEditable: false,
                                               canBeRepliedTo: true,
                                               isThreaded: false,
                                               sender: .init(id: "sender"),
                                               content: .init(body: "TextString", formattedBody: AttributedString(textAttributedString)))
        let noticeAttributedString = "NoticeAttributed"
        let noticeMessage = NoticeRoomTimelineItem(id: .random,
                                                   timestamp: "",
                                                   isOutgoing: false,
                                                   isEditable: false,
                                                   canBeRepliedTo: true,
                                                   isThreaded: false,
                                                   sender: .init(id: "sender"),
                                                   content: .init(body: "NoticeString", formattedBody: AttributedString(noticeAttributedString)))
        let emoteAttributedString = "EmoteAttributed"
        let emoteMessage = EmoteRoomTimelineItem(id: .random,
                                                 timestamp: "",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 canBeRepliedTo: true,
                                                 isThreaded: false,
                                                 sender: .init(id: "sender"),
                                                 content: .init(body: "EmoteString", formattedBody: AttributedString(emoteAttributedString)))
        let imageMessage = ImageRoomTimelineItem(id: .init(timelineID: "myimagemessage"),
                                                 timestamp: "",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 canBeRepliedTo: true,
                                                 isThreaded: false,
                                                 sender: .init(id: "sender"),
                                                 content: .init(body: "ImageString", source: MediaSourceProxy(url: .picturesDirectory, mimeType: "image/gif"), thumbnailSource: nil))
        let videoMessage = VideoRoomTimelineItem(id: .random,
                                                 timestamp: "",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 canBeRepliedTo: true,
                                                 isThreaded: false,
                                                 sender: .init(id: "sender"),
                                                 content: .init(body: "VideoString", duration: 0, source: nil, thumbnailSource: nil))
        let fileMessage = FileRoomTimelineItem(id: .random,
                                               timestamp: "",
                                               isOutgoing: false,
                                               isEditable: false,
                                               canBeRepliedTo: true,
                                               isThreaded: false,
                                               sender: .init(id: "sender"),
                                               content: .init(body: "FileString", source: nil, thumbnailSource: nil, contentType: nil))
        
        // When logging that value
        MXLog.configure(logLevel: .info)
        
        MXLog.info(textMessage)
        MXLog.info(noticeMessage)
        MXLog.info(emoteMessage)
        MXLog.info(imageMessage)
        MXLog.info(videoMessage)
        MXLog.info(fileMessage)
        
        // Then the log file should not include the text content
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        let content = try String(contentsOf: logFile)
        XCTAssertTrue(content.contains(textMessage.id.timelineID))
        XCTAssertFalse(content.contains(textMessage.body))
        XCTAssertFalse(content.contains(textAttributedString))
        
        XCTAssertTrue(content.contains(noticeMessage.id.timelineID))
        XCTAssertFalse(content.contains(noticeMessage.body))
        XCTAssertFalse(content.contains(noticeAttributedString))
        
        XCTAssertTrue(content.contains(emoteMessage.id.timelineID))
        XCTAssertFalse(content.contains(emoteMessage.body))
        XCTAssertFalse(content.contains(emoteAttributedString))
        
        XCTAssertTrue(content.contains(imageMessage.id.timelineID))
        XCTAssertFalse(content.contains(imageMessage.body))
        
        XCTAssertTrue(content.contains(videoMessage.id.timelineID))
        XCTAssertFalse(content.contains(videoMessage.body))
        
        XCTAssertTrue(content.contains(fileMessage.id.timelineID))
        XCTAssertFalse(content.contains(fileMessage.body))
    }
        
    func validateRustMessageContentIsRedacted() throws {
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
        
        let rustImageMessage = ImageMessageContent(body: "ImageString", formatted: nil, filename: nil, source: MediaSource(noPointer: .init()), info: nil)
        let rustVideoMessage = VideoMessageContent(body: "VideoString", formatted: nil, filename: nil, source: MediaSource(noPointer: .init()), info: nil)
        let rustFileMessage = FileMessageContent(body: "FileString", formatted: nil, filename: "FileName", source: MediaSource(noPointer: .init()), info: nil)
        
        // When logging that value
        MXLog.info(rustTextMessage)
        MXLog.info(rustNoticeMessage)
        MXLog.info(rustEmoteMessage)
        MXLog.info(rustImageMessage)
        MXLog.info(rustVideoMessage)
        MXLog.info(rustFileMessage)
        
        // Then the log file should not include the text content
        guard let logFile = RustTracing.logFiles.first else {
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
        XCTAssertFalse(content.contains(rustImageMessage.body))
        
        XCTAssertTrue(content.contains(String(describing: VideoMessageContent.self)))
        XCTAssertFalse(content.contains(rustVideoMessage.body))
        
        XCTAssertTrue(content.contains(String(describing: FileMessageContent.self)))
        XCTAssertFalse(content.contains(rustFileMessage.body))
    }
    
    func testLogFileSorting() async throws {
        // Given a collection of log files.
        XCTAssertTrue(RustTracing.logFiles.isEmpty)
        
        // When creating new logs.
        let logsFileDirectory = RustTracing.logsDirectory
        for i in 1...5 {
            let filename = "console.\(i).log"
            try "console".write(to: logsFileDirectory.appending(path: filename), atomically: true, encoding: .utf8)
        }
        
        for i in 1...5 {
            let nseFilename = "console-nse.\(i).log"
            try "nse".write(to: logsFileDirectory.appending(path: nseFilename), atomically: true, encoding: .utf8)
        }
        
        // Then the logs should be sorted chronologically (newest first) and not alphabetically.
        XCTAssertEqual(RustTracing.logFiles.map(\.lastPathComponent),
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
        XCTAssertEqual(RustTracing.logFiles.map(\.lastPathComponent),
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
}
