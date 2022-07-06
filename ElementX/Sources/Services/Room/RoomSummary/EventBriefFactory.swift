//
//  EventBriefFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct EventBriefFactory: EventBriefFactoryProtocol {
    private let memberDetailProvider: MemberDetailProviderProtocol
    
    init(memberDetailProvider: MemberDetailProviderProtocol) {
        self.memberDetailProvider = memberDetailProvider
    }
    
    func buildEventBriefFor(message: RoomMessageProtocol?) async -> EventBrief? {
        guard let message = message else {
            return nil
        }
        
        switch message {
        case is ImageRoomMessage:
            return nil
        case let message as TextRoomMessage:
            return await buildEventBrief(message: message, htmlBody: message.htmlBody)
        case let message as NoticeRoomMessage:
            return await buildEventBrief(message: message, htmlBody: message.htmlBody)
        case let message as EmoteRoomMessage:
            return await buildEventBrief(message: message, htmlBody: message.htmlBody)
        default:
            fatalError("Unknown room message.")
        }
    }
    
    // MARK: - Private
    
    private func buildEventBrief(message: RoomMessageProtocol, htmlBody: String?) async -> EventBrief? {
        switch await memberDetailProvider.loadDisplayNameForUserId(message.sender) {
        case .success(let displayName):
            return EventBrief(eventId: message.id,
                              senderId: message.sender,
                              senderDisplayName: displayName,
                              body: message.body,
                              htmlBody: htmlBody,
                              date: message.originServerTs)
        case .failure(let error):
            MXLog.error("Failed fetching sender display name with error: \(error)")
            
            return EventBrief(eventId: message.id,
                              senderId: message.sender,
                              senderDisplayName: nil,
                              body: message.body,
                              htmlBody: htmlBody,
                              date: message.originServerTs)
        }
    }
}
