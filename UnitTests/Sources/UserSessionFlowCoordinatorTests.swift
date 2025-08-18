//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

import Combine
@testable import ElementX

@MainActor
class UserSessionFlowCoordinatorTests: XCTestCase {
    var clientProxy: ClientProxyMock!
    var timelineControllerFactory: TimelineControllerFactoryMock!
    var userSessionFlowCoordinator: UserSessionFlowCoordinator!
    var rootCoordinator: NavigationRootCoordinator!
    var notificationManager: NotificationManagerMock!
    let stateMachineFactory = PublishedStateMachineFactory()
    
    var cancellables = Set<AnyCancellable>()
    
    var tabCoordinator: NavigationTabCoordinator<UserSessionFlowCoordinator.HomeTab>? { rootCoordinator?.rootCoordinator as? NavigationTabCoordinator }
    var chatsSplitCoordinator: NavigationSplitCoordinator? { tabCoordinator?.tabCoordinators.first as? NavigationSplitCoordinator }
    var detailCoordinator: CoordinatorProtocol? { chatsSplitCoordinator?.detailCoordinator }
    var detailNavigationStack: NavigationStackCoordinator? { detailCoordinator as? NavigationStackCoordinator }
    
    override func setUp() async throws {
        cancellables.removeAll()
        clientProxy = ClientProxyMock(.init(userID: "hi@bob", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
        timelineControllerFactory = TimelineControllerFactoryMock(.init())
        
        rootCoordinator = NavigationRootCoordinator()
        
        notificationManager = NotificationManagerMock()
        
        userSessionFlowCoordinator = UserSessionFlowCoordinator(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                                isNewLogin: false,
                                                                navigationRootCoordinator: rootCoordinator,
                                                                appLockService: AppLockServiceMock(),
                                                                bugReportService: BugReportServiceMock(.init()),
                                                                elementCallService: ElementCallServiceMock(.init()),
                                                                timelineControllerFactory: timelineControllerFactory,
                                                                appMediator: AppMediatorMock.default,
                                                                appSettings: ServiceLocator.shared.settings,
                                                                appHooks: AppHooks(),
                                                                analytics: ServiceLocator.shared.analytics,
                                                                notificationManager: notificationManager,
                                                                stateMachineFactory: stateMachineFactory)
        
        userSessionFlowCoordinator.start()
    }
    
    func testInitialState() async throws {
        XCTAssertNotNil(chatsSplitCoordinator)
        XCTAssertNil(detailCoordinator)
    }
    
    func testSettingsPresentation() async throws {
        try await process(route: .settings, expectedUserSessionState: .settingsScreen)
        XCTAssertTrue((tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
    }
    
    func testRoomPresentation() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedChatsState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testRoomPresentationClearsSettings() async throws {
        try await process(route: .settings, expectedUserSessionState: .settingsScreen)
        XCTAssertTrue((tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        XCTAssertNil(detailCoordinator)
        
        try await process(route: .room(roomID: "1", via: []), expectedChatsState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertNil((tabCoordinator?.sheetCoordinator))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
    }
    
    func testChildRoomPresentation() async throws {
        try await process(route: .room(roomID: "1", via: []), expectedChatsState: .roomList(roomListSelectedRoomID: "1"))
        let detailNavigationStack = try XCTUnwrap(detailNavigationStack, "There must be a navigation stack.")
        XCTAssertTrue(detailNavigationStack.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        
        let deferred = deferFulfillment(detailNavigationStack.observe(\.stackCoordinators.count)) { $0 == 1 }
        try await process(route: .childRoom(roomID: "2", via: []))
        try await deferred.fulfill()
        XCTAssertTrue(detailNavigationStack.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNotNil(detailCoordinator)
        XCTAssertEqual(detailNavigationStack.stackCoordinators.count, 1)
        XCTAssertTrue(detailNavigationStack.stackCoordinators.first is RoomScreenCoordinator)
    }
    
    func testShareMediaRouteWithoutRoom() async throws {
        try await process(route: .settings, expectedUserSessionState: .settingsScreen)
        XCTAssertTrue((tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        XCTAssertNil(chatsSplitCoordinator?.sheetCoordinator)

        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: nil, mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await process(route: .share(sharePayload),
                          expectedUserSessionState: .tabBar,
                          expectedChatsState: .shareExtensionRoomList(sharePayload: sharePayload))
        XCTAssertNil(tabCoordinator?.sheetCoordinator)
        XCTAssertTrue((chatsSplitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomSelectionScreenCoordinator)
    }
    
    func testShareMediaRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedChatsState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNil(tabCoordinator?.sheetCoordinator)
        XCTAssertNil(chatsSplitCoordinator?.sheetCoordinator)

        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: "2", mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await process(route: .share(sharePayload),
                          expectedChatsState: .roomList(roomListSelectedRoomID: "2"))

        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNil(tabCoordinator?.sheetCoordinator)
        XCTAssertTrue((chatsSplitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
    }
    
    func testShareTextRouteWithoutRoom() async throws {
        try await process(route: .settings, expectedUserSessionState: .settingsScreen)
        XCTAssertTrue((tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        XCTAssertNil(chatsSplitCoordinator?.sheetCoordinator)

        let sharePayload: ShareExtensionPayload = .text(roomID: nil, text: "Important Text")
        try await process(route: .share(sharePayload),
                          expectedUserSessionState: .tabBar,
                          expectedChatsState: .shareExtensionRoomList(sharePayload: sharePayload))
        XCTAssertNil(tabCoordinator?.sheetCoordinator)
        XCTAssertTrue((chatsSplitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomSelectionScreenCoordinator)
    }
    
    func testShareTextRouteWithRoom() async throws {
        try await process(route: .event(eventID: "1", roomID: "1", via: []), expectedChatsState: .roomList(roomListSelectedRoomID: "1"))
        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNil(tabCoordinator?.sheetCoordinator)
        XCTAssertNil(chatsSplitCoordinator?.sheetCoordinator)

        let sharePayload: ShareExtensionPayload = .text(roomID: "2", text: "Important text")
        try await process(route: .share(sharePayload),
                          expectedChatsState: .roomList(roomListSelectedRoomID: "2"))

        XCTAssertTrue(detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        XCTAssertNil(tabCoordinator?.sheetCoordinator)
        XCTAssertNil(chatsSplitCoordinator?.sheetCoordinator, "The media upload sheet shouldn't be shown when sharing text.")
    }
    
    // MARK: - Helpers
    
    private func process(route: AppRoute,
                         expectedUserSessionState: UserSessionFlowCoordinator.State? = nil,
                         expectedChatsState: ChatsFlowCoordinatorStateMachine.State? = nil) async throws {
        let deferredUserSession: DeferredFulfillment? = if let expectedUserSessionState {
            deferFulfillment(stateMachineFactory.userSessionFlowStatePublisher.delay(for: .milliseconds(100), scheduler: DispatchQueue.main)) {
                $0 == expectedUserSessionState
            }
        } else {
            nil
        }
        
        let deferredChatsState: DeferredFulfillment? = if let expectedChatsState {
            deferFulfillment(stateMachineFactory.chatsFlowStatePublisher.delay(for: .milliseconds(100), scheduler: DispatchQueue.main)) {
                $0 == expectedChatsState
            }
        } else {
            nil
        }
        
        userSessionFlowCoordinator.handleAppRoute(route, animated: true)
        try await deferredUserSession?.fulfill()
        try await deferredChatsState?.fulfill()
    }
}
