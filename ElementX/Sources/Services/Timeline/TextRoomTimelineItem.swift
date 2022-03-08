//
//  TextRoomTimelineItem.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

struct TextRoomTimelineItem: RoomTimelineItemProtocol {
    let id: String
    let senderDisplayName: String
    let text: String
    let originServerTs: Date
}
