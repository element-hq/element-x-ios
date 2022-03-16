//
//  TextRoomMessage.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit
import MatrixRustSDK

struct TextRoomMessage: RoomMessageProtocol {
    private let message: MatrixRustSDK.TextMessage
    
    init(message: MatrixRustSDK.TextMessage) {
        self.message = message
    }
    
    var id: String {
        message.baseMessage().id()
    }
    
    var content: String {
        message.baseMessage().content()
    }
    
    var sender: String {
        message.baseMessage().sender()
    }
    
    var originServerTs: Date {
        Date(timeIntervalSince1970: TimeInterval(message.baseMessage().originServerTs()))
    }
}
