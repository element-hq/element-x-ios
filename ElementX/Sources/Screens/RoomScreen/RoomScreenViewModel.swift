//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import OrderedCollections
import SwiftUI

typealias RoomScreenViewModelType = StateStoreViewModel<RoomScreenViewState, RoomScreenViewAction>

class RoomScreenViewModel: RoomScreenViewModelType, RoomScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let appMediator: AppMediatorProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    private let pinnedEventStringBuilder: RoomEventStringBuilder
    private var initialSelectedPinnedEventID: String?
    
    private let actionsSubject: PassthroughSubject<RoomScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<RoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var pinnedEventsTimelineProvider: RoomTimelineProviderProtocol? {
        didSet {
            guard let pinnedEventsTimelineProvider else {
                return
            }
            
            buildPinnedEventContents(timelineItems: pinnedEventsTimelineProvider.itemProxies)
            pinnedEventsTimelineProvider.updatePublisher
                // When pinning or unpinning an item, the timeline might return empty for a short while, so we need to debounce it to prevent weird UI behaviours like the banner disappearing
                .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
                .sink { [weak self] updatedItems, _ in
                    guard let self else { return }
                    buildPinnedEventContents(timelineItems: updatedItems)
                }
                .store(in: &cancellables)
        }
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         initialSelectedPinnedEventID: String?,
         mediaProvider: MediaProviderProtocol,
         ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never>,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService) {
        self.roomProxy = roomProxy
        self.appMediator = appMediator
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        self.initialSelectedPinnedEventID = initialSelectedPinnedEventID
        pinnedEventStringBuilder = .pinnedEventStringBuilder(userID: roomProxy.ownUserID)

        super.init(initialViewState: .init(roomTitle: roomProxy.roomTitle,
                                           roomAvatar: roomProxy.avatar,
                                           hasOngoingCall: roomProxy.hasOngoingCall,
                                           bindings: .init()),
                   mediaProvider: mediaProvider)
        
        Task {
            await handleRoomInfoUpdate()
        }
        
        setupSubscriptions(ongoingCallRoomIDPublisher: ongoingCallRoomIDPublisher)
    }

    override func process(viewAction: RoomScreenViewAction) {
        switch viewAction {
        case .tappedPinnedEventsBanner:
            analyticsService.trackInteraction(name: .PinnedMessageBannerClick)
            if let eventID = state.pinnedEventsBannerState.selectedPinnedEventID {
                actionsSubject.send(.focusEvent(eventID: eventID))
            }
            state.pinnedEventsBannerState.previousPin()
        case .viewAllPins:
            analyticsService.trackInteraction(name: .PinnedMessageBannerViewAllButton)
            actionsSubject.send(.displayPinnedEventsTimeline)
        case .displayRoomDetails:
            actionsSubject.send(.displayRoomDetails)
        case .displayCall:
            actionsSubject.send(.displayCall)
            actionsSubject.send(.removeComposerFocus)
            analyticsService.trackInteraction(name: .MobileRoomCallButton)
        }
    }
    
    func timelineHasScrolled(direction: ScrollDirection) {
        state.lastScrollDirection = direction
    }
    
    func setSelectedPinnedEventID(_ eventID: String) {
        state.pinnedEventsBannerState.setSelectedPinnedEventID(eventID)
    }
    
    private func setupSubscriptions(ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never>) {
        let roomInfoSubscription = roomProxy
            .actionsPublisher
            .filter { $0 == .roomInfoUpdate }
        
        roomInfoSubscription
            .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] _ in
                guard let self else { return }
                state.roomTitle = roomProxy.roomTitle
                state.roomAvatar = roomProxy.avatar
                state.hasOngoingCall = roomProxy.hasOngoingCall
            }
            .store(in: &cancellables)
        
        Task { [weak self] in
            for await _ in roomInfoSubscription.receive(on: DispatchQueue.main).values {
                guard !Task.isCancelled else {
                    return
                }
                
                await self?.handleRoomInfoUpdate()
            }
        }
        .store(in: &cancellables)
        
        let pinningEnabledPublisher = appSettings.$pinningEnabled
        
        pinningEnabledPublisher
            .weakAssign(to: \.state.isPinningEnabled, on: self)
            .store(in: &cancellables)
        
        pinningEnabledPublisher
            .combineLatest(appMediator.networkMonitor.reachabilityPublisher)
            .filter { $0.0 && $0.1 == .reachable }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.setupPinnedEventsTimelineProviderIfNeeded()
            }
            .store(in: &cancellables)
        
        ongoingCallRoomIDPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] ongoingCallRoomID in
                guard let self else { return }
                state.shouldShowCallButton = ongoingCallRoomID != roomProxy.id
            }
            .store(in: &cancellables)
    }
    
    private func buildPinnedEventContents(timelineItems: [TimelineItemProxy]) {
        var pinnedEventContents = OrderedDictionary<String, AttributedString>()
        
        for item in timelineItems {
            // Only remote events are pinned
            if case let .event(event) = item,
               let eventID = event.id.eventID {
                pinnedEventContents.updateValue(pinnedEventStringBuilder.buildAttributedString(for: event) ?? AttributedString(L10n.commonUnsupportedEvent),
                                                forKey: eventID)
            }
        }
        
        state.pinnedEventsBannerState.setPinnedEventContents(pinnedEventContents)
        
        // If it's the first time we are setting the pinned events, we should select the initial event if available.
        if let initialSelectedPinnedEventID {
            state.pinnedEventsBannerState.setSelectedPinnedEventID(initialSelectedPinnedEventID)
            self.initialSelectedPinnedEventID = nil
        }
    }
    
    private func handleRoomInfoUpdate() async {
        let pinnedEventIDs = await roomProxy.pinnedEventIDs
        // Only update the loading state of the banner
        if state.pinnedEventsBannerState.isLoading {
            state.pinnedEventsBannerState = .loading(numbersOfEvents: pinnedEventIDs.count)
        }
        
        let userID = roomProxy.ownUserID
        if case let .success(permission) = await roomProxy.canUserJoinCall(userID: userID) {
            state.canJoinCall = permission
        }
    }
    
    private func setupPinnedEventsTimelineProviderIfNeeded() {
        guard pinnedEventsTimelineProvider == nil else {
            return
        }
        
        Task {
            guard let timelineProvider = await roomProxy.pinnedEventsTimeline?.timelineProvider else {
                return
            }
            
            if pinnedEventsTimelineProvider == nil {
                pinnedEventsTimelineProvider = timelineProvider
            }
        }
    }
}

extension RoomScreenViewModel {
    static func mock(roomProxyMock: JoinedRoomProxyMock) -> RoomScreenViewModel {
        RoomScreenViewModel(roomProxy: roomProxyMock,
                            initialSelectedPinnedEventID: nil,
                            mediaProvider: MockMediaProvider(),
                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                            appMediator: AppMediatorMock.default,
                            appSettings: ServiceLocator.shared.settings,
                            analyticsService: ServiceLocator.shared.analytics)
    }
}

private struct RoomContextKey: EnvironmentKey {
    @MainActor static let defaultValue: RoomScreenViewModel.Context? = nil
}

extension EnvironmentValues {
    /// Used to access and inject the room context without observing it
    var roomContext: RoomScreenViewModel.Context? {
        get { self[RoomContextKey.self] }
        set { self[RoomContextKey.self] = newValue }
    }
}
