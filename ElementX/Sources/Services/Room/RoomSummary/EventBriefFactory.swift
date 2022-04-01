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
    
    func eventBriefForMessage(_ message: RoomMessageProtocol?, completion: @escaping ((EventBrief?) -> Void)) {
        guard let message = message else {
            completion(nil)
            return
        }
        
        switch message {
        case is ImageRoomMessage:
            completion(nil)
        case let message as TextRoomMessage:
            buildEventBrief(message: message, htmlBody: message.htmlBody, completion: completion)
        case let message as NoticeRoomMessage:
            buildEventBrief(message: message, htmlBody: message.htmlBody, completion: completion)
        case let message as EmoteRoomMessage:
            buildEventBrief(message: message, htmlBody: message.htmlBody, completion: completion)
        default:
            fatalError("Unknown room message.")
        }
    }
    
    // MARK: - Private
    
    private func buildEventBrief(message: RoomMessageProtocol, htmlBody: String?, completion: @escaping ((EventBrief?) -> Void)) {
        memberDetailProvider.displayNameForUserId(message.sender) { result in
            switch result {
            case .success(let displayName):
                completion(EventBrief(eventId: message.id,
                                      senderId: message.sender,
                                      senderDisplayName: displayName,
                                      body: message.body,
                                      htmlBody: htmlBody,
                                      date: message.originServerTs))
            case .failure(let error):
                MXLog.error("Failed fetching sender display name with error: \(error)")
                
                completion(EventBrief(eventId: message.id,
                                      senderId: message.sender,
                                      senderDisplayName: nil,
                                      body: message.body,
                                      htmlBody: htmlBody,
                                      date: message.originServerTs))
            }
        }
    }
}
