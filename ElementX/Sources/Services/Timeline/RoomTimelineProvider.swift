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
        itemProxies = []

        Task {
            let roomTimelineListener = RoomTimelineListener()
            await roomProxy.addTimelineListener(listener: roomTimelineListener)

            roomTimelineListener
                .itemsUpdatePublisher
                .collect(.byTime(DispatchQueue.global(), 0.25))
                .sink { self.updateItemsWithDiffs($0) }
                .store(in: &cancellables)
        }
    }
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineProviderError> {
        // Set this back to false after actually updating the items or if failed
        backPaginationPublisher.send(true)
        
        MXLog.info("Started back pagination request")
        switch await roomProxy.paginateBackwards(count: count) {
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
    
    // MARK: - Private
    
    private func updateItemsWithDiffs(_ diffs: [TimelineDiff]) {
        MXLog.info("Received timeline diffs")
        
        itemProxies = diffs
            .reduce(itemProxies) { partialResult, diff in
                guard let collectionDiff = buildDiff(from: diff, on: partialResult) else {
                    return partialResult
                }
                
                guard let new = partialResult.applying(collectionDiff) else {
                    fatalError("Failed miserably")
                }
                
                MXLog.info("New count: \(new.count)")
                
                return new
            }
        
        MXLog.info("Finished applying diffs")
    }
     
    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func buildDiff(from diff: TimelineDiff, on itemProxies: [TimelineItemProxy]) -> CollectionDifference<TimelineItemProxy>? {
        var changes = [CollectionDifference<TimelineItemProxy>.Change]()
        
        switch diff.change() {
        case .push:
            if let item = diff.push() {
                let itemProxy = TimelineItemProxy(item: item)
                MXLog.verbose("Push")
                changes.append(.insert(offset: Int(itemProxies.count), element: itemProxy, associatedWith: nil))
            }
        case .updateAt:
            if let update = diff.updateAt() {
                MXLog.verbose("Update \(update.index), current total count: \(itemProxies.count)")
                let itemProxy = TimelineItemProxy(item: update.item)
                changes.append(.remove(offset: Int(update.index), element: itemProxy, associatedWith: nil))
                changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            }
        case .insertAt:
            if let update = diff.insertAt() {
                MXLog.verbose("Insert at \(update.index), current total count: \(itemProxies.count)")
                let itemProxy = TimelineItemProxy(item: update.item)
                changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            }
        case .move:
            if let update = diff.move() {
                MXLog.verbose("Move from: \(update.oldIndex) to: \(update.newIndex), current total count: \(itemProxies.count)")
                let itemProxy = itemProxies[Int(update.oldIndex)]
                changes.append(.remove(offset: Int(update.oldIndex), element: itemProxy, associatedWith: nil))
                changes.append(.insert(offset: Int(update.newIndex), element: itemProxy, associatedWith: nil))
            }
        case .removeAt:
            if let index = diff.removeAt() {
                MXLog.verbose("Remove from: \(index), current total count: \(itemProxies.count)")
                let itemProxy = itemProxies[Int(index)]
                changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
            }
        case .replace:
            if let items = diff.replace() {
                MXLog.verbose("Replace all items with new count: \(items.count), current total count: \(itemProxies.count)")
                for (index, itemProxy) in itemProxies.enumerated() {
                    changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
                }
                
                for (index, item) in items.enumerated() {
                    changes.append(.insert(offset: index, element: TimelineItemProxy(item: item), associatedWith: nil))
                }
            }
        case .clear:
            MXLog.verbose("Clear all items, current total count: \(itemProxies.count)")
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .pop:
            MXLog.verbose("Pop, current total count: \(itemProxies.count)")
            if let itemProxy = itemProxies.last {
                changes.append(.remove(offset: itemProxies.count - 1, element: itemProxy, associatedWith: nil))
            }
        }
        
        return CollectionDifference(changes)
    }
}
