//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Foundation
import UIKit

class RoomTimelineController: RoomTimelineControllerProtocol {
    private let userId: String
    private let timelineProvider: RoomTimelineProviderProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    private let mediaProvider: MediaProviderProtocol
    private let roomProxy: RoomProxyProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private var timelineItemsUpdateTask: Task<Void, Never>? {
        willSet {
            timelineItemsUpdateTask?.cancel()
        }
    }
    
    let roomId: String
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    private(set) var timelineItems = [RoomTimelineItemProtocol]()
    
    init(userId: String,
         roomId: String,
         timelineProvider: RoomTimelineProviderProtocol,
         timelineItemFactory: RoomTimelineItemFactoryProtocol,
         mediaProvider: MediaProviderProtocol,
         roomProxy: RoomProxyProtocol) {
        self.userId = userId
        self.roomId = roomId
        self.timelineProvider = timelineProvider
        self.timelineItemFactory = timelineItemFactory
        self.mediaProvider = mediaProvider
        self.roomProxy = roomProxy
        
        self.timelineProvider
            .itemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                
                self.updateTimelineItems()
            }
            .store(in: &cancellables)
        
        self.timelineProvider
            .backPaginationPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                if value {
                    self?.callbacks.send(.startedBackPaginating)
                } else {
                    self?.callbacks.send(.finishedBackPaginating)
                }
            }
            .store(in: &cancellables)
        
        updateTimelineItems()
        
        NotificationCenter.default.addObserver(self, selector: #selector(contentSizeCategoryDidChange), name: UIContentSizeCategory.didChangeNotification, object: nil)
    }
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError> {
        switch await timelineProvider.paginateBackwards(count) {
        case .success:
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
            await loadImageForImageTimelineItem(item)
        case let item as VideoRoomTimelineItem:
            await loadImageForVideoTimelineItem(item)
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
    
    func sendReply(_ message: String, to itemId: String) async {
        switch await timelineProvider.sendMessage(message, inReplyToItemId: itemId) {
        default:
            break
        }
    }

    func editMessage(_ newMessage: String, of itemId: String) async {
        switch await timelineProvider.editMessage(newMessage, originalItemId: itemId) {
        default:
            break
        }
    }
    
    func redact(_ eventID: String) async {
        switch await timelineProvider.redact(eventID) {
        default:
            break
        }
    }
    
    // Handle this paralel to the timeline items so we're not forced
    // to bundle the Rust side objects within them
    func debugDescriptionFor(_ itemId: String) -> String {
        var description = "Unknown item"
        timelineProvider.itemsPublisher.value.forEach { timelineItemProxy in
            switch timelineItemProxy {
            case .event(let item):
                if item.id == itemId {
                    description = item.debugDescription
                    return
                }
            default:
                break
            }
        }
        
        return description
    }

    // MARK: - Private
    
    @objc private func contentSizeCategoryDidChange() {
        // Recompute all attributed strings on content size changes -> DynamicType support
        updateTimelineItems()
    }
    
    private func updateTimelineItems() {
        timelineItemsUpdateTask = Task {
            await asyncUpdateTimelineItems()
        }
    }
    
    private func asyncUpdateTimelineItems() async {
        var newTimelineItems = [RoomTimelineItemProtocol]()

        for (index, itemProxy) in timelineProvider.itemsPublisher.value.enumerated() {
            if Task.isCancelled {
                return
            }

            let previousItemProxy = timelineProvider.itemsPublisher.value[safe: index - 1]
            let nextItemProxy = timelineProvider.itemsPublisher.value[safe: index + 1]

            let inGroupState = inGroupState(for: itemProxy, previousItemProxy: previousItemProxy, nextItemProxy: nextItemProxy)
            
            switch itemProxy {
            case .event(let eventItem):
                newTimelineItems.append(timelineItemFactory.buildTimelineItemFor(eventItemProxy: eventItem,
                                                                                 inGroupState: inGroupState))
            default:
                break
            }
        }
        
        if Task.isCancelled {
            return
        }
        
        timelineItems = newTimelineItems
        
        callbacks.send(.updatedTimelineItems)
    }

    private func inGroupState(for itemProxy: TimelineItemProxy,
                              previousItemProxy: TimelineItemProxy?,
                              nextItemProxy: TimelineItemProxy?) -> TimelineItemInGroupState {
        guard let previousItem = previousItemProxy else {
            //  no previous item, check next item
            guard let nextItem = nextItemProxy else {
                //  no next item neither, this is single
                return .single
            }
            guard nextItem.canBeGrouped(with: itemProxy) else {
                //  there is a next item but can't be grouped, this is single
                return .single
            }
            //  next will be grouped with this one, this is the start
            return .beginning
        }

        guard let nextItem = nextItemProxy else {
            //  no next item
            guard itemProxy.canBeGrouped(with: previousItem) else {
                //  there is a previous item but can't be grouped, this is single
                return .single
            }
            //  will be grouped with previous, this is the end
            return .end
        }

        guard itemProxy.canBeGrouped(with: previousItem) else {
            guard nextItem.canBeGrouped(with: itemProxy) else {
                //  there is a next item but can't be grouped, this is single
                return .single
            }
            //  next will be grouped with this one, this is the start
            return .beginning
        }

        guard nextItem.canBeGrouped(with: itemProxy) else {
            //  there is a next item but can't be grouped, this is the end
            return .end
        }

        //  next will be grouped with this one, this is the start
        return .middle
    }
    
    private func loadImageForImageTimelineItem(_ timelineItem: ImageRoomTimelineItem) async {
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

    private func loadImageForVideoTimelineItem(_ timelineItem: VideoRoomTimelineItem) async {
        if timelineItem.image != nil {
            return
        }

        guard let source = timelineItem.thumbnailSource else {
            return
        }

        switch await mediaProvider.loadImageFromSource(source) {
        case .success(let image):
            guard let index = timelineItems.firstIndex(where: { $0.id == timelineItem.id }),
                  var item = timelineItems[index] as? VideoRoomTimelineItem else {
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
        
        switch await roomProxy.loadAvatarURLForUserId(timelineItem.senderId) {
        case .success(let avatarURLString):
            guard let avatarURLString else {
                return
            }
            
            switch await mediaProvider.loadImageFromURLString(avatarURLString, avatarSize: .user(on: .timeline)) {
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
        
        switch await roomProxy.loadDisplayNameForUserId(timelineItem.senderId) {
        case .success(let displayName):
            guard let displayName,
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
