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
import MatrixRustSDK

private class RoomTimelineListener: TimelineListener {
    let itemsUpdatePublisher = PassthroughSubject<TimelineDiff, Never>()
    
    func onUpdate(update: TimelineDiff) {
        itemsUpdatePublisher.send(update)
    }
}

class RoomTimelineProvider: RoomTimelineProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private let serialDispatchQueue: DispatchQueue
    private var cancellables = Set<AnyCancellable>()
    
    let itemsPublisher = CurrentValueSubject<[TimelineItemProxy], Never>([])
    let backPaginationPublisher = CurrentValueSubject<Bool, Never>(false)
    
    private var itemProxies: [TimelineItemProxy] {
        didSet {
            itemsPublisher.send(itemProxies)
            
            if backPaginationPublisher.value == true {
                backPaginationPublisher.send(false)
            }
        }
    }
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        serialDispatchQueue = DispatchQueue(label: "io.element.elementx.roomtimelineprovider")
        itemProxies = []

        Task {
            let roomTimelineListener = RoomTimelineListener()
            
            roomTimelineListener
                .itemsUpdatePublisher
                .receive(on: DispatchQueue.main)
//                .collect(.byTime(serialDispatchQueue, 0.25))
                .sink { [weak self] in self?.updateItemsWithDiffs([$0]) }
                .store(in: &cancellables)
            
            switch await roomProxy.addTimelineListener(listener: roomTimelineListener) {
            case .failure:
                MXLog.error("Failed adding timeline listener on room with identifier: \(await roomProxy.id)")
            default:
                break
            }
        }
    }
    
    func paginateBackwards(requestSize: UInt, untilNumberOfItems: UInt) async -> Result<Void, RoomTimelineProviderError> {
        // Set this back to false after actually updating the items or if failed
        backPaginationPublisher.send(true)
        
        MXLog.info("Started back pagination request")
        switch await roomProxy.paginateBackwards(requestSize: requestSize, untilNumberOfItems: untilNumberOfItems) {
        case .success:
            MXLog.info("Finished back pagination request")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed back pagination request with error: \(error)")
            backPaginationPublisher.send(false)
            
            if error == .noMoreMessagesToBackPaginate {
                return .failure(.noMoreMessagesToBackPaginate)
            }
            
            return .failure(.failedPaginatingBackwards)
        }
    }
    
    func sendMessage(_ message: String, inReplyToItemId: String?) async -> Result<Void, RoomTimelineProviderError> {
        if let inReplyToItemId {
            MXLog.info("Sending message in reply to: \(inReplyToItemId)")
        } else {
            MXLog.info("Sending message")
        }
        
        switch await roomProxy.sendMessage(message, inReplyToEventId: inReplyToItemId) {
        case .success:
            MXLog.info("Finished sending message")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed sending message with error: \(error)")
            return .failure(.failedSendingMessage)
        }
    }
    
    func sendReaction(_ reaction: String, for itemId: String) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.sendReaction(reaction, for: itemId) {
        case .success:
            MXLog.info("Finished sending reaction")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed sending reaction with error: \(error)")
            return .failure(.failedSendingReaction)
        }
    }

    func editMessage(_ newMessage: String, originalItemId: String) async -> Result<Void, RoomTimelineProviderError> {
        MXLog.info("Editing message: \(originalItemId)")
        switch await roomProxy.editMessage(newMessage, originalEventId: originalItemId) {
        case .success:
            MXLog.info("Finished editing message")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed editing message with error: \(error)")
            return .failure(.failedSendingMessage)
        }
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomTimelineProviderError> {
        MXLog.info("Redacting message: \(eventID)")
        switch await roomProxy.redact(eventID) {
        case .success:
            MXLog.info("Finished redacting message")
            return .success(())
        case .failure(let error):
            MXLog.error("Failed redacting message with error: \(error)")
            return .failure(.failedRedactingItem)
        }
    }
    
    func retryDecryption(forSessionId sessionId: String) async {
        await roomProxy.retryDecryption(forSessionId: sessionId)
    }
    
    // MARK: - Private
    
    private func updateItemsWithDiffs(_ diffs: [TimelineDiff]) {
        MXLog.verbose("Received timeline diffs")
        
        itemProxies = diffs
            .reduce(itemProxies) { currentItems, diff in
                guard let collectionDiff = buildDiff(from: diff, on: currentItems) else {
                    MXLog.error("Failed building CollectionDifference from \(diff)")
                    return currentItems
                }
                
                guard let updatedItems = currentItems.applying(collectionDiff) else {
                    MXLog.error("Failed applying diff: \(collectionDiff)")
                    return currentItems
                }
                
                MXLog.verbose("Applied diff \(collectionDiff), new count: \(updatedItems.count)")
                
                return updatedItems
            }
        
        MXLog.verbose("Finished applying diffs")
    }
     
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func buildDiff(from diff: TimelineDiff, on itemProxies: [TimelineItemProxy]) -> CollectionDifference<TimelineItemProxy>? {
        var changes = [CollectionDifference<TimelineItemProxy>.Change]()
        
        switch diff.change() {
        case .push:
            guard let item = diff.push() else {
                fatalError()
            }
            
            MXLog.verbose("Push")
            let itemProxy = TimelineItemProxy(item: item)
            changes.append(.insert(offset: Int(itemProxies.count), element: itemProxy, associatedWith: nil))
        case .updateAt:
            guard let update = diff.updateAt() else {
                fatalError()
            }
            
            MXLog.verbose("Update \(update.index), current total count: \(itemProxies.count)")
            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.remove(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .insertAt:
            guard let update = diff.insertAt() else {
                fatalError()
            }
            
            MXLog.verbose("Insert at \(update.index), current total count: \(itemProxies.count)")
            let itemProxy = TimelineItemProxy(item: update.item)
            changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
        case .move:
            guard let update = diff.move() else {
                fatalError()
            }
                
            MXLog.verbose("Move from: \(update.oldIndex) to: \(update.newIndex), current total count: \(itemProxies.count)")
            let itemProxy = itemProxies[Int(update.oldIndex)]
            changes.append(.remove(offset: Int(update.oldIndex), element: itemProxy, associatedWith: nil))
            changes.append(.insert(offset: Int(update.newIndex), element: itemProxy, associatedWith: nil))
        case .removeAt:
            guard let index = diff.removeAt() else {
                fatalError()
            }
            
            MXLog.verbose("Remove from: \(index), current total count: \(itemProxies.count)")
            let itemProxy = itemProxies[Int(index)]
            changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
        case .replace:
            guard let items = diff.replace() else {
                fatalError()
            }
            
            MXLog.verbose("Replace all items with new count: \(items.count), current total count: \(itemProxies.count)")
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
            
            for (index, item) in items.enumerated() {
                changes.append(.insert(offset: index, element: TimelineItemProxy(item: item), associatedWith: nil))
            }
        case .clear:
            MXLog.verbose("Clear all items, current total count: \(itemProxies.count)")
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .pop:
            MXLog.verbose("Pop, current total count: \(itemProxies.count)")
            guard let itemProxy = itemProxies.last else {
                fatalError()
            }
            
            changes.append(.remove(offset: itemProxies.count - 1, element: itemProxy, associatedWith: nil))
        }
        
        return CollectionDifference(changes)
    }
}
