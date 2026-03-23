//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

class RoomThreadListProxy: RoomThreadListServiceProxyProtocol {
    private let threadListService: ThreadListServiceProtocol
    private let eventStringBuilder: RoomEventStringBuilder
    
    private var itemUpdatesHandle: TaskHandle?
    private let itemsSubject = CurrentValueSubject<[RoomThreadListItem], Never>([])
    var itemsPublisher: CurrentValuePublisher<[RoomThreadListItem], Never> {
        itemsSubject.asCurrentValuePublisher()
    }
    
    private var paginationStateHandle: TaskHandle?
    let paginationStatePublisher: CurrentValuePublisher<RoomThreadListPaginationState, Never>
    
    init(threadListService: ThreadListServiceProtocol, eventStringBuilder: RoomEventStringBuilder, paginationToken: String? = nil) {
        self.threadListService = threadListService
        self.eventStringBuilder = eventStringBuilder
        
        let paginationStateSubject = CurrentValueSubject<RoomThreadListPaginationState, Never>(.init(sdkState: threadListService.paginationState()))
        paginationStatePublisher = paginationStateSubject.asCurrentValuePublisher()
        
        paginationStateHandle = threadListService.subscribeToPaginationStateUpdates(listener: SDKListener { state in
            paginationStateSubject.send(.init(sdkState: state))
        })
        
        updateItems()
        
        itemUpdatesHandle = self.threadListService.subscribeToItemsUpdates(listener: SDKListener { [weak self] _ in
            self?.updateItems()
        })
    }
    
    func paginate() async -> Result<Void, RoomProxyError> {
        do {
            try await threadListService.paginate()
            return .success(())
        } catch {
            MXLog.error("Failed paginating with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: - Private
    
    private func updateItems() {
        let items = threadListService.items().map { item in
            guard let rootMessageDetails = buildMessageDetails(item.rootEvent) else {
                fatalError("This should never fail™")
            }
            
            let latestMessageDetails = buildMessageDetails(item.latestEvent)
            
            return RoomThreadListItem(id: item.rootEvent.eventId,
                                      rootMessageDetails: rootMessageDetails,
                                      latestMessageDetails: latestMessageDetails,
                                      numberOfReplies: UInt(item.numReplies))
        }
        
        itemsSubject.send(items)
    }
    
    private func buildMessageDetails(_ threadListItemEvent: ThreadListItemEvent?) -> RoomThreadListItem.MessageDetails? {
        guard let threadListItemEvent else {
            return nil
        }
        
        let sender = TimelineItemSender(senderID: threadListItemEvent.sender, senderProfile: threadListItemEvent.senderProfile)
        let timestamp = Date(timeIntervalSince1970: TimeInterval(threadListItemEvent.timestamp / 1000))
                
        let message: AttributedString? = if let content = threadListItemEvent.content {
            eventStringBuilder.buildAttributedString(for: content,
                                                     sender: sender,
                                                     isOutgoing: threadListItemEvent.isOwn)
        } else {
            nil
        }
        
        return .init(sender: sender, timestamp: timestamp, message: message)
    }
}

extension RoomThreadListPaginationState {
    init(sdkState: MatrixRustSDK.ThreadListPaginationState) {
        switch sdkState {
        case .loading:
            self = .loading
        case .idle(let endReached):
            self = .idle(endReached: endReached)
        }
    }
}
