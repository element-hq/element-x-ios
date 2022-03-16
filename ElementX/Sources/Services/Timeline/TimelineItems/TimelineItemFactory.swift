//
//  TimelineItemFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct TimelineItemFactory {
    func buildTimelineItemFor(_ roomMessage: RoomMessageProtocol, showSenderDetails: Bool) -> TimelineItemProtocol {
        switch roomMessage {
        case let message as TextRoomMessage:
            return TextRoomTimelineItem(id: message.id,
                                        senderDisplayName: message.sender,
                                        text: message.content,
                                        timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                        shouldShowSenderDetails: showSenderDetails)
        case let message as ImageRoomMessage:
            return ImageRoomTimelineItem(id: message.id,
                                         senderDisplayName: message.sender,
                                         text: message.content,
                                         timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                         shouldShowSenderDetails: showSenderDetails)
        default:
            fatalError("Unknown room message.")
        }
    }
}
