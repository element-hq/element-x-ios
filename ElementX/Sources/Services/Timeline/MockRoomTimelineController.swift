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
    let timelineItems: [RoomTimelineItemProtocol] = [TextRoomTimelineItem(id: UUID().uuidString, senderDisplayName: "Anne", text: "You rock!", originServerTs: .now),
                                                     TextRoomTimelineItem(id: UUID().uuidString, senderDisplayName: "Bob", text: "You rule!", originServerTs: .now)]
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    func paginateBackwards(_ count: UInt) {
        
    }
}
