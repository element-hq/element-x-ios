//
//  MockRoomTimelineController.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

class MockRoomTimelineController: RoomTimelineControllerProtocol {
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    var timelineItems: [RoomTimelineItemProtocol] = [SeparatorRoomTimelineItem(id: UUID().uuidString, text: "Yesterday"),
                                                     TextRoomTimelineItem(id: UUID().uuidString, text: "You rock!", timestamp: "10:10 AM", shouldShowSenderDetails: true, senderId: "Alice"),
                                                     TextRoomTimelineItem(id: UUID().uuidString, text: "You also rule!", timestamp: "10:11 AM", shouldShowSenderDetails: false, senderId: "Alice"),
                                                     SeparatorRoomTimelineItem(id: UUID().uuidString, text: "Today"),
                                                     TextRoomTimelineItem(id: UUID().uuidString, text: "You too!", timestamp: "5 PM", shouldShowSenderDetails: true, senderId: "Bob")]
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError> {
        return .failure(.generic)
    }
    
    func processItemAppearance(_ itemId: String) async {
        
    }
    
    func processItemDisappearance(_ itemId: String) async {
        
    }
    
    func sendMessage(_ message: String) async {
        
    }
}
