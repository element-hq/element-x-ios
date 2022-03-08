//
//  RoomTimelineController.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine
import MatrixRustSDK

enum RoomTimelineControllerCallback {
    case updatedTimelineItems
}

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let timelineProvider: RoomTimelineProvider
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()
    
    init(timelineProvider: RoomTimelineProvider) {
        self.timelineProvider = timelineProvider
        
        self.timelineProvider.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .updatedMessages:
                self.timelineItems = self.timelineProvider.messages.map { message in
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(message.originServerTs()))
                    return TextRoomTimelineItem(id: message.id(),
                                                senderDisplayName: message.sender(),
                                                text: message.content(),
                                                originServerTs: timestamp)
                }
                self.callbacks.send(.updatedTimelineItems)
            }
        }.store(in: &cancellables)
    }
    
    func paginateBackwards(_ count: UInt) {
        timelineProvider.paginateBackwards(count)
    }
}
