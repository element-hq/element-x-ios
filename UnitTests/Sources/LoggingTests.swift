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
        RustTracing.deleteLogFiles()
    }
    
    // swiftlint:disable:next function_body_length
    func testLogging() async throws {
        let target = "tests"
        XCTAssertTrue(RustTracing.logFiles.isEmpty)

        // MARK: - File logging
        
        let infoLog = UUID().uuidString

        MXLog.configure(target: target, logLevel: .info)
        
        MXLog.info(infoLog)
        
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        try XCTAssertTrue(String(contentsOf: logFile).contains(infoLog))
        
        // MARK: - Log levels
        
        let verboseLog = UUID().uuidString
        
        MXLog.verbose(verboseLog)
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }
        
        try XCTAssertFalse(String(contentsOf: logFile).contains(verboseLog))
        
        // MARK: - Target name
        
        MXLog.info(UUID().uuidString)
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        XCTAssertTrue(logFile.lastPathComponent.contains(target))
        
        // MARK: - Room summary content is redacted
        
        // Given a room summary that contains sensitive information
        let roomName = "Private Conversation"
        let lastMessage = "Secret information"
        let roomSummary = RoomSummaryDetails(id: "myroomid",
                                             name: roomName,
                                             isDirect: true,
                                             avatarURL: nil,
                                             lastMessage: AttributedString(lastMessage),
                                             lastMessageFormattedTimestamp: "Now",
                                             unreadMessagesCount: 0,
                                             unreadMentionsCount: 0,
                                             unreadNotificationsCount: 0,
                                             notificationMode: nil,
                                             canonicalAlias: nil,
                                             inviter: nil,
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
        
        let roomSummaryContent = try String(contentsOf: logFile)
        XCTAssertTrue(roomSummaryContent.contains(roomSummary.id))
        XCTAssertFalse(roomSummaryContent.contains(roomName))
        XCTAssertFalse(roomSummaryContent.contains(lastMessage))
        
        // MARK: - Timeline content is redacted
        
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

        let timelineContent = try String(contentsOf: logFile)
        XCTAssertTrue(timelineContent.contains(textMessage.id.timelineID))
        XCTAssertFalse(timelineContent.contains(textMessage.body))
        XCTAssertFalse(timelineContent.contains(textAttributedString))
        
        XCTAssertTrue(timelineContent.contains(noticeMessage.id.timelineID))
        XCTAssertFalse(timelineContent.contains(noticeMessage.body))
        XCTAssertFalse(timelineContent.contains(noticeAttributedString))
        
        XCTAssertTrue(timelineContent.contains(emoteMessage.id.timelineID))
        XCTAssertFalse(timelineContent.contains(emoteMessage.body))
        XCTAssertFalse(timelineContent.contains(emoteAttributedString))
        
        XCTAssertTrue(timelineContent.contains(imageMessage.id.timelineID))
        XCTAssertFalse(timelineContent.contains(imageMessage.body))
        
        XCTAssertTrue(timelineContent.contains(videoMessage.id.timelineID))
        XCTAssertFalse(timelineContent.contains(videoMessage.body))
        
        XCTAssertTrue(timelineContent.contains(fileMessage.id.timelineID))
        XCTAssertFalse(timelineContent.contains(fileMessage.body))
        
        // MARK: - Rust message content is redacted
        
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
        
        let pointer = Unmanaged.passRetained(NSURL(fileURLWithPath: "/tmp/file")).toOpaque()
        let rustImageMessage = ImageMessageContent(body: "ImageString", source: MediaSource(unsafeFromRawPointer: pointer), info: nil)
        let rustVideoMessage = VideoMessageContent(body: "VideoString", source: MediaSource(unsafeFromRawPointer: pointer), info: nil)
        let rustFileMessage = FileMessageContent(body: "FileString", filename: "FileName", source: MediaSource(unsafeFromRawPointer: pointer), info: nil)
        
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

        let rustContent = try String(contentsOf: logFile)
        XCTAssertTrue(rustContent.contains(String(describing: TextMessageContent.self)))
        XCTAssertFalse(rustContent.contains(textString))
        
        XCTAssertTrue(rustContent.contains(String(describing: NoticeMessageContent.self)))
        XCTAssertFalse(rustContent.contains(noticeString))
        
        XCTAssertTrue(rustContent.contains(String(describing: EmoteMessageContent.self)))
        XCTAssertFalse(rustContent.contains(emoteString))
        
        XCTAssertTrue(rustContent.contains(String(describing: ImageMessageContent.self)))
        XCTAssertFalse(rustContent.contains(rustImageMessage.body))
        
        XCTAssertTrue(rustContent.contains(String(describing: VideoMessageContent.self)))
        XCTAssertFalse(rustContent.contains(rustVideoMessage.body))
        
        XCTAssertTrue(rustContent.contains(String(describing: FileMessageContent.self)))
        XCTAssertFalse(rustContent.contains(rustFileMessage.body))
    }
    
    func disabled_testLogFileSorting() async throws {
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
        guard let newLineData = "newline".data(using: .utf8) else {
            XCTFail("Couldn't create data to write to disk.")
            return
        }
        
        try fileHandle.write(contentsOf: newLineData)
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
