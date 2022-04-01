//
//  EventBriefFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct EventBriefFactory: EventBriefFactoryProtocol {
    
    func eventBriefForMessage(_ message: RoomMessageProtocol?) -> EventBrief? {
        guard let message = message else {
            return nil
        }
        
        switch message {
        case is ImageRoomMessage:
            return nil
        case let message as TextRoomMessage:
            return buildEventBrief(message: message, htmlBody: message.htmlBody)
        case let message as NoticeRoomMessage:
            return buildEventBrief(message: message, htmlBody: message.htmlBody)
        case let message as EmoteRoomMessage:
            return buildEventBrief(message: message, htmlBody: message.htmlBody)
        default:
            fatalError("Unknown room message.")
        }
    }
    
    // MARK: - Private
    
    private func buildEventBrief(message: RoomMessageProtocol, htmlBody: String?) -> EventBrief {
        return EventBrief(id: message.id,
                          senderName: message.sender,
                          body: message.body,
                          htmlBody: htmlBody,
                          date: message.originServerTs)
    }
}
