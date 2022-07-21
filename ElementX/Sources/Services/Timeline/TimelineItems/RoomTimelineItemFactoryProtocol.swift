//
//  RoomTimelineItemFactoryProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 26/05/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

@MainActor
protocol RoomTimelineItemFactoryProtocol {
    func buildTimelineItemFor(message: RoomMessageProtocol, isOutgoing: Bool, showSenderDetails: Bool) async -> RoomTimelineItemProtocol
}
