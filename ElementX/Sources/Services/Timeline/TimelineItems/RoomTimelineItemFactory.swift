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
    private let memberDetailsProvider: MemberDetailsProvider
    
    init(mediaProvider: MediaProviderProtocol,
         memberDetailsProvider: MemberDetailsProvider) {
        self.mediaProvider = mediaProvider
        self.memberDetailsProvider = memberDetailsProvider
    }
    
    func buildTimelineItemFor(_ roomMessage: RoomMessageProtocol, showSenderDetails: Bool) -> RoomTimelineItemProtocol {
        
        let avatarURL = memberDetailsProvider.avatarURLForUserId(roomMessage.sender)
        let avatarImage = mediaProvider.imageForURL(avatarURL)
        
        switch roomMessage {
        case let message as TextRoomMessage:
            return TextRoomTimelineItem(id: message.id,
                                        text: message.content,
                                        timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                        shouldShowSenderDetails: showSenderDetails,
                                        sender: message.sender,
                                        senderAvatar: avatarImage)
        case let message as ImageRoomMessage:
            return ImageRoomTimelineItem(id: message.id,
                                         text: message.content,
                                         timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                         shouldShowSenderDetails: showSenderDetails,
                                         sender: message.sender,
                                         senderAvatar: avatarImage,
                                         url: message.url,
                                         image: mediaProvider.imageForURL(message.url))
        default:
            fatalError("Unknown room message.")
        }
    }
}
