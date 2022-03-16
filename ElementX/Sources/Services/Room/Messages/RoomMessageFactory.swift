//
//  RoomMessageFactory.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK

struct RoomMessageFactory {
    func buildRoomMessageFrom(_ message: AnyMessage) -> RoomMessageProtocol {
        if let textMessage = message.text() {
            return TextRoomMessage(message: textMessage)
        } else if let imageMessage = message.image() {
            return ImageRoomMessage(message: imageMessage)
        } else {
            fatalError("One of these must exist")
        }
    }
}
