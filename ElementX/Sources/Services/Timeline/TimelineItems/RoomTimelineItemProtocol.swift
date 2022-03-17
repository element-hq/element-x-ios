//
//  RoomTimelineItemProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 16/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

protocol RoomTimelineItemProtocol {
    var id: String { get }
}

protocol BaseRoomTimelineItemProtocol: RoomTimelineItemProtocol {
    var text: String { get }
    var timestamp: String { get }
    var shouldShowSenderDetails: Bool { get }
    
    var sender: String { get }
    var senderAvatar: UIImage? { get set }
}
