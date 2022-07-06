//
//  RoomTimelineController.swift
//  ElementX
//
//  Created by Stefan Ceriu on 04.03.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Combine
import Foundation
import UIKit

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let userId: String
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let mediaProvider: MediaProviderProtocol
    private let memberDetailProvider: MemberDetailProviderProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()
    
    init(userId: String,
         timelineProvider: RoomTimelineProviderProtocol,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         mediaProvider: MediaProviderProtocol,
         memberDetailProvider: MemberDetailProviderProtocol) {
        self.userId = userId
        self.timelineProvider = timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
        self.memberDetailProvider = memberDetailProvider
        
        self.timelineProvider
            .callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self = self else { return }
                
                switch callback {
                case .updatedMessages:
                    self.updateTimelineItems()
                }
            }.store(in: &cancellables)
        
        updateTimelineItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError> {
        switch await timelineProvider.paginateBackwards(count) {
        case .success:
            updateTimelineItems()
            return .success(())
        case .failure:
            return .failure(.generic)
        }
    }
    
    func processItemAppearance(_ itemId: String) async {
        guard let timelineItem = timelineItems.first(where: { $0.id == itemId }) else {
            return
        }
        
        if let item = timelineItem as? EventBasedTimelineItemProtocol {
            await loadUserAvatarForTimelineItem(item)
            await loadUserDisplayNameForTimelineItem(item)
        }
                
        switch timelineItem {
        case let item as ImageRoomTimelineItem:
            await loadImageForTimelineItem(item)
        default:
            break
        }
    }
    
    func processItemDisappearance(_ itemId: String) { }
    
    func sendMessage(_ message: String) async {
        switch await timelineProvider.sendMessage(message) {
        default:
            break
        }
    }
    
    // MARK: - Private
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        updateTimelineItems()
    }
    
    private func updateTimelineItems() {
        var newTimelineItems = [RoomTimelineItemProtocol]()
        
        var previousMessage: RoomMessageProtocol?
        for message in timelineProvider.messages {
            let areMessagesFromTheSameDay = haveSameDay(lhs: previousMessage, rhs: message)
            let shouldAddSectionHeader = !areMessagesFromTheSameDay
            
            if shouldAddSectionHeader {
                newTimelineItems.append(SeparatorRoomTimelineItem(id: message.originServerTs.ISO8601Format(),
                                                                  text: message.originServerTs.formatted(date: .complete, time: .omitted)))
            }
            
            let areMessagesFromTheSameSender = (previousMessage?.sender == message.sender)
            let shouldShowSenderDetails = !areMessagesFromTheSameSender || !areMessagesFromTheSameDay
            
            newTimelineItems.append(timelineItemFactory.buildTimelineItemFor(message: message,
                                                                             isOutgoing: message.sender == userId,
                                                                             showSenderDetails: shouldShowSenderDetails))
            
            previousMessage = message
        }
        
        timelineItems = newTimelineItems
        
        callbacks.send(.updatedTimelineItems)
    }
    
    private func haveSameDay(lhs: RoomMessageProtocol?, rhs: RoomMessageProtocol?) -> Bool {
        guard let lhs = lhs, let rhs = rhs else {
            return false
        }
        
        return Calendar.current.isDate(lhs.originServerTs, inSameDayAs: rhs.originServerTs)
    }
    
    private func loadImageForTimelineItem(_ timelineItem: ImageRoomTimelineItem) async {
        if timelineItem.image != nil {
            return
        }
        
        guard let source = timelineItem.source else {
            return
        }
        
        switch await mediaProvider.loadImageFromSource(source) {
        case .success(let image):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? ImageRoomTimelineItem else {
                return
            }
            
            item.image = image
            timelineItems[index] = item
            callbacks.send(.updatedTimelineItem(timelineItem.id))
        case .failure:
            break
        }
    }
    
    private func loadUserAvatarForTimelineItem(_ timelineItem: EventBasedTimelineItemProtocol) async {
        if timelineItem.shouldShowSenderDetails == false {
            return
        }
        
        switch await memberDetailProvider.loadAvatarURLStringForUserId(timelineItem.senderId) {
        case .success(let avatarURLString):
            guard let avatarURLString = avatarURLString else {
                return
            }
            
            switch await mediaProvider.loadImageFromURLString(avatarURLString) {
            case .success(let avatar):
                guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                      var item = timelineItems[index] as? EventBasedTimelineItemProtocol else {
                    return
                }
                
                item.senderAvatar = avatar
                timelineItems[index] = item
                callbacks.send(.updatedTimelineItem(timelineItem.id))
            case .failure:
                break
            }
            
        case .failure:
            break
        }
    }
    
    private func loadUserDisplayNameForTimelineItem(_ timelineItem: EventBasedTimelineItemProtocol) async {
        if timelineItem.shouldShowSenderDetails == false {
            return
        }
        
        switch await memberDetailProvider.loadDisplayNameForUserId(timelineItem.senderId) {
        case .success(let displayName):
            guard let displayName = displayName,
                  let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? EventBasedTimelineItemProtocol else {
                return
            }
            
            item.senderDisplayName = displayName
            timelineItems[index] = item
            callbacks.send(.updatedTimelineItem(timelineItem.id))
        case .failure:
            break
        }
    }
}
