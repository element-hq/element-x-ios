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
    let tempDir = URL.temporaryDirectory.appending(path: "Logs")
    
    private enum Constants {
        static let genericFailure = "Test failed"
    }

    override func setUpWithError() throws {
        RustTracing.deleteLogFiles()
    }

    func disabled_testFileLogging() async throws {
        XCTAssertTrue(RustTracing.logFiles.isEmpty)

        let log = UUID().uuidString

        MXLog.configure(logLevel: .info)
        
        MXLog.info(log)
        
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOf: logFile)
        XCTAssert(content.contains(log))
    }

    func disabled_testLogLevels() throws {
        XCTAssert(RustTracing.logFiles.isEmpty)

        let log = UUID().uuidString

        MXLog.configure(logLevel: .info)
        
        MXLog.verbose(log)
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        let content = try String(contentsOf: logFile)
        XCTAssertFalse(content.contains(log))
    }

    func disabled_testSubLogName() {
        XCTAssert(RustTracing.logFiles.isEmpty)

        let target = "nse"

        MXLog.configure(target: target, logLevel: .info)
        
        MXLog.info(UUID().uuidString)
        guard let logFile = RustTracing.logFiles.first else {
            XCTFail(Constants.genericFailure)
            return
        }

        XCTAssertTrue(logFile.lastPathComponent.contains(target))
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
    
    func disabled_testRoomSummaryContentIsRedacted() throws {
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
        XCTAssert(RustTracing.logFiles.isEmpty)
        
        MXLog.configure(logLevel: .info)
        
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
    }
    
    func disabled_testTimelineContentIsRedacted() throws {
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
        XCTAssert(RustTracing.logFiles.isEmpty)
        
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
    
    func disabled_testRustMessageContentIsRedacted() throws {
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
        let fileMessage = FileMessageContent(body: "FileString", filename: "FileName", source: MediaSource(unsafeFromRawPointer: pointer), info: nil)
        
        // When logging that value
        XCTAssert(RustTracing.logFiles.isEmpty)
        
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
