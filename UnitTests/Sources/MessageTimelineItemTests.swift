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

@testable import ElementX
import MatrixRustSDK
import XCTest

// swiftlint:disable force_unwrapping
class MessageTimelineItemTests: XCTestCase {
    // MARK: Image
    
    func testImageContentType() {
        let mimetype = "image/gif"
        let imageContent = ImageMessageContent(body: "amazing.gif",
                                               source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                               info: makeImageInfo(mimetype: mimetype))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertEqual(messageItem.contentType, .gif)
    }
    
    func testImageContentTypeWithoutMimetype() {
        let imageContent = ImageMessageContent(body: "amazing.jpeg",
                                               source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                               info: makeImageInfo(mimetype: nil))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertEqual(messageItem.contentType, .jpeg)
    }
    
    func makeImageInfo(mimetype: String?) -> ImageInfo {
        ImageInfo(height: nil,
                  width: nil,
                  mimetype: mimetype,
                  size: nil,
                  thumbnailInfo: nil,
                  thumbnailSource: nil,
                  blurhash: nil)
    }
    
    // MARK: Video
    
    func testVideoContentType() {
        let mimetype = "video/x-msvideo"
        let imageContent = VideoMessageContent(body: "amazing.avi",
                                               source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                               info: makeVideoInfo(mimetype: mimetype))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertEqual(messageItem.contentType, .avi)
    }
    
    func testVideoContentTypeWithoutMimetype() {
        let imageContent = VideoMessageContent(body: "amazing.mp4",
                                               source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                               info: makeVideoInfo(mimetype: nil))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertEqual(messageItem.contentType, .mpeg4Movie)
    }
    
    func makeVideoInfo(mimetype: String?) -> VideoInfo {
        VideoInfo(duration: nil,
                  height: nil,
                  width: nil,
                  mimetype: mimetype,
                  size: nil,
                  thumbnailInfo: nil,
                  thumbnailSource: nil,
                  blurhash: nil)
    }
    
    // MARK: Audio
    
    func testAudioContentType() {
        let mimetype = "audio/mp3"
        let imageContent = AudioMessageContent(body: "amazing.mp3",
                                               source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                               info: makeAudioInfo(mimetype: mimetype))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertEqual(messageItem.contentType, .mp3)
    }
    
    func testAudioContentTypeWithoutMimetype() {
        let imageContent = AudioMessageContent(body: "amazing.m4a",
                                               source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                               info: makeAudioInfo(mimetype: nil))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertTrue(messageItem.contentType!.conforms(to: .mpeg4Audio))
    }
    
    func makeAudioInfo(mimetype: String?) -> AudioInfo {
        AudioInfo(duration: nil, size: nil, mimetype: mimetype)
    }
    
    // MARK: File
    
    func testFileContentType() {
        let mimetype = "text"
        let imageContent = FileMessageContent(body: "amazing.txt",
                                              source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                              info: makeFileInfo(mimetype: mimetype))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertEqual(messageItem.contentType, .plainText)
    }
    
    func testFileContentTypeWithoutMimetype() {
        let imageContent = FileMessageContent(body: "amazing.rtf",
                                              source: mediaSourceFromUrl(url: "mxc://doesnt/matter"),
                                              info: makeFileInfo(mimetype: nil))
        let messageItem = makeMessageTimelineItem(content: imageContent)
        XCTAssertEqual(messageItem.contentType, .rtf)
    }
    
    func makeFileInfo(mimetype: String?) -> FileInfo {
        FileInfo(mimetype: mimetype, size: nil, thumbnailInfo: nil, thumbnailSource: nil)
    }
    
    // MARK: - Helpers
    
    func makeMessageTimelineItem<Content: MessageContentProtocol>(content: Content) -> MessageTimelineItem<Content> {
        let item = MockEventTimelineItem(underlyingContent: content)
        return MessageTimelineItem(item: item, content: content)
    }
}

// swiftlint:disable force_cast
struct MockEventTimelineItem: EventTimelineItemProtocol {
    let underlyingContent: MessageContentProtocol
    
    func content() -> MatrixRustSDK.TimelineItemContent { underlyingContent as! TimelineItemContent }
    
    func eventId() -> String? { UUID().uuidString }
    
    func fmtDebug() -> String { "MockEvent" }
    
    func isEditable() -> Bool { false }
    
    func isLocal() -> Bool { false }
    
    func isOwn() -> Bool { false }
    
    func isRemote() -> Bool { true }
    
    func localSendState() -> MatrixRustSDK.EventSendState? { nil }
    
    func raw() -> String? { nil }
    
    func reactions() -> [MatrixRustSDK.Reaction]? { nil }
    
    func sender() -> String { "@user:server.com" }
    
    func senderProfile() -> MatrixRustSDK.ProfileTimelineDetails { .unavailable }
    
    func timestamp() -> UInt64 { 0 }
    
    func uniqueIdentifier() -> String { eventId() ?? "" }
}
