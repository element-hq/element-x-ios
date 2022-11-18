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
                .collect(.byTime(DispatchQueue.global(), 0.5))
                .sink { self.updateItemsWithDiffs($0) }
                .store(in: &cancellables)
        }
    }
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineProviderError> {
        // Set this back to false after actually updating the items or if failed
        backPaginationPublisher.send(true)
        
        switch await roomProxy.paginateBackwards(count: count) {
        case .success:
            return .success(())
        case .failure(let error):
            backPaginationPublisher.send(false)
            
            if error == .noMoreMessagesToBackPaginate {
                return .failure(.noMoreMessagesToBackPaginate)
            }
            
            return .failure(.failedPaginatingBackwards)
        }
    }
    
    func sendMessage(_ message: String, inReplyToItemId: String?) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.sendMessage(message, inReplyToEventId: inReplyToItemId) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.failedSendingMessage)
        }
    }

    func editMessage(_ newMessage: String, originalItemId: String) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.editMessage(newMessage, originalEventId: originalItemId) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.failedSendingMessage)
        }
    }
    
    func redact(_ eventID: String) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.redact(eventID) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.failedRedactingItem)
        }
    }
    
    // MARK: - Private

    private func updateItemsWithDiffs(_ diffs: [TimelineDiff]) {
        itemProxies = diffs
            .compactMap(buildDiff)
            .reduce(itemProxies) { $0.applying($1) ?? $0 }
    }
     
    // swiftlint:disable:next cyclomatic_complexity
    private func buildDiff(from diff: TimelineDiff) -> CollectionDifference<TimelineItemProxy>? {
        var changes = [CollectionDifference<TimelineItemProxy>.Change]()
        
        switch diff.change() {
        case .push:
            if let item = diff.push() {
                let itemProxy = TimelineItemProxy(item: item)
                changes.append(.insert(offset: Int(itemProxies.count), element: itemProxy, associatedWith: nil))
            }
        case .updateAt:
            if let update = diff.updateAt() {
                let itemProxy = TimelineItemProxy(item: update.item)
                changes.append(.remove(offset: Int(update.index), element: itemProxy, associatedWith: nil))
                changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            }
        case .insertAt:
            if let update = diff.insertAt() {
                let itemProxy = TimelineItemProxy(item: update.item)
                changes.append(.insert(offset: Int(update.index), element: itemProxy, associatedWith: nil))
            }
        case .move:
            if let update = diff.move() {
                let itemProxy = itemProxies[Int(update.oldIndex)]
                changes.append(.remove(offset: Int(update.oldIndex), element: itemProxy, associatedWith: nil))
                changes.append(.insert(offset: Int(update.newIndex), element: itemProxy, associatedWith: nil))
            }
        case .removeAt:
            if let index = diff.removeAt() {
                let itemProxy = itemProxies[Int(index)]
                changes.append(.remove(offset: Int(index), element: itemProxy, associatedWith: nil))
            }
        case .replace:
            if let items = diff.replace() {
                for (index, itemProxy) in itemProxies.enumerated() {
                    changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
                }
                
                items
                    .reversed()
                    .map { TimelineItemProxy(item: $0) }
                    .forEach { itemProxy in
                        changes.append(.insert(offset: 0, element: itemProxy, associatedWith: nil))
                    }
            }
        case .clear:
            for (index, itemProxy) in itemProxies.enumerated() {
                changes.append(.remove(offset: index, element: itemProxy, associatedWith: nil))
            }
        case .pop:
            if let itemProxy = itemProxies.last {
                changes.append(.remove(offset: itemProxies.count - 1, element: itemProxy, associatedWith: nil))
            }
        }
        
        return CollectionDifference(changes)
    }
}
