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
    private let userSession: UserSessionProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    private let emojiProvider: EmojiProviderProtocol
    private let timelineControllerFactory: TimelineControllerFactoryProtocol
    private let timelineItemFactory: RoomTimelineItemFactoryProtocol
    
    private let actionsSubject: PassthroughSubject<BookmarksScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<BookmarksScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var timelineComponents = [(JoinedRoomProxyProtocol, TimelineProxyProtocol, TimelineViewModelProtocol)]()
    
    init(userSession: UserSessionProtocol,
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService,
         emojiProvider: EmojiProviderProtocol,
         timelineControllerFactory: TimelineControllerFactoryProtocol) {
        self.userSession = userSession
        self.mediaPlayerProvider = mediaPlayerProvider
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.emojiProvider = emojiProvider
        self.timelineControllerFactory = timelineControllerFactory
        
        timelineItemFactory = RoomTimelineItemFactory(userID: userSession.clientProxy.userID,
                                                      attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                      stateEventStringBuilder: RoomStateEventStringBuilder(userID: userSession.clientProxy.userID))
        
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
        case .display(let eventID, let roomID):
            actionsSubject.send(.display(eventID: eventID, roomID: roomID))
        }
    }
    
    // MARK: - Private
    
    private func setupTimelines() async {
        guard case let .success(roomsWithBookmarks) = await userSession.clientProxy.getRoomsWithBookmarks() else {
            #warning("Show an error or something")
            return
        }
        
        var timelineComponents = [(JoinedRoomProxyProtocol, TimelineProxyProtocol, TimelineViewModelProtocol)]()
        for roomID in roomsWithBookmarks {
            switch await userSession.clientProxy.roomForIdentifier(roomID) {
            case .joined(let roomProxy):
                if case let .success(timelineProxy) = await roomProxy.bookmarksTimeline() {
                    let timelineController = TimelineController(roomProxy: roomProxy,
                                                                timelineProxy: timelineProxy,
                                                                initialFocussedEventID: nil,
                                                                timelineItemFactory: timelineItemFactory,
                                                                mediaProvider: userSession.mediaProvider,
                                                                appSettings: appSettings)
                    
                    let viewModel = TimelineViewModel(roomProxy: roomProxy,
                                                      timelineController: timelineController,
                                                      userSession: userSession,
                                                      mediaPlayerProvider: mediaPlayerProvider,
                                                      userIndicatorController: userIndicatorController,
                                                      appMediator: appMediator,
                                                      appSettings: appSettings,
                                                      analyticsService: analyticsService,
                                                      emojiProvider: emojiProvider,
                                                      timelineControllerFactory: timelineControllerFactory)
                                        
                    timelineComponents.append((roomProxy, timelineProxy, viewModel))
                }
            default:
                continue
            }
        }
        
        self.timelineComponents = timelineComponents
        
        for timeline in timelineComponents.map(\.1) {
            timeline.timelineItemProvider.updatePublisher.sink { [weak self] _ in
                Task { await self?.updateBookmarks() }
            }
            .store(in: &cancellables)
        }
    }
    
    private func updateBookmarks() async {
        var stateItems = [BookmarkListItem]()
        
        for (roomProxy, timelineProxy, timelineViewModel) in timelineComponents {
            for timelineItemProxy in timelineProxy.timelineItemProvider.itemProxies {
                switch timelineItemProxy {
                case .event(let eventTimelineItemProxy):
                    if let item = timelineItemFactory.buildTimelineItem(for: eventTimelineItemProxy, isDM: false), let eventID = eventTimelineItemProxy.id.eventID {
                        stateItems.append(.init(timelineItemViewState: .init(item: item, groupStyle: .single),
                                                timelineContext: timelineViewModel.context,
                                                roomName: roomProxy.details.name ?? roomProxy.id,
                                                eventID: eventID,
                                                roomID: roomProxy.id,
                                                info: (item as? EventBasedTimelineItemProtocol)?.properties.bookmarkInfo))
                    }
                default:
                    continue
                }
            }
        }
        
        state.items = stateItems.sorted { firstItem, secondItem in
            guard let firstDate = firstItem.info?.creationDate, let secondDate = secondItem.info?.creationDate else {
                return false
            }
            
            return firstDate > secondDate
        }
    }
}
