//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite(.serialized)
struct UserSessionFlowCoordinatorTests {
    private var userSessionFlowCoordinator: UserSessionFlowCoordinator!
    private var rootCoordinator: NavigationRootCoordinator!
    private var userIndicatorController: UserIndicatorControllerMock!
    private let stateMachineFactory = PublishedStateMachineFactory()
    
    private let networkReachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never> = .init(.reachable)
    private let homeserverReachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never> = .init(.reachable)
    private var cancellables = Set<AnyCancellable>()
    
    private var tabCoordinator: NavigationTabCoordinator<UserSessionFlowCoordinator.HomeTab>? {
        rootCoordinator?.rootCoordinator as? NavigationTabCoordinator
    }

    private var chatsSplitCoordinator: NavigationSplitCoordinator? {
        tabCoordinator?.tabCoordinators.first as? NavigationSplitCoordinator
    }

    private var detailCoordinator: CoordinatorProtocol? {
        chatsSplitCoordinator?.detailCoordinator
    }

    private var detailNavigationStack: NavigationStackCoordinator? {
        detailCoordinator as? NavigationStackCoordinator
    }
    
    init() async throws {
        rootCoordinator = NavigationRootCoordinator()
        
        let clientProxy = ClientProxyMock(.init(userID: "hi@bob", roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
        clientProxy.homeserverReachabilityPublisher = homeserverReachabilitySubject.asCurrentValuePublisher()
        
        let networkMonitor = NetworkMonitorMock.default
        networkMonitor.reachabilityPublisher = networkReachabilitySubject.asCurrentValuePublisher()
        let appMediator = AppMediatorMock.default
        appMediator.networkMonitor = networkMonitor
        
        userIndicatorController = UserIndicatorControllerMock()
        
        let flowParameters = CommonFlowParameters(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  elementCallService: ElementCallServiceMock(.init()),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                  emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  appMediator: appMediator,
                                                  appSettings: ServiceLocator.shared.settings,
                                                  appHooks: AppHooks(),
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: userIndicatorController,
                                                  notificationManager: NotificationManagerMock(),
                                                  stateMachineFactory: stateMachineFactory)
        
        userSessionFlowCoordinator = UserSessionFlowCoordinator(isNewLogin: false,
                                                                navigationRootCoordinator: rootCoordinator,
                                                                appLockService: AppLockServiceMock(),
                                                                flowParameters: flowParameters)
        
        userSessionFlowCoordinator.start()
    }
    
    // MARK: Navigation
    
    @Test
    func initialState() {
        #expect(chatsSplitCoordinator != nil)
        #expect(detailCoordinator == nil)
    }
    
    @Test
    func settingsPresentation() async throws {
        var testSetup = self
        try await testSetup.process(route: .settings, expectedUserSessionState: .settingsScreen)
        #expect((testSetup.tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
    }
    
    @Test
    func roomPresentation() async throws {
        var testSetup = self
        try await testSetup.process(route: .room(roomID: "1", via: []), expectedChatsState: .roomList(detailState: .room(roomID: "1")))
        #expect(testSetup.detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.detailCoordinator != nil)
    }
    
    @Test
    func roomPresentationClearsSettings() async throws {
        var testSetup = self
        try await testSetup.process(route: .settings, expectedUserSessionState: .settingsScreen)
        #expect((testSetup.tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        #expect(testSetup.detailCoordinator == nil)
        
        try await testSetup.process(route: .room(roomID: "1", via: []), expectedChatsState: .roomList(detailState: .room(roomID: "1")))
        #expect(testSetup.tabCoordinator?.sheetCoordinator == nil)
        #expect(testSetup.detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.detailCoordinator != nil)
    }
    
    @Test
    func childRoomPresentation() async throws {
        var testSetup = self
        try await testSetup.process(route: .room(roomID: "1", via: []), expectedChatsState: .roomList(detailState: .room(roomID: "1")))
        let detailNavigationStack = try #require(testSetup.detailNavigationStack, "There must be a navigation stack.")
        #expect(detailNavigationStack.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.detailCoordinator != nil)
        
        let deferred = deferFulfillment(detailNavigationStack.observe(\.stackCoordinators.count)) { $0 == 1 }
        try await testSetup.process(route: .childRoom(roomID: "2", via: []))
        try await deferred.fulfill()
        #expect(detailNavigationStack.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.detailCoordinator != nil)
        #expect(detailNavigationStack.stackCoordinators.count == 1)
        #expect(detailNavigationStack.stackCoordinators.first is RoomScreenCoordinator)
    }
    
    @Test
    func shareMediaRouteWithoutRoom() async throws {
        var testSetup = self
        try await testSetup.process(route: .settings, expectedUserSessionState: .settingsScreen)
        #expect((testSetup.tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        #expect(testSetup.chatsSplitCoordinator?.sheetCoordinator == nil)

        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: nil, mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await testSetup.process(route: .share(sharePayload),
                                    expectedUserSessionState: .tabBar,
                                    expectedChatsState: .shareExtensionRoomList(sharePayload: sharePayload))
        #expect(testSetup.tabCoordinator?.sheetCoordinator == nil)
        #expect((testSetup.chatsSplitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomSelectionScreenCoordinator)
    }
    
    @Test
    func shareMediaRouteWithRoom() async throws {
        var testSetup = self
        try await testSetup.process(route: .event(eventID: "1", roomID: "1", via: []), expectedChatsState: .roomList(detailState: .room(roomID: "1")))
        #expect(testSetup.detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.tabCoordinator?.sheetCoordinator == nil)
        #expect(testSetup.chatsSplitCoordinator?.sheetCoordinator == nil)

        let sharePayload: ShareExtensionPayload = .mediaFiles(roomID: "2", mediaFiles: [.init(url: .picturesDirectory, suggestedName: nil)])
        try await testSetup.process(route: .share(sharePayload),
                                    expectedChatsState: .roomList(detailState: .room(roomID: "2")))

        #expect(testSetup.detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.tabCoordinator?.sheetCoordinator == nil)
        #expect((testSetup.chatsSplitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is MediaUploadPreviewScreenCoordinator)
    }
    
    @Test
    func shareTextRouteWithoutRoom() async throws {
        var testSetup = self
        try await testSetup.process(route: .settings, expectedUserSessionState: .settingsScreen)
        #expect((testSetup.tabCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is SettingsScreenCoordinator)
        #expect(testSetup.chatsSplitCoordinator?.sheetCoordinator == nil)

        let sharePayload: ShareExtensionPayload = .text(roomID: nil, text: "Important Text")
        try await testSetup.process(route: .share(sharePayload),
                                    expectedUserSessionState: .tabBar,
                                    expectedChatsState: .shareExtensionRoomList(sharePayload: sharePayload))
        #expect(testSetup.tabCoordinator?.sheetCoordinator == nil)
        #expect((testSetup.chatsSplitCoordinator?.sheetCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomSelectionScreenCoordinator)
    }
    
    @Test
    func shareTextRouteWithRoom() async throws {
        var testSetup = self
        try await testSetup.process(route: .event(eventID: "1", roomID: "1", via: []), expectedChatsState: .roomList(detailState: .room(roomID: "1")))
        #expect(testSetup.detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.tabCoordinator?.sheetCoordinator == nil)
        #expect(testSetup.chatsSplitCoordinator?.sheetCoordinator == nil)

        let sharePayload: ShareExtensionPayload = .text(roomID: "2", text: "Important text")
        try await testSetup.process(route: .share(sharePayload),
                                    expectedChatsState: .roomList(detailState: .room(roomID: "2")))

        #expect(testSetup.detailNavigationStack?.rootCoordinator is RoomScreenCoordinator)
        #expect(testSetup.tabCoordinator?.sheetCoordinator == nil)
        #expect(testSetup.chatsSplitCoordinator?.sheetCoordinator == nil, "The media upload sheet shouldn't be shown when sharing text.")
    }
    
    // MARK: Indicators
    
    @Test
    func reachabilityIndicators() async throws {
        var testSetup = self
        // Given a flow in its initial state.
        try await Task.sleep(for: .milliseconds(100))
        
        // Then no reachability indicators should be shown.
        #expect(!testSetup.userIndicatorController.submitIndicatorDelayCalled)
        #expect(testSetup.retractReachabilityIndicatorCallsCount == 1) // The initial state removes the indicator.
        
        // When the homeserver becomes unreachable.
        testSetup.homeserverReachabilitySubject.send(.unreachable)
        try await Task.sleep(for: .milliseconds(100))
        
        // Then a server unreachable indicator should be shown.
        #expect(testSetup.userIndicatorController.submitIndicatorDelayCallsCount == 1)
        #expect(testSetup.userIndicatorController.submitIndicatorDelayReceivedArguments?.indicator.title == L10n.commonServerUnreachable)
        #expect(testSetup.retractReachabilityIndicatorCallsCount == 1)
        
        // When the network also becomes unreachable.
        testSetup.networkReachabilitySubject.send(.unreachable)
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the server unreachable indicator should be replaced with an offline indicator.
        #expect(testSetup.userIndicatorController.submitIndicatorDelayCallsCount == 2)
        #expect(testSetup.userIndicatorController.submitIndicatorDelayReceivedArguments?.indicator.title == L10n.commonOffline)
        #expect(testSetup.retractReachabilityIndicatorCallsCount == 1)
        
        // When the homeserver becomes reachable again.
        testSetup.homeserverReachabilitySubject.send(.reachable)
        try await Task.sleep(for: .milliseconds(100))
        
        // Then there should still be an offline indicator (as we don't yet support air-gapped servers on iOS).
        #expect(testSetup.userIndicatorController.submitIndicatorDelayCallsCount == 3)
        #expect(testSetup.userIndicatorController.submitIndicatorDelayReceivedArguments?.indicator.title == L10n.commonOffline)
        #expect(testSetup.retractReachabilityIndicatorCallsCount == 1)
        
        // When the network becomes reachable again.
        testSetup.networkReachabilitySubject.send(.reachable)
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the indicator should be hidden now as everything is back to normal
        #expect(testSetup.userIndicatorController.submitIndicatorDelayCallsCount == 3)
        #expect(testSetup.retractReachabilityIndicatorCallsCount == 2)
    }
    
    // MARK: - Helpers
    
    private mutating func process(route: AppRoute,
                                  expectedUserSessionState: UserSessionFlowCoordinator.State? = nil,
                                  expectedChatsState: ChatsTabFlowCoordinatorStateMachine.State? = nil) async throws {
        let deferredUserSession: DeferredFulfillment<UserSessionFlowCoordinator.State>? = if let expectedUserSessionState {
            deferFulfillment(stateMachineFactory.userSessionFlowStatePublisher.delay(for: .milliseconds(100), scheduler: DispatchQueue.main)) {
                $0 == expectedUserSessionState
            }
        } else {
            nil
        }
        
        let deferredChatsState: DeferredFulfillment<ChatsTabFlowCoordinatorStateMachine.State>? = if let expectedChatsState {
            deferFulfillment(stateMachineFactory.chatsTabFlowStatePublisher.delay(for: .milliseconds(100), scheduler: DispatchQueue.main)) {
                $0 == expectedChatsState
            }
        } else {
            nil
        }
        
        userSessionFlowCoordinator.handleAppRoute(route, animated: true)
        try await deferredUserSession?.fulfill()
        try await deferredChatsState?.fulfill()
    }
    
    /// Other services retract indicators, so this filters based on the reachability ID.
    private var retractReachabilityIndicatorCallsCount: Int {
        userIndicatorController
            .retractIndicatorWithIdReceivedInvocations
            .filter { $0 == "io.element.elementx.reachability.notification" }
            .count
    }
}
