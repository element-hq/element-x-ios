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
            case .addedMessage:
                self.rebuildTimeline()
            }
        }.store(in: &cancellables)
    }
    
    func paginateBackwards(_ count: UInt, callback: @escaping ((Result<Void, RoomTimelineControllerError>) -> Void)) {
        timelineProvider.paginateBackwards(count) { [weak self] result in
            switch result {
            case .success:
                callback(.success(()))
                self?.rebuildTimeline()
            case .failure:
                callback(.failure(.generic))
            }
        }
    }
    
    // MARK: - Private
    
    private func rebuildTimeline() {
        var newTimelineItems = [RoomTimelineViewProvider]()
        
        var previousMessage: RoomMessageProtocol?
        for message in self.timelineProvider.messages {
            let areMessagesFromTheSameDay = self.haveSameDay(lhs: previousMessage, rhs: message)
            let shouldAddSectionHeader = !areMessagesFromTheSameDay
            
            if shouldAddSectionHeader {
                let item = SeparatorRoomTimelineItem(id: message.originServerTs.ISO8601Format(),
                                                     text: message.originServerTs.formatted(date: .long, time: .omitted))
                
                newTimelineItems.append(RoomTimelineViewProvider.separator(item))
            }
            
            let areMessagesFromTheSameSender = (previousMessage?.sender == message.sender)
            let shouldShowSenderDetails = !areMessagesFromTheSameSender || !areMessagesFromTheSameDay
            
            let item = TextRoomTimelineItem(id: message.id,
                                            senderDisplayName: message.sender,
                                            text: message.content,
                                            timestamp: message.originServerTs.formatted(date: .omitted, time: .shortened),
                                            shouldShowSenderDetails: shouldShowSenderDetails)
            
            newTimelineItems.append(RoomTimelineViewProvider.text(item))
            
            previousMessage = message
        }
        
        self.timelineItems = newTimelineItems
        
        self.callbacks.send(.updatedTimelineItems)
    }
    
    private func haveSameDay(lhs: RoomMessageProtocol?, rhs: RoomMessageProtocol?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else {
            return false
        }
        
        return Calendar.current.isDate(lhs.originServerTs, inSameDayAs: rhs.originServerTs)
    }
}
