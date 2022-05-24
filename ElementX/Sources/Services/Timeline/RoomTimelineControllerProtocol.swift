//
//  RoomTimelineControllerProtocol.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

enum RoomTimelineControllerCallback {
    case updatedTimelineItems
    case updatedTimelineItem(_ itemId: String)
}

enum RoomTimelineControllerError: Error {
    case generic
}

protocol RoomTimelineControllerProtocol {
    var timelineItems: [RoomTimelineItemProtocol] { get }
    var callbacks: PassthroughSubject<RoomTimelineControllerCallback, Never> { get }
    
    func processItemAppearance(_ itemId: String) async
    
    func processItemDisappearance(_ itemId: String) async
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError>
    
    func sendMessage(_ message: String) async
}
