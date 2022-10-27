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
import MatrixRustSDK

#warning("Rename to RoomTimelineListener???")
class WeakRoomTimelineProviderWrapper: TimelineListener {
    private weak var timelineProvider: RoomTimelineProvider?
    
    init(timelineProvider: RoomTimelineProvider) {
        self.timelineProvider = timelineProvider
    }
    
    func onUpdate(update: TimelineDiff) {
        timelineProvider?.onUpdate(update: update)
    }
}

class RoomTimelineProvider: RoomTimelineProviderProtocol {
    private let roomProxy: RoomProxyProtocol
    private var cancellables = Set<AnyCancellable>()
    
    let callbacks = PassthroughSubject<RoomTimelineProviderCallback, Never>()
    
    private(set) var itemProxies: [TimelineItemProxy]
    
    init(roomProxy: RoomProxyProtocol) {
        self.roomProxy = roomProxy
        itemProxies = []
        
        Task {
            await roomProxy.addTimelineListener(listener: WeakRoomTimelineProviderWrapper(timelineProvider: self))
        }
    }
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.paginateBackwards(count: count) {
        case .success:
            return .success(())
        case .failure(let error):
            if error == .noMoreMessagesToBackPaginate { return .failure(.noMoreMessagesToBackPaginate) }
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
    
    func redact(_ eventID: String) async -> Result<Void, RoomTimelineProviderError> {
        switch await roomProxy.redact(eventID) {
        case .success:
            return .success(())
        case .failure:
            return .failure(.failedRedactingItem)
        }
    }
}

// MARK: - TimelineListener

private extension RoomTimelineProvider {
    func onUpdate(update: TimelineDiff) {
        let change = update.change()
        MXLog.verbose("Change: \(change)")
        
        switch change {
        case .replace:
            replaceItems(update.replace())
        case .insertAt:
            insertItem(update.insertAt())
        case .updateAt:
            updateItem(update.updateAt())
        case .removeAt:
            removeItem(at: update.removeAt())
        case .move:
            moveItem(update.move())
        case .push:
            pushItem(update.push())
        case .pop:
            popItem()
        case .clear:
            clearAllItems()
        }
        
        callbacks.send(.updatedMessages)
    }
    
    private func replaceItems(_ items: [MatrixRustSDK.TimelineItem]?) {
        guard let items else { return }
        itemProxies = items.map(TimelineItemProxy.init)
    }
    
    private func insertItem(_ data: InsertAtData?) {
        guard let data else { return }
        let itemProxy = TimelineItemProxy(item: data.item)
        itemProxies.insert(itemProxy, at: Int(data.index))
    }
    
    private func updateItem(_ data: UpdateAtData?) {
        guard let data else { return }
        let itemProxy = TimelineItemProxy(item: data.item)
        itemProxies[Int(data.index)] = itemProxy
    }
    
    private func removeItem(at index: UInt32?) {
        guard let index else { return }
        itemProxies.remove(at: Int(index))
    }
    
    private func moveItem(_ data: MoveData?) {
        guard let data else { return }
        itemProxies.move(fromOffsets: IndexSet(integer: Int(data.oldIndex)), toOffset: Int(data.newIndex))
    }
    
    private func pushItem(_ item: MatrixRustSDK.TimelineItem?) {
        guard let item else { return }
        itemProxies.append(TimelineItemProxy(item: item))
    }
    
    private func popItem() {
        itemProxies.removeLast()
    }
    
    private func clearAllItems() {
        itemProxies.removeAll()
    }
}
