//
//  EmoteRoomMessage.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK
import UIKit

struct EmoteRoomMessage: RoomMessageProtocol {
    private let message: MatrixRustSDK.EmoteMessage
    
    init(message: MatrixRustSDK.EmoteMessage) {
        self.message = message
    }
    
    var id: String {
        message.baseMessage().id()
    }
    
    var body: String {
        message.baseMessage().body()
    }
    
    var htmlBody: String? {
        message.htmlBody()
    }
    
    var sender: String {
        message.baseMessage().sender()
    }
    
    var originServerTs: Date {
        Date(timeIntervalSince1970: TimeInterval(message.baseMessage().originServerTs()))
    }
}
