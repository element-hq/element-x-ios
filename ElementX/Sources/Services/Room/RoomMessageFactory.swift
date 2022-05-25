//
//  RoomMessageFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK

struct RoomMessageFactory: RoomMessageFactoryProtocol {
    func buildRoomMessageFrom(_ message: AnyMessage) -> RoomMessageProtocol {
        if let textMessage = message.textMessage() {
            return TextRoomMessage(message: textMessage)
        } else if let imageMessage = message.imageMessage() {
            return ImageRoomMessage(message: imageMessage)
        } else if let noticeMessage = message.noticeMessage() {
            return NoticeRoomMessage(message: noticeMessage)
        } else if let emoteMessage = message.emoteMessage() {
            return EmoteRoomMessage(message: emoteMessage)
        } else {
            fatalError("One of these must exist")
        }
    }
}
