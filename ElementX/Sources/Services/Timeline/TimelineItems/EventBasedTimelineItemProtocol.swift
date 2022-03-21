//
//  EventBasedTimelineItemProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 18/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import UIKit

protocol EventBasedTimelineItemProtocol: RoomTimelineItemProtocol {
    var text: String { get }
    var timestamp: String { get }
    var shouldShowSenderDetails: Bool { get }
    
    var senderId: String { get }
    var senderDisplayName: String? { get set }
    var senderAvatar: UIImage? { get set }
}
