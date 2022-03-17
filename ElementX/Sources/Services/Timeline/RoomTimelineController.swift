//
//  RoomTimelineController.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let timelineProvider: RoomTimelineProvider
    private let timelineItemFactory: RoomTimelineItemFactory
    private let mediaProvider: MediaProviderProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()
    
    init(timelineProvider: RoomTimelineProvider,
         timelineItemFactory: RoomTimelineItemFactory,
         mediaProvider: MediaProviderProtocol) {
        self.timelineProvider = timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
        
        self.timelineProvider.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .addedMessage:
                self.updateTimelineItems()
            }
        }.store(in: &cancellables)
    }
    
    func paginateBackwards(_ count: UInt, callback: @escaping ((Result<Void, RoomTimelineControllerError>) -> Void)) {
        timelineProvider.paginateBackwards(count) { [weak self] result in
            switch result {
            case .success:
                callback(.success(()))
                self?.updateTimelineItems()
            case .failure:
                callback(.failure(.generic))
            }
        }
    }
    
    func processItemAppearance(_ itemId: String) {
        guard let timelineItem = self.timelineItems.filter({ $0.id == itemId}).first else {
            return
        }
        
        loadAvatarIfNeededForTimelineItem(timelineItem)
        
        switch timelineItem {
        case var item as ImageRoomTimelineItem:
            if item.image != nil {
                return
            }
            
            guard let url = item.url else {
                return
            }
            
            mediaProvider.loadImageFromURL(url) { [weak self] result in
                guard let self = self else {
                    return
                }
                
                if case let .success(image) = result {
                    guard let index = self.timelineItems.firstIndex(where: { $0.id == itemId }) else {
                        return
                    }
                    
                    item.image = image
                    self.timelineItems[index] = item
                    self.callbacks.send(.updatedTimelineItem(itemId))
                }
            }
        default:
            break
        }
    }
    
    func processItemDisappearance(_ itemId: String) {
        
    }
    
    // MARK: - Private
    
    private func updateTimelineItems() {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        
        var previousMessage: RoomMessageProtocol?
        for message in self.timelineProvider.messages {
            let areMessagesFromTheSameDay = self.haveSameDay(lhs: previousMessage, rhs: message)
            let shouldAddSectionHeader = !areMessagesFromTheSameDay
            
            if shouldAddSectionHeader {
                newTimelineItems.append(SeparatorRoomTimelineItem(id: message.originServerTs.ISO8601Format(),
                                                                  text: message.originServerTs.formatted(date: .long, time: .omitted)))
            }
            
            let areMessagesFromTheSameSender = (previousMessage?.sender == message.sender)
            let shouldShowSenderDetails = !areMessagesFromTheSameSender || !areMessagesFromTheSameDay
            
            newTimelineItems.append(timelineItemFactory.buildTimelineItemFor(message, showSenderDetails: shouldShowSenderDetails))
            
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
    
    private func loadAvatarIfNeededForTimelineItem(_ timelineItem: RoomTimelineItemProtocol) {
        switch timelineItem {
        case var item as BaseRoomTimelineItemProtocol:
            if item.shouldShowSenderDetails == false {
                break
            }
            
            timelineProvider.avatarURLForUserId(item.sender) { [weak self] result in
                guard let self = self else {
                    return
                }
                
                switch result {
                case .success(let userAvatarURL):
                    guard let avatarURL = userAvatarURL else {
                        return
                    }
                    
                    self.mediaProvider.loadImageFromURL(avatarURL) { result in
                        if case let .success(image) = result {
                            guard let index = self.timelineItems.firstIndex(where: { $0.id == timelineItem.id }) else {
                                return
                            }
                            
                            item.senderAvatar = image
                            self.timelineItems[index] = item
                            self.callbacks.send(.updatedTimelineItem(timelineItem.id))
                        }
                    }
                case .failure:
                    MXLog.error("Failed retrieving user avatar")
                }
            }
            
        default:
            break
        }
    }
}
