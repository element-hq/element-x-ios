//
//  RoomTimelineController.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import Combine
import UIKit

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactory
    private let mediaProvider: MediaProviderProtocol
    private let memberDetailProvider: MemberDetailProviderProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()
    
    init(timelineProvider: RoomTimelineProviderProtocol,
         timelineItemFactory: RoomTimelineItemFactory,
         mediaProvider: MediaProviderProtocol,
         memberDetailProvider: MemberDetailProviderProtocol) {
        self.timelineProvider = timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
        self.memberDetailProvider = memberDetailProvider
        
        self.timelineProvider.callbacks.sink { [weak self] callback in
            guard let self = self else { return }
            
            switch callback {
            case .updatedMessages:
                self.updateTimelineItems()
            }
        }.store(in: &cancellables)
        
        updateTimelineItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
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
        
        if let item = timelineItem as? EventBasedTimelineItemProtocol {
            loadUserAvatarForTimelineItem(item)
            loadUserDisplayNameForTimelineItem(item)
        }
                
        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            loadImageForTimelineItem(item)
        default:
            break
        }
    }
    
    func processItemDisappearance(_ itemId: String) {
        
    }
    
    // MARK: - Private
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        updateTimelineItems()
    }
    
    private func updateTimelineItems() {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        
        var previousMessage: RoomMessageProtocol?
        for message in self.timelineProvider.messages {
            let areMessagesFromTheSameDay = self.haveSameDay(lhs: previousMessage, rhs: message)
            let shouldAddSectionHeader = !areMessagesFromTheSameDay
            
            if shouldAddSectionHeader {
                newTimelineItems.append(SeparatorRoomTimelineItem(id: message.originServerTs.ISO8601Format(),
                                                                  text: message.originServerTs.formatted(date: .complete, time: .omitted)))
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
    
    private func loadImageForTimelineItem(_ timelineItem: ImageRoomTimelineItem) {
        if timelineItem.image != nil {
            return
        }
        
        guard let source = timelineItem.source else {
            return
        }
        
        mediaProvider.loadImageFromSource(source) { [weak self] result in
            guard let self = self else {
                return
            }
            
            if case let .success(image) = result {
                guard let index = self.timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                      var item = self.timelineItems[index] as? ImageRoomTimelineItem else {
                    return
                }
                
                item.image = image
                self.timelineItems[index] = item
                self.callbacks.send(.updatedTimelineItem(timelineItem.id))
            }
        }
    }
    
    private func loadUserAvatarForTimelineItem(_ timelineItem: EventBasedTimelineItemProtocol) {
        if timelineItem.shouldShowSenderDetails == false {
            return
        }
        
        memberDetailProvider.avatarURLForUserId(timelineItem.senderId) { result in
            if case let .success(avatarURL) = result,
               let avatarURL = avatarURL {
                self.mediaProvider.loadImageFromURL(avatarURL) { result in
                    if case let .success(image) = result {
                        guard let index = self.timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                              var item = self.timelineItems[index] as? EventBasedTimelineItemProtocol else {
                            return
                        }
                        
                        item.senderAvatar = image
                        self.timelineItems[index] = item
                        self.callbacks.send(.updatedTimelineItem(timelineItem.id))
                    }
                }
            }
        }
    }
    
    private func loadUserDisplayNameForTimelineItem(_ timelineItem: EventBasedTimelineItemProtocol) {
        if timelineItem.shouldShowSenderDetails == false {
            return
        }
        
        memberDetailProvider.displayNameForUserId(timelineItem.senderId) { result in
            if case let .success(displayName) = result,
               let displayName = displayName {
                guard let index = self.timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                      var item = self.timelineItems[index] as? EventBasedTimelineItemProtocol else {
                          return
                      }
                
                item.senderDisplayName = displayName
                self.timelineItems[index] = item
                self.callbacks.send(.updatedTimelineItem(timelineItem.id))
            }
        }
    }
}
