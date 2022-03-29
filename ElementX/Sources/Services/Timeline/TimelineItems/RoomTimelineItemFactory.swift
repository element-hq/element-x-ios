//
//  TimelineItemFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

struct RoomTimelineItemFactory {
    private let mediaProvider: MediaProviderProtocol
    private let memberDetailsProvider: MemberDetailsProviderProtocol
    private let attributedStringBuilder: AttributedStringBuilderProtocol
    
    init(mediaProvider: MediaProviderProtocol,
         memberDetailsProvider: MemberDetailsProviderProtocol,
         attributedStringBuilder: AttributedStringBuilderProtocol) {
        self.mediaProvider = mediaProvider
        self.memberDetailsProvider = memberDetailsProvider
        self.attributedStringBuilder = attributedStringBuilder
    }
    
    func buildTimelineItemFor(_ roomMessage: RoomMessageProtocol, showSenderDetails: Bool) -> RoomTimelineItemProtocol {
        let displayName = memberDetailsProvider.displayNameForUserId(roomMessage.sender)
        let avatarURL = memberDetailsProvider.avatarURLForUserId(roomMessage.sender)
        let avatarImage = mediaProvider.imageForURL(avatarURL)
        
        switch roomMessage {
        case let message as TextRoomMessage:
            return buildTextTimelineItemFromMessage(message, showSenderDetails, displayName, avatarImage)
        case let message as ImageRoomMessage:
            return buildImageTimelineItemFromMessage(message, showSenderDetails, displayName, avatarImage)
        case let message as NoticeRoomMessage:
            return buildNoticeTimelineItemFromMessage(message, showSenderDetails, displayName, avatarImage)
        case let message as EmoteRoomMessage:
            return buildEmoteTimelineItemFromMessage(message, showSenderDetails, displayName, avatarImage)
        default:
            fatalError("Unknown room message.")
        }
    }
    
    // MARK: - Private
    private func buildTextTimelineItemFromMessage(_ message: TextRoomMessage,
                                                  _ showSenderDetails: Bool,
                                                  _ displayName: String?,
                                                  _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        let attributedText = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return TextRoomTimelineItem(id: message.id,
                                    text: message.body,
                                    attributedComponents: attributedComponents,
                                    timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                    shouldShowSenderDetails: showSenderDetails,
                                    senderId: message.sender,
                                    senderDisplayName: displayName,
                                    senderAvatar: avatarImage)
    }
    
    private func buildImageTimelineItemFromMessage(_ message: ImageRoomMessage,
                                                   _ showSenderDetails: Bool,
                                                   _ displayName: String?,
                                                   _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        return ImageRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                     shouldShowSenderDetails: showSenderDetails,
                                     senderId: message.sender,
                                     senderDisplayName: displayName,
                                     senderAvatar: avatarImage,
                                     url: message.url,
                                     image: mediaProvider.imageForURL(message.url))
    }
    
    private func buildNoticeTimelineItemFromMessage(_ message: NoticeRoomMessage,
                                                    _ showSenderDetails: Bool,
                                                    _ displayName: String?,
                                                    _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        let attributedText = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return NoticeRoomTimelineItem(id: message.id,
                                      text: message.body,
                                      attributedComponents: attributedComponents,
                                      timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                      shouldShowSenderDetails: showSenderDetails,
                                      senderId: message.sender,
                                      senderDisplayName: displayName,
                                      senderAvatar: avatarImage)
    }
    
    private func buildEmoteTimelineItemFromMessage(_ message: EmoteRoomMessage,
                                                   _ showSenderDetails: Bool,
                                                   _ displayName: String?,
                                                   _ avatarImage: UIImage?) -> RoomTimelineItemProtocol {
        let attributedText = (message.htmlBody != nil ? attributedStringBuilder.fromHTML(message.htmlBody) : attributedStringBuilder.fromPlain(message.body))
        let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
        
        return EmoteRoomTimelineItem(id: message.id,
                                     text: message.body,
                                     attributedComponents: attributedComponents,
                                     timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                     shouldShowSenderDetails: showSenderDetails,
                                     senderId: message.sender,
                                     senderDisplayName: displayName,
                                     senderAvatar: avatarImage)
    }
}
