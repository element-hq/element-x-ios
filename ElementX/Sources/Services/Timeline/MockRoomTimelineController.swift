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
    
    var timelineItems: [RoomTimelineViewProvider] = [RoomTimelineViewProvider.separator(.init(id: UUID().uuidString, text: "Yesterday")),
                                                     RoomTimelineViewProvider.text(.init(id: UUID().uuidString, senderDisplayName: "Alice", text: "You rock!", timestamp: "10:10 AM", shouldShowSenderDetails: true)),
                                                     RoomTimelineViewProvider.text(.init(id: UUID().uuidString, senderDisplayName: "Alice", text: "You also rule!", timestamp: "10:11 AM", shouldShowSenderDetails: false)),
                                                     RoomTimelineViewProvider.separator(.init(id: UUID().uuidString, text: "Today")),
                                                     RoomTimelineViewProvider.text(.init(id: UUID().uuidString, senderDisplayName: "Bob", text: "You too!", timestamp: "5 PM", shouldShowSenderDetails: true))]
    
    func paginateBackwards(_ count: UInt, callback: ((Result<Void, RoomTimelineControllerError>) -> Void)) {
        callbacks.send(.updatedTimelineItems)
    }
}
