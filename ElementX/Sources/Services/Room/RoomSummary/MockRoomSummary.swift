//
//  MockRoomSummary.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import UIKit

struct MockRoomSummary: RoomSummaryProtocol {
    var id: String = UUID().uuidString
    
    var name: String?
    
    var displayName: String?
    
    var topic: String?
    
    var isDirect = false
    
    var isEncrypted = false
    
    var isSpace = false
    
    var isTombstoned = false
    
    var lastMessage: EventBrief?
    
    var avatar: UIImage?
    
    func loadDetails() async { }
    
    var callbacks = PassthroughSubject<RoomSummaryCallback, Never>()
}
