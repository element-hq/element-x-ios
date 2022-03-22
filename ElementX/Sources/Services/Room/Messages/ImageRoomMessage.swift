//
//  ImageRoomMessage.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import MatrixRustSDK

struct ImageRoomMessage: RoomMessageProtocol {
    private let message: MatrixRustSDK.ImageMessage
    
    init(message: MatrixRustSDK.ImageMessage) {
        self.message = message
    }
    
    var id: String {
        message.baseMessage().id()
    }
    
    var body: String {
        message.baseMessage().body()
    }
    
    var sender: String {
        message.baseMessage().sender()
    }
    
    var originServerTs: Date {
        Date(timeIntervalSince1970: TimeInterval(message.baseMessage().originServerTs()))
    }
    
    var url: String? {
        message.url()
    }
}
