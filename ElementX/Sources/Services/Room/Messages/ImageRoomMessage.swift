//
//  ImageRoomMessage.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import MatrixRustSDK
import UIKit

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
    
    var source: MediaSource? {
        MediaSource(source: message.source())
    }
    
    var width: CGFloat? {
        guard let width = message.width() else {
            return nil
        }
        
        return CGFloat(width)
    }
    
    var height: CGFloat? {
        guard let height = message.height() else {
            return nil
        }
        
        return CGFloat(height)
    }
    
    var blurhash: String? {
        message.blurhash()
    }
}
