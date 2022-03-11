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
    
    private(set) var timelineItems = [RoomTimelineViewProvider]()
    
    init(timelineProvider: RoomTimelineProvider) {
        self.timelineProvider = timelineProvider
        
        self.timelineProvider.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .updatedMessages:
                var newTimelineItems = [RoomTimelineViewProvider]()
                
                var previousMessage: Message?
                for message in self.timelineProvider.messages {
                    let timestamp = Date(timeIntervalSince1970: TimeInterval(message.originServerTs()))
                    
                    let areMessagesFromTheSameDay = self.haveSameDay(lhs: previousMessage, rhs: message)
                    let shouldAddSectionHeader = !areMessagesFromTheSameDay
                    
                    if shouldAddSectionHeader {
                        let item = SeparatorRoomTimelineItem(id: timestamp.ISO8601Format(),
                                                             text: timestamp.formatted(date: .long, time: .omitted))
                        
                        newTimelineItems.append(RoomTimelineViewProvider.separator(item))
                    }
                    
                    let areMessagesFromTheSameSender = (previousMessage?.sender() == message.sender())
                    let shouldShowSenderDetails = !areMessagesFromTheSameSender || !areMessagesFromTheSameDay
                    
                    let item = TextRoomTimelineItem(id: message.id(),
                                                    senderDisplayName: message.sender(),
                                                    text: message.content(),
                                                    timestamp: timestamp.formatted(date: .omitted, time: .shortened),
                                                    shouldShowSenderDetails: shouldShowSenderDetails)
                    
                    newTimelineItems.append(RoomTimelineViewProvider.text(item))
                    
                    previousMessage = message
                }
                
                self.timelineItems = newTimelineItems
                
                self.callbacks.send(.updatedTimelineItems)
            }
        }.store(in: &cancellables)
    }
    
    func paginateBackwards(_ count: UInt) {
        timelineProvider.paginateBackwards(count)
    }
    
    // MARK: - Private
    
    private func haveSameDay(lhs: Message?, rhs: Message?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else {
            return false
        }
        
        let lhsTimestamp = Date(timeIntervalSince1970: TimeInterval(lhs.originServerTs()))
        let rhsTimestamp = Date(timeIntervalSince1970: TimeInterval(rhs.originServerTs()))
        
        return Calendar.current.isDate(lhsTimestamp, inSameDayAs: rhsTimestamp)
        
    }
}
