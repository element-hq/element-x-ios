//
//  TextRoomTimelineItem.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

struct TextRoomTimelineItem: EventBasedTimelineItemProtocol, Identifiable, Equatable {
    let id: String
    let body: String
    var htmlBody: String?
    let timestamp: String
    let shouldShowSenderDetails: Bool
    
    let senderId: String
    var senderDisplayName: String?
    var senderAvatar: UIImage?
}
