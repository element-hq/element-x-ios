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

import Foundation
import UIKit

struct RoomTimelineItemFactory: RoomTimelineItemFactoryProtocol {
    private let mediaProvider: MediaProviderProtocol
    private let memberDetailProvider: MemberDetailProviderProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    init(mediaProvider: MediaProviderProtocol,
         memberDetailProvider: MemberDetailProviderProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.mediaProvider = mediaProvider
        self.memberDetailProvider = memberDetailProvider
        self.attributedStringBuilder = attributedStringBuilder
    }
    
    func buildTimelineItemFor(message: RoomMessageProtocol, isOutgoing: Bool, showSenderDetails: Bool) async -> RoomTimelineItemProtocol {
        let displayName = memberDetailProvider.displayNameForUserId(message.sender)
        let avatarURL = memberDetailProvider.avatarURLStringForUserId(message.sender)
        let avatarImage = mediaProvider.imageFromURLString(avatarURL)
        
        switch message {
        case let message as TextRoomMessage:
            return await buildTextTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        case let message as ImageRoomMessage:
            return await buildImageTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        case let message as NoticeRoomMessage:
            return await buildNoticeTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        case let message as EmoteRoomMessage:
            return await buildEmoteTimelineItemFromMessage(message, isOutgoing, showSenderDetails, displayName, avatarImage)
        default:
            fatalError("Unknown room message.")
        }
    }
    
    // MARK: - Private

    private func buildTextTimelineItemFromMessage(_ message: TextRoomMessage,
                                                  _ isOutgoing: Bool,
                                                  _ showSenderDetails: Bool,
                                                  _ displayName: String?,
                                                  _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: message.id,
                                    text: message.body,
                                    attributedComponents: attributedComponents,
                                    timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                    shouldShowSenderDetails: showSenderDetails,
                                    isOutgoing: isOutgoing,
                                    senderId: message.sender,
                                    senderDisplayName: displayName,
                                    senderAvatar: avatarImage,
                                    properties: RoomTimelineItemProperties())
    }
    
    private func buildImageTimelineItemFromMessage(_ message: ImageRoomMessage,
                                                   _ isOutgoing: Bool,
                                                   _ showSenderDetails: Bool,
                                                   _ displayName: String?,
                                                   _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        var aspectRatio: CGFloat?
        if let width = message.width,
           let height = message.height {
            aspectRatio = width / height
        }
        
        return ImageRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                     shouldShowSenderDetails: showSenderDetails,
                                     isOutgoing: isOutgoing,
                                     senderId: message.sender,
                                     senderDisplayName: displayName,
                                     senderAvatar: avatarImage,
                                     source: message.source,
                                     image: mediaProvider.imageFromSource(message.source),
                                     width: message.width,
                                     height: message.height,
                                     aspectRatio: aspectRatio,
                                     blurhash: message.blurhash,
                                     properties: RoomTimelineItemProperties())
    }
    
    private func buildNoticeTimelineItemFromMessage(_ message: NoticeRoomMessage,
                                                    _ isOutgoing: Bool,
                                                    _ showSenderDetails: Bool,
                                                    _ displayName: String?,
                                                    _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return NoticeRoomTimelineItem(id: message.id,
                                      text: message.body,
                                      attributedComponents: attributedComponents,
                                      timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                      shouldShowSenderDetails: showSenderDetails,
                                      isOutgoing: isOutgoing,
                                      senderId: message.sender,
                                      senderDisplayName: displayName,
                                      senderAvatar: avatarImage,
                                      properties: RoomTimelineItemProperties())
    }
    
    private func buildEmoteTimelineItemFromMessage(_ message: EmoteRoomMessage,
                                                   _ isOutgoing: Bool,
                                                   _ showSenderDetails: Bool,
                                                   _ displayName: String?,
                                                   _ avatarImage: UIImage?) async -> RoomTimelineItemProtocol {
        let attributedText = await (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return EmoteRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     attributedComponents: attributedComponents,
                                     timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                     shouldShowSenderDetails: showSenderDetails,
                                     isOutgoing: isOutgoing,
                                     senderId: message.sender,
                                     senderDisplayName: displayName,
                                     senderAvatar: avatarImage,
                                     properties: RoomTimelineItemProperties())
    }
}
