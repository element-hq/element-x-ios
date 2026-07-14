//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
struct ChatsTabFlowCoordinatorTests {
    var clientProxy: ClientProxyMock!
    var timelineControllerFactory: TimelineControllerFactoryMock!
    var chatsTabFlowCoordinator: ChatsTabFlowCoordinator!
    var splitCoordinator: NavigationSplitCoordinator!
    var notificationManager: NotificationManagerMock!
    let stateMachineFactory = PublishedStateMachineFactory()
    
    var cancellables = Set<AnyCancellable>()
    
    var detailCoordinator: CoordinatorProtocol? {
        splitCoordinator.detailCoordinator
    }
    
    var detailNavigationStack: NavigationStackCoordinator? {
        detailCoordinator as? NavigationStackCoordinator
    }
    
    init() async throws {
        let appSettings = AppSettings.volatile()
        
        clientProxy = ClientProxyMock(.init(userID: "hi@bob", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
        timelineControllerFactory = TimelineControllerFactoryMock(.init())
        
        splitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator(hideBrandChrome: false))
        
        notificationManager = NotificationManagerMock()
        
        let flowParameters = CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  elementCallService: ElementCallServiceMock(.init()),
                                                  timelineControllerFactory: timelineControllerFactory,
                                                  emojiProvider: EmojiProvider(appSettings: appSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: AppMediatorMock(.init()),
                                                  appSettings: appSettings,
                                                  appHooks: AppHooks(),
                                                  analytics: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  notificationManager: notificationManager,
                                                  stateMachineFactory: stateMachineFactory)
        chatsTabFlowCoordinator = ChatsTabFlowCoordinator(isNewLogin: false,
                                                          navigationSplitCoordinator: splitCoordinator,
                                                          flowParameters: flowParameters)
        
        let deferred = deferFulfillment(stateMachineFactory.chatsTabFlowStatePublisher) { $0 == .roomList(detailState: nil) }
        chatsTabFlowCoordinator.start()
        try await deferred.fulfill()
    }
    
    @Test
    mutating func roomPresentation() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        #expect(detailNavigationStack?.rootCoordinator == nil)
        #expect(detailCoordinator == nil)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(detailState: .room(roomID: "2")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        #expect(detailNavigationStack?.rootCoordinator == nil)
        #expect(detailCoordinator == nil)
        
        #expect(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations == ["1", "1", "2"])
    }
    
    @Test
    mutating func roomAliasPresentation() async throws {
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "1", servers: []))
        
        try await process(route: .roomAlias("#alias:matrix.org"), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        #expect(detailNavigationStack?.rootCoordinator == nil)
        #expect(detailCoordinator == nil)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        clientProxy.resolveRoomAliasReturnValue = .success(.init(roomId: "2", servers: []))
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(detailState: .room(roomID: "2")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        #expect(detailNavigationStack?.rootCoordinator == nil)
        #expect(detailCoordinator == nil)
        
        #expect(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations == ["1", "1", "2"])
    }
    
    @Test
    mutating func roomDetailsPresentation() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .roomList, expectedState: .roomList(detailState: nil))
        #expect(detailNavigationStack?.rootCoordinator == nil)
        #expect(detailCoordinator == nil)
    }
    
    @Test
    mutating func stackUnwinding() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .room(roomID: "2", via: []), expectedState: .roomList(detailState: .room(roomID: "2")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
    }
    
    @Test
    mutating func noOp() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        let unexpectedFulfillment = deferFailure(stateMachineFactory.chatsTabFlowStatePublisher, timeout: .seconds(1)) { _ in true }
        chatsTabFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
    }
    
    @Test
    mutating func switchToDifferentDetails() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .roomDetails(roomID: "2"), expectedState: .roomList(detailState: .room(roomID: "2")))
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
    }
    
    @Test
    mutating func pushDetails() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        let unexpectedFulfillment = deferFailure(stateMachineFactory.chatsTabFlowStatePublisher, timeout: .seconds(1)) { _ in true }
        chatsTabFlowCoordinator.handleAppRoute(.roomDetails(roomID: "1"), animated: true)
        try await unexpectedFulfillment.fulfill()
        
        let detailStack = try #require(detailNavigationStack)
        let deferredPush = deferFulfillment(detailStack.observe(\.stackCoordinators.count)) { $0 == 1 }
        try await deferredPush.fulfill()
        
        #expect(detailStack.rootCoordinator is RoomScreenCoordinator)
        #expect(detailStack.stackCoordinators.first is RoomDetailsScreenCoordinator)
    }
    
    @Test
    mutating func replaceDetailsWithTimeline() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
        
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailCoordinator != nil)
    }
    
    @Test
    mutating func userProfileClearsStack() async throws {
        try await process(route: .roomDetails(roomID: "1"), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomDetailsScreenCoordinator)
        #expect(detailCoordinator != nil)
        #expect(splitCoordinator.sheetCoordinator == nil)
        
        try await process(route: .userProfile(userID: "alice"), expectedState: .userProfileScreen)
        #expect(detailNavigationStack?.rootCoordinator == nil)
        let sheetStackCoordinator = try #require(splitCoordinator.sheetCoordinator as? NavigationStackCoordinator, "There should be a navigation stack presented as a sheet.")
        #expect(sheetStackCoordinator.rootCoordinator is UserProfileScreenCoordinator)
    }
    
    @Test
    mutating func roomClearsStack() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailNavigationStack?.stackCoordinators.isEmpty == true)
        #expect(detailCoordinator != nil)
        
        chatsTabFlowCoordinator.handleAppRoute(.childRoom(roomID: "2", via: []), animated: true)
        let detailStack = try #require(detailNavigationStack)
        let deferredPush = deferFulfillment(detailStack.observe(\.stackCoordinators.count)) { $0 == 1 }
        try await deferredPush.fulfill()
        
        #expect(detailStack.rootCoordinator is RoomScreenCoordinator)
        #expect(detailStack.stackCoordinators.first is RoomScreenCoordinator)
        
        try await process(route: .room(roomID: "3", via: []), expectedState: .roomList(detailState: .room(roomID: "3")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailNavigationStack?.stackCoordinators.isEmpty == true)
        #expect(detailCoordinator != nil)
    }
    
    @Test
    mutating func eventRoutes() async throws {
        // A regular event route should set its room as the root of the stack and focus on the event.
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailNavigationStack?.stackCoordinators.isEmpty == true)
        #expect(detailCoordinator != nil)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount == 1)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID == "1")
        
        // A child event route should push a new room screen onto the stack and focus on the event.
        chatsTabFlowCoordinator.handleAppRoute(.childEvent(eventID: "2", roomID: "2", via: []), animated: true)
        let detailStack = try #require(detailNavigationStack)
        let deferredPush = deferFulfillment(detailStack.observe(\.stackCoordinators.count)) { $0 == 1 }
        try await deferredPush.fulfill()
        
        #expect(detailStack.rootCoordinator is RoomScreenCoordinator)
        #expect(detailStack.stackCoordinators.count == 1)
        #expect(detailStack.stackCoordinators.first is RoomScreenCoordinator)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount == 2)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID == "2")
        
        // A subsequent regular event route should clear the stack and set the new room as the root of the stack.
        try await process(route: .event(eventID: "3", roomID: "3", via: []), expectedState: .roomList(detailState: .room(roomID: "3")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailNavigationStack?.stackCoordinators.isEmpty == true)
        #expect(detailCoordinator != nil)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount == 3)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID == "3")
        
        // A regular event route for the same room should set a new instance of the room as the root of the stack.
        try await process(route: .event(eventID: "4", roomID: "3", via: []), expectedState: .roomList(detailState: .room(roomID: "3")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(detailNavigationStack?.stackCoordinators.isEmpty == true)
        #expect(detailCoordinator != nil)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderCallsCount == 4)
        #expect(timelineControllerFactory.buildTimelineControllerRoomProxyInitialFocussedEventIDTimelineItemFactoryMediaProviderReceivedArguments?.initialFocussedEventID == "4",
                "A new timeline should be created for the same room ID, so that the screen isn't stale while loading.")
    }
    
    @Test
    mutating func shareMediaRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: "2", mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await process(route: .share(sharePayload),
                          expectedState: .roomList(detailState: .room(roomID: "2")))
        
        let deferredSheet = deferFulfillment(splitCoordinator.observe(\.sheetCoordinatorID)) { $0 != nil }
        try await deferredSheet.fulfill()
        
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect((splitCoordinator.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
    }
    
    @Test
    mutating func shareTextRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedState: .roomList(detailState: .room(roomID: "1")))
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        
        let sharePayload: ShareExtensionPayload = .text(roomID: "2", text: "Important text")
        try await process(route: .share(sharePayload),
                          expectedState: .roomList(detailState: .room(roomID: "2")))
        
        #expect(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(splitCoordinator.sheetCoordinator == nil, "The media upload sheet shouldn't be shown when sharing text.")
    }
    
    // MARK: - Private
    
    private func process(route: AppRoute, expectedState: ChatsTabFlowCoordinatorStateMachine.State) async throws {
        // Keep the previous root coordinator alive while waiting, otherwise a newly presented
        // coordinator could be allocated at the same address and be mistaken for it below.
        let previousDetailRootCoordinator = splitCoordinator.detailRootCoordinator
        let previousDetailRootCoordinatorID = previousDetailRootCoordinator.map { ObjectIdentifier($0) }
        
        let deferred = deferFulfillment(stateMachineFactory.chatsTabFlowStatePublisher) { $0 == expectedState }
        chatsTabFlowCoordinator.handleAppRoute(route, animated: true)
        try await deferred.fulfill()
        
        // The state machine's state changes before the coordinators have updated the stack,
        // so also wait for the navigation side effect implied by the expected state.
        switch expectedState {
        case .roomList(detailState: .some(.room)):
            let deferredDetail = deferFulfillment(splitCoordinator.observe(\.detailRootCoordinatorID)) { $0 != nil && $0 != previousDetailRootCoordinatorID }
            try await deferredDetail.fulfill()
        case .roomList(detailState: nil):
            let deferredDetail = deferFulfillment(splitCoordinator.observe(\.detailCoordinatorID)) { $0 == nil }
            try await deferredDetail.fulfill()
        case .userProfileScreen:
            let deferredDetail = deferFulfillment(splitCoordinator.observe(\.detailRootCoordinatorID)) { $0 == nil }
            try await deferredDetail.fulfill()
            
            let deferredSheet = deferFulfillment(splitCoordinator.observe(\.sheetCoordinatorID)) { $0 != nil }
            try await deferredSheet.fulfill()
        default:
            break
        }
        
        withExtendedLifetime(previousDetailRootCoordinator) { }
    }
}
