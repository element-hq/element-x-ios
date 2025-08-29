//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias BookmarksScreenViewModelType = StateStoreViewModelV2<BookmarksScreenViewState, BookmarksScreenViewAction>

class BookmarksScreenViewModel: BookmarksScreenViewModelType, BookmarksScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    
    private let actionsSubject: PassthroughSubject<BookmarksScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<BookmarksScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var roomsAndTimelines = [(JoinedRoomProxyProtocol, TimelineProxyProtocol)]()

    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
        
        super.init(initialViewState: .init())
        
        Task {
            await setupTimelines()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: BookmarksScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }
    
    // MARK: - Private
    
    private func setupTimelines() async {
        guard case let .success(roomsWithBookmarks) = await clientProxy.getRoomsWithBookmarks() else {
            #warning("Show an error or something")
            return
        }
        
        var roomsAndTimelines = [(JoinedRoomProxyProtocol, TimelineProxyProtocol)]()
        for roomID in roomsWithBookmarks {
            switch await clientProxy.roomForIdentifier(roomID) {
            case .joined(let roomProxy):
                if case let .success(timelineProxy) = await roomProxy.bookmarksTimeline() {
                    roomsAndTimelines.append((roomProxy, timelineProxy))
                }
            default:
                continue
            }
        }
        
        self.roomsAndTimelines = roomsAndTimelines
        
        for timeline in roomsAndTimelines.map(\.1) {
            timeline.timelineItemProvider.updatePublisher.sink { [weak self] _ in
                Task { await self?.updateBookmarks() }
            }
            .store(in: &cancellables)
        }
    }
    
    private func updateBookmarks() async {
        var stateItems = [BookmarkListItem]()
        
        for (room, timeline) in roomsAndTimelines {
            for timelineItemProxy in timeline.timelineItemProvider.itemProxies {
                switch timelineItemProxy {
                case .event(let eventTimelineItemProxy):
                    switch eventTimelineItemProxy.item.content {
                    case .msgLike(let content):
                        switch content.kind {
                        case .message(let messageContent):
                            stateItems.append(.init(id: eventTimelineItemProxy.id,
                                                    body: messageContent.body,
                                                    roomName: room.details.name ?? room.id))
                        default:
                            continue
                        }
                    default:
                        continue
                    }
                default:
                    continue
                }
            }
        }
        
        state.items = stateItems
    }
}
