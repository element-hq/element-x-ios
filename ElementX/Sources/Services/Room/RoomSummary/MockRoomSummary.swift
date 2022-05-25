//
//  MockRoomSummary.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import UIKit
import Combine

struct MockRoomSummary: RoomSummaryProtocol {
    var id: String = UUID().uuidString
    
    var name: String?
    
    var topic: String?
    
    var isDirect: Bool = false
    
    var isEncrypted: Bool = false
    
    var isSpace: Bool = false
    
    var isTombstoned: Bool = false
    
    var displayName: String?
    
    var lastMessage: EventBrief?
    
    var avatar: UIImage?
    
    func loadDetails() async {
        
    }
    
    var callbacks = PassthroughSubject<RoomSummaryCallback, Never>()
}
