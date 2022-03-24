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
            let attributedText = attributedStringBuilder.fromHTML(message.htmlBody ?? message.body)
            let attributedComponents = attributedStringBuilder.blockquoteCoalescedComponentsFrom(attributedText)
            
            return TextRoomTimelineItem(id: message.id,
                                        text: message.body,
                                        attributedComponents: attributedComponents,
                                        timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                        shouldShowSenderDetails: showSenderDetails,
                                        senderId: message.sender,
                                        senderDisplayName: displayName,
                                        senderAvatar: avatarImage)
        case let message as ImageRoomMessage:
            return ImageRoomTimelineItem(id: message.id,
                                         text: message.body,
                                         timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                         shouldShowSenderDetails: showSenderDetails,
                                         senderId: message.sender,
                                         senderDisplayName: displayName,
                                         senderAvatar: avatarImage,
                                         url: message.url,
                                         image: mediaProvider.imageForURL(message.url))
        default:
            fatalError("Unknown room message.")
        }
    }
}
