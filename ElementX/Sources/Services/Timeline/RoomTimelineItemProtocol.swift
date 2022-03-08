//
//  RoomTimelineItemProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

protocol RoomTimelineItemProtocol {
    var id: String { get }
    var senderDisplayName: String { get }
    var text: String { get }
    var originServerTs: Date { get }
}
