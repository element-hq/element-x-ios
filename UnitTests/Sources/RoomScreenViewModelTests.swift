//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK

import Combine
import XCTest

@MainActor
class RoomScreenViewModelTests: XCTestCase {
    private var viewModel: RoomScreenViewModel!
    
    override func setUp() async throws {
        AppSettings.resetAllSettings()
    }
    
    override func tearDown() {
        viewModel = nil
    }
    
    func testPinnedEventsBanner() async throws {
        var configuration = JoinedRoomProxyMockConfiguration()
        let timelineSubject = PassthroughSubject<TimelineProxyProtocol, Never>()
        let infoSubject = CurrentValueSubject<RoomInfoProxy, Never>(.init(roomInfo: RoomInfo(configuration)))
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        // setup a way to inject the mock of the pinned events timeline
        roomProxyMock.pinnedEventsTimelineClosure = {
            await timelineSubject.values.first()
        }
        // setup the room proxy actions publisher
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: nil,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        
        // check if in the default state is not showing but is indeed loading
        var deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.count == 0
        }
        try await deferred.fulfill()
        XCTAssertTrue(viewModel.context.viewState.pinnedEventsBannerState.isLoading)
        XCTAssertFalse(viewModel.context.viewState.shouldShowPinnedEventsBanner)

        // check if if after the pinned event ids are set the banner is still in a loading state, but is both loading and showing with a counter
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.count == 2
        }
        configuration.pinnedEventIDs = ["test1", "test2"]
        infoSubject.send(.init(roomInfo: RoomInfo(configuration)))
        try await deferred.fulfill()
        XCTAssertTrue(viewModel.context.viewState.pinnedEventsBannerState.isLoading)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        XCTAssertEqual(viewModel.context.viewState.pinnedEventsBannerState.selectedPinnedIndex, 1)
        
        // setup the loaded pinned events injection in the timeline
        let pinnedTimelineMock = TimelineProxyMock()
        let pinnedTimelineProviderMock = RoomTimelineProviderMock()
        let providerUpdateSubject = PassthroughSubject<([TimelineItemProxy], PaginationState), Never>()
        pinnedTimelineProviderMock.underlyingUpdatePublisher = providerUpdateSubject.eraseToAnyPublisher()
        pinnedTimelineMock.timelineProvider = pinnedTimelineProviderMock
        pinnedTimelineProviderMock.itemProxies = [.event(.init(item: EventTimelineItem(configuration: .init(eventID: "test1")), uniqueID: .init(id: "1"))),
                                                  .event(.init(item: EventTimelineItem(configuration: .init(eventID: "test2")), uniqueID: .init(id: "2")))]
        
        // check if the banner is now in a loaded state and is showing the counter
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            !viewState.pinnedEventsBannerState.isLoading
        }
        timelineSubject.send(pinnedTimelineMock)
        try await deferred.fulfill()
        XCTAssertEqual(viewModel.context.viewState.pinnedEventsBannerState.count, 2)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        XCTAssertEqual(viewModel.context.viewState.pinnedEventsBannerState.selectedPinnedIndex, 1)
        
        // check if the banner is updating alongside the timeline
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.count == 3
        }
        providerUpdateSubject.send(([.event(.init(item: EventTimelineItem(configuration: .init(eventID: "test1")), uniqueID: .init(id: "1"))),
                                     .event(.init(item: EventTimelineItem(configuration: .init(eventID: "test2")), uniqueID: .init(id: "2"))),
                                     .event(.init(item: EventTimelineItem(configuration: .init(eventID: "test3")), uniqueID: .init(id: "3")))], .initial))
        try await deferred.fulfill()
        XCTAssertFalse(viewModel.context.viewState.pinnedEventsBannerState.isLoading)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        XCTAssertEqual(viewModel.context.viewState.pinnedEventsBannerState.selectedPinnedIndex, 1)

        // check how the scrolling changes the banner visibility
        viewModel.timelineHasScrolled(direction: .top)
        XCTAssertFalse(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        
        viewModel.timelineHasScrolled(direction: .bottom)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
    }
    
    func testPinnedEventsBannerSelection() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init())
        // setup a way to inject the mock of the pinned events timeline
        let pinnedTimelineMock = TimelineProxyMock()
        let pinnedTimelineProviderMock = RoomTimelineProviderMock()
        pinnedTimelineMock.timelineProvider = pinnedTimelineProviderMock
        pinnedTimelineProviderMock.underlyingUpdatePublisher = Empty<([TimelineItemProxy], PaginationState), Never>().eraseToAnyPublisher()
        pinnedTimelineProviderMock.itemProxies = [.event(.init(item: EventTimelineItem(configuration: .init(eventID: "test1")), uniqueID: .init(id: "1"))),
                                                  .event(.init(item: EventTimelineItem(configuration: .init(eventID: "test2")), uniqueID: .init(id: "2"))),
                                                  .event(.init(item: EventTimelineItem(configuration: .init(eventID: "test3")), uniqueID: .init(id: "3")))]
        roomProxyMock.underlyingPinnedEventsTimeline = pinnedTimelineMock
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: "test1",
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        
        // check if the banner is now in a loaded state and is showing the counter
        var deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            !viewState.pinnedEventsBannerState.isLoading
        }
        try await deferred.fulfill()
        XCTAssertEqual(viewModel.context.viewState.pinnedEventsBannerState.count, 3)
        XCTAssertTrue(viewModel.context.viewState.shouldShowPinnedEventsBanner)
        // And that is actually displaying the `initialSelectedPinEventID` which is gthe first one in the list
        XCTAssertEqual(viewModel.context.viewState.pinnedEventsBannerState.selectedPinnedIndex, 0)
        
        // check if the banner scrolls when tapping the previous pin
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.selectedPinnedIndex == 2
        }
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            if case let .focusEvent(eventID) = action {
                return eventID == "test1"
            }
            return false
        }
        viewModel.context.send(viewAction: .tappedPinnedEventsBanner)
        try await deferred.fulfill()
        try await deferredAction.fulfill()
        
        // check if the banner scrolls to the specific selected pin
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.pinnedEventsBannerState.selectedPinnedIndex == 1
        }
        viewModel.setSelectedPinnedEventID("test2")
        try await deferred.fulfill()
    }
    
    func testRoomInfoUpdate() async throws {
        var configuration = JoinedRoomProxyMockConfiguration(id: "TestID", name: "StartingName", avatarURL: nil, hasOngoingCall: false)
        let infoSubject = CurrentValueSubject<RoomInfoProxy, Never>(.init(roomInfo: RoomInfo(configuration)))
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        // setup the room proxy actions publisher
        roomProxyMock.canUserJoinCallUserIDReturnValue = .success(false)
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: nil,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.roomTitle == "StartingName" &&
                viewState.roomAvatar == .room(id: "TestID", name: "StartingName", avatarURL: nil) &&
                !viewState.canJoinCall &&
                !viewState.hasOngoingCall
        }
        try await deferred.fulfill()
        
        configuration.name = "NewName"
        configuration.avatarURL = .mockMXCAvatar
        configuration.hasOngoingCall = true
        roomProxyMock.canUserJoinCallUserIDReturnValue = .success(true)
        
        deferred = deferFulfillment(viewModel.context.$viewState) { viewState in
            viewState.roomTitle == "NewName" &&
                viewState.roomAvatar == .room(id: "TestID", name: "NewName", avatarURL: .mockMXCAvatar) &&
                viewState.canJoinCall &&
                viewState.hasOngoingCall
        }
        
        infoSubject.send(.init(roomInfo: RoomInfo(configuration)))
        try await deferred.fulfill()
    }
    
    func testCallButtonVisibility() async throws {
        // Given a room screen with no ongoing call.
        let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(nil)
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "MyRoomID"))
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: nil,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: ongoingCallRoomIDSubject.asCurrentValuePublisher(),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        XCTAssertTrue(viewModel.state.shouldShowCallButton)
        
        // When a call starts in this room.
        var deferred = deferFulfillment(viewModel.context.$viewState) { !$0.shouldShowCallButton }
        ongoingCallRoomIDSubject.send("MyRoomID")
        try await deferred.fulfill()
        
        // Then the call button should be hidden.
        XCTAssertFalse(viewModel.state.shouldShowCallButton)
        
        // When a call starts in a different room.
        deferred = deferFulfillment(viewModel.context.$viewState) { $0.shouldShowCallButton }
        ongoingCallRoomIDSubject.send("OtherRoomID")
        try await deferred.fulfill()
        
        // Then the call button should be shown again.
        XCTAssertTrue(viewModel.state.shouldShowCallButton)
        
        // When the call from the other room finishes.
        let deferredFailure = deferFailure(viewModel.context.$viewState, timeout: 1) { !$0.shouldShowCallButton }
        ongoingCallRoomIDSubject.send(nil)
        try await deferredFailure.fulfill()
        
        // Then the call button should remain visible shown.
        XCTAssertTrue(viewModel.state.shouldShowCallButton)
    }
    
    // MARK: - Knock Requests
    
    func testKnockRequestBanner() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org", displayName: "Alice", reason: "Hello World!")),
                                                                                   // This one should be filtered
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org", isSeen: true))]),
                                                      joinRule: .knock))
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: nil,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.shouldSeeKnockRequests &&
                state.unseenKnockRequests == [.init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: "Hello World!", eventID: "1")]
        }
        try await deferred.fulfill()
                
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .displayKnockRequests }
        viewModel.context.send(viewAction: .viewKnockRequests)
        try await deferredAction.fulfill()
        
        deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.handledEventIDs == ["1"] &&
                !state.shouldSeeKnockRequests
        }
        viewModel.context.send(viewAction: .acceptKnock(eventID: "1"))
        try await deferred.fulfill()
    }
    
    func testKnockRequestBannerMarkAsSeen() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org", displayName: "Alice", reason: "Hello World!")),
                                                                                   // This one should be filtered
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org"))]),
                                                      joinRule: .knock))
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: nil,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.shouldSeeKnockRequests &&
                state.unseenKnockRequests == [.init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: "Hello World!", eventID: "1"),
                                              .init(displayName: nil, avatarURL: nil, userID: "@bob:matrix.org", reason: nil, eventID: "2")]
        }
        try await deferred.fulfill()
        
        deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.handledEventIDs == ["1", "2"] &&
                !state.shouldSeeKnockRequests
        }
        viewModel.context.send(viewAction: .dismissKnockRequests)
        try await deferred.fulfill()
    }
    
    func testLoadingKnockRequests() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loading,
                                                      joinRule: .knock))
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: nil,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        
        // Loading state just does not appear at all
        let deferred = deferFulfillment(viewModel.context.$viewState) { !$0.shouldSeeKnockRequests }
        try await deferred.fulfill()
    }
    
    func testKnockRequestsBannerDoesNotAppearIfUserHasNoPermission() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org", displayName: "Alice", reason: "Hello World!"))]),
                                                      canUserInvite: false,
                                                      joinRule: .knock))
        let viewModel = RoomScreenViewModel(clientProxy: ClientProxyMock(),
                                            roomProxy: roomProxyMock,
                                            initialSelectedPinnedEventID: nil,
                                            mediaProvider: MediaProviderMock(configuration: .init()),
                                            ongoingCallRoomIDPublisher: .init(.init(nil)),
                                            appMediator: AppMediatorMock.default,
                                            appSettings: ServiceLocator.shared.settings,
                                            analyticsService: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        self.viewModel = viewModel
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.unseenKnockRequests == [.init(displayName: "Alice", avatarURL: nil, userID: "@alice:matrix.org", reason: "Hello World!", eventID: "1")] &&
                !state.shouldSeeKnockRequests
        }
        try await deferred.fulfill()
    }
}
