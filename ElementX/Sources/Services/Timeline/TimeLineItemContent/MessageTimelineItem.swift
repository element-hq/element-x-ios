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

import CoreGraphics
import Foundation
import MatrixRustSDK

/// A protocol that contains the base `m.room.message` event content properties.
protocol MessageContentProtocol: RoomMessageEventContentProtocol {
    var body: String { get }
}

/// The delivery status for the item.
enum MessageTimelineItemDeliveryStatus: Equatable {
    case unknown
    case sending
    case sent(elapsedTime: TimeInterval)
}

/// A timeline item that represents an `m.room.message` event.
struct MessageTimelineItem<Content: MessageContentProtocol> {
    let item: MatrixRustSDK.EventTimelineItem
    let content: Content

    var id: String {
        #warning("Handle txid properly")
        switch item.key() {
        case .transactionId(let txnID):
            return txnID
        case .eventId(let eventID):
            return eventID
        }
    }
    
    var deliveryStatus: MessageTimelineItemDeliveryStatus {
        switch item.key() {
        case .transactionId:
            return .sending
        case .eventId:
            return .sent(elapsedTime: Date().timeIntervalSince1970 - originServerTs.timeIntervalSince1970)
        }
    }

    var body: String {
        content.body
    }
    
    var isEdited: Bool {
        item.content().asMessage()?.isEdited() == true
    }

    var isEditable: Bool {
        item.isEditable()
    }
    
    var inReplyTo: String? {
        item.content().asMessage()?.inReplyTo()
    }
    
    var reactions: [Reaction] {
        item.reactions()
    }

    var sender: String {
        item.sender()
    }

    var originServerTs: Date {
        if let timestamp = item.originServerTs() {
            return Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        } else {
            return .now
        }
    }
}

// MARK: - Formatted Text

/// A protocol that contains the expected event content properties for a formatted message.
protocol FormattedMessageContentProtocol: MessageContentProtocol {
    var formatted: FormattedBody? { get }
}

extension MatrixRustSDK.TextMessageContent: FormattedMessageContentProtocol { }
extension MatrixRustSDK.EmoteMessageContent: FormattedMessageContentProtocol { }
extension MatrixRustSDK.NoticeMessageContent: FormattedMessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event where
/// the `msgtype` would likely contain a formatted body.
extension MessageTimelineItem where Content: FormattedMessageContentProtocol {
    var htmlBody: String? {
        guard content.formatted?.format == .html else { return nil }
        return content.formatted?.body
    }
}

// MARK: - Media

extension MatrixRustSDK.ImageMessageContent: MessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event with a `msgtype` of `m.image`.
extension MessageTimelineItem where Content == MatrixRustSDK.ImageMessageContent {
    var source: MediaSourceProxy {
        .init(source: content.source)
    }

    var width: CGFloat? {
        content.info?.width.map(CGFloat.init)
    }

    var height: CGFloat? {
        content.info?.height.map(CGFloat.init)
    }

    var blurhash: String? {
        content.info?.blurhash
    }
}

extension MatrixRustSDK.VideoMessageContent: MessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event with a `msgtype` of `m.video`.
extension MessageTimelineItem where Content == MatrixRustSDK.VideoMessageContent {
    var source: MediaSourceProxy {
        .init(source: content.source)
    }

    var thumbnailSource: MediaSourceProxy? {
        guard let src = content.info?.thumbnailSource else {
            return nil
        }
        return .init(source: src)
    }

    var duration: UInt64 {
        content.info?.duration ?? 0
    }

    var width: CGFloat? {
        content.info?.width.map(CGFloat.init)
    }

    var height: CGFloat? {
        content.info?.height.map(CGFloat.init)
    }

    var blurhash: String? {
        content.info?.blurhash
    }
}

extension MatrixRustSDK.FileMessageContent: MessageContentProtocol { }

/// A timeline item that represents an `m.room.message` event with a `msgtype` of `m.file`.
extension MessageTimelineItem where Content == MatrixRustSDK.FileMessageContent {
    var source: MediaSourceProxy {
        .init(source: content.source)
    }

    var thumbnailSource: MediaSourceProxy? {
        guard let src = content.info?.thumbnailSource else {
            return nil
        }
        return .init(source: src)
    }
}
