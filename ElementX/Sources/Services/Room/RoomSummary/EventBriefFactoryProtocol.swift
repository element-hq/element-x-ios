//
//  EventBriefFactoryProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 01/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

@MainActor
protocol EventBriefFactoryProtocol {
    func eventBriefForMessage(_ message: RoomMessageProtocol?) async -> EventBrief?
}
