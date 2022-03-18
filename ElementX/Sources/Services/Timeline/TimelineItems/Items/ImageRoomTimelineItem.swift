//
//  ImageRoomTimelineItem.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

struct ImageRoomTimelineItem: EventBasedTimelineItemProtocol, Identifiable, Equatable {
    let id: String
    let text: String
    let timestamp: String
    let shouldShowSenderDetails: Bool
    
    let sender: String
    var senderAvatar: UIImage?
    
    let url: String?
    var image: UIImage?
}
