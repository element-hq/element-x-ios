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
    let timelineItems: [RoomTimelineItem] = [RoomTimelineItem.text(id: UUID().uuidString, senderDisplayName: "Anne", text: "You rock!", originServerTs: .now, shouldShowSenderDetails: true),
                                             RoomTimelineItem.text(id: UUID().uuidString, senderDisplayName: "Anne", text: "Some other message from Anne", originServerTs: .now, shouldShowSenderDetails: false),
                                             RoomTimelineItem.sectionTitle(id: UUID().uuidString, text: "The next day"),
                                             RoomTimelineItem.text(id: UUID().uuidString, senderDisplayName: "Bob", text: "You rule!", originServerTs: .now, shouldShowSenderDetails: true)]
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    func paginateBackwards(_ count: UInt) {
        
    }
}
