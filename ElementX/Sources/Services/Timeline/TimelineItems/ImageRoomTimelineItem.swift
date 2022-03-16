//
//  ImageRoomTimelineItem.swift
//  ElementX
//
//  Created by Stefan Ceriu on 11/03/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct ImageRoomTimelineItem: TimelineItemProtocol, Identifiable, Equatable {
    let id: String
    let senderDisplayName: String
    let text: String
    let timestamp: String
    let shouldShowSenderDetails: Bool
}
