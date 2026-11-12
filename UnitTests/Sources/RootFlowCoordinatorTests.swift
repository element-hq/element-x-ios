//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import SwiftUI
import Testing

@MainActor
struct RootFlowCoordinatorTests {
    private let navigationRootCoordinator = NavigationRootCoordinator()
    private let userSessionManager: UserSessionManagerMock
    private let userSessionManagerCallbacks = PassthroughSubject<UserSessionManagerCallback, Never>()
    private let userIndicatorController = UserIndicatorControllerMock()
    private let clientProxy: ClientProxyMock
    private let elementCallManager: ElementCallManagerMock
    private let callManagerActions = PassthroughSubject<ElementCallManagerAction, Never>()
    private let roomID = "1"
    private let inviteRoomID = "someAwesomeRoomId1"
    
    private let rootFlowCoordinator: RootFlowCoordinator
    
    init() {
        clientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org",
                                            deviceID: "alice-device-id",
                                            roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded([RoomSummary].mockRooms + .mockInvites)))))
        clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.invited())
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        userSessionManager = UserSessionManagerMock(.init(sessions: [userSession],
                                                          callbacksPublisher: userSessionManagerCallbacks.eraseToAnyPublisher()))
        userSessionManager.sessionForClosure = { userID in userID == "@alice:matrix.org" ? userSession : nil }
        
        elementCallManager = ElementCallManagerMock(.init(actionsPublisher: callManagerActions.eraseToAnyPublisher()))
        let appMediator = AppMediatorMock(.init())
        (appMediator.windowManager as? WindowManagerMock)?.mainWindow = UIWindow()
        
        rootFlowCoordinator = RootFlowCoordinator(navigationRootCoordinator: navigationRootCoordinator,
                                                  userSessionManager: userSessionManager,
                                                  elementCallManager: elementCallManager,
                                                  appLockService: AppLockServiceMock(),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  appMediator: appMediator,
                                                  appSettings: .volatile(),
                                                  appHooks: AppHooks(),
                                                  analyticsService: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: userIndicatorController)
    }
    
    // MARK: Pending routes
    
    @Test("A route received before the user session flow starts is opened once it does")
    func pendingRoute() async throws {
        rootFlowCoordinator.handleAppRoute(.room(roomID: roomID, via: []), userID: "@alice:matrix.org", awaitsRoom: false, animated: false)
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        
        let splitCoordinator = try #require(chatsSplitCoordinator)
        let deferred = deferFulfillment(splitCoordinator.observe(\.detailRootCoordinatorID)) { $0 != nil }
        try await deferred.fulfill()
        #expect((splitCoordinator.detailCoordinator as? NavigationStackCoordinator)?.rootCoordinator is RoomScreenCoordinator)
    }
    
    @Test("A pending invite only waits for its room to sync once the user session flow starts")
    func pendingInvite() {
        rootFlowCoordinator.handleAppRoute(.room(roomID: inviteRoomID, via: []), userID: "@alice:matrix.org", awaitsRoom: true, animated: false)
        #expect(clientProxy.roomsToAwait.isEmpty)
        
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        #expect(clientProxy.roomsToAwait == [inviteRoomID])
    }
    
    // MARK: Routes while a flow is shown
    
    @Test("A route that needs a session is ignored when not signed in")
    func routeDuringAuthentication() async throws {
        rootFlowCoordinator.handleAppRoute(.authentication, animated: false)
        #expect(navigationRootCoordinator.rootCoordinator is NavigationStackCoordinator)
        
        rootFlowCoordinator.handleAppRoute(.room(roomID: roomID, via: []), animated: false)
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        
        let splitCoordinator = try #require(chatsSplitCoordinator)
        let deferred = deferFailure(splitCoordinator.observe(\.detailRootCoordinatorID), timeout: .seconds(1)) { $0 != nil }
        try await deferred.fulfill()
    }
    
    // MARK: Session restoration
    
    @Test("Restoring the active account's session shows its flow")
    func activeSessionRestoration() {
        userSessionManagerCallbacks.send(.didRestoreSession(userID: "@alice:matrix.org"))
        
        #expect(navigationRootCoordinator.rootCoordinator is NavigationTabCoordinator<UserSessionFlowCoordinator.HomeTab>)
    }
    
    @Test("Restoring an account that isn't active shows nothing")
    func inactiveSessionRestoration() {
        userSessionManagerCallbacks.send(.didRestoreSession(userID: "@bob:matrix.org"))
        
        #expect(navigationRootCoordinator.rootCoordinator == nil)
    }
    
    @Test("A failed restore at launch shows a toast and waits for the other accounts to restore")
    func failedRestoration() {
        // Given an account that's still restoring.
        userSessionManager.activeSession = nil
        userSessionManager.userIDs = ["@bob:matrix.org"]
        
        // When another account fails to restore.
        userSessionManagerCallbacks.send(.didRemoveAccount(userID: "@alice:matrix.org", error: .failedRestoringSession))
        
        // Then the failure is shown without leaving the launch screen.
        #expect(userIndicatorController.submitIndicatorDelayReceivedArguments?.indicator.title == "Failed logging in")
        #expect(navigationRootCoordinator.rootCoordinator == nil)
    }
    
    @Test("Authentication is shown once every account has failed to restore at launch")
    func lastFailedRestoration() {
        // Given no accounts left to restore.
        userSessionManager.activeSession = nil
        userSessionManager.userIDs = []
        
        // When the last account fails to restore.
        userSessionManagerCallbacks.send(.didRemoveAccount(userID: "@alice:matrix.org", error: .failedRestoringSession))
        
        // Then authentication is shown along with the failure.
        #expect(navigationRootCoordinator.rootCoordinator is NavigationStackCoordinator)
        #expect(userIndicatorController.submitIndicatorDelayReceivedArguments?.indicator.title == "Failed logging in")
    }
    
    // MARK: Account removal
    
    @Test("Removing the shown account switches to the next account's flow")
    func shownAccountRemoval() async throws {
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        let aliceRootCoordinator = navigationRootCoordinator.rootCoordinator
        
        let bob = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@bob:matrix.org"))))
        userSessionManager.activeSession = bob
        userSessionManager.sessionsPublisher = .init([bob])
        let deferred = deferFulfillment(rootFlowCoordinator.actionsPublisher) { action in
            guard case .closeSecondaryWindows = action else { return false }
            return true
        }
        userSessionManagerCallbacks.send(.didRemoveAccount(userID: "@alice:matrix.org", error: nil))
        try await deferred.fulfill()
        
        #expect(navigationRootCoordinator.rootCoordinator is NavigationTabCoordinator<UserSessionFlowCoordinator.HomeTab>)
        #expect(navigationRootCoordinator.rootCoordinator !== aliceRootCoordinator)
    }
    
    @Test("Removing the shown account waits while another account is still restoring")
    func shownAccountRemovalWhileRestoring() {
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        let aliceRootCoordinator = navigationRootCoordinator.rootCoordinator
        
        userSessionManager.activeSession = nil
        userSessionManager.userIDs = ["@bob:matrix.org"]
        userSessionManagerCallbacks.send(.didRemoveAccount(userID: "@alice:matrix.org", error: .remoteLogout))
        
        #expect(navigationRootCoordinator.rootCoordinator === aliceRootCoordinator)
    }
    
    @Test("Removing an account that isn't shown leaves the root untouched")
    func backgroundAccountRemoval() {
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        let rootCoordinator = navigationRootCoordinator.rootCoordinator
        
        userSessionManagerCallbacks.send(.didRemoveAccount(userID: "@bob:matrix.org", error: .remoteLogout))
        
        #expect(navigationRootCoordinator.rootCoordinator === rootCoordinator)
    }
    
    // MARK: Calls
    
    @Test("The call route asks for the call as the route's account, when it's signed in")
    func callRoute() {
        userSessionManager.userIDs = ["@alice:matrix.org", "@bob:matrix.org"]
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        
        rootFlowCoordinator.handleAppRoute(.call(roomID: roomID, isVoiceCall: false, answeredFromCallKit: true), userID: "@carol:matrix.org", awaitsRoom: false, animated: false)
        #expect(!elementCallManager.requestCallUserIDRoomIDIsVoiceCallAnsweredFromCallKitCalled)
        
        rootFlowCoordinator.handleAppRoute(.call(roomID: roomID, isVoiceCall: false, answeredFromCallKit: true), userID: "@bob:matrix.org", awaitsRoom: false, animated: false)
        #expect(elementCallManager.requestCallUserIDRoomIDIsVoiceCallAnsweredFromCallKitReceivedArguments?.userID == "@bob:matrix.org")
    }
    
    @Test("Another account's call shows above the shown account's screens, with its own session")
    func callForAnotherAccount() async {
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        let bobCallService = addBob()
        
        await waitForConfirmation { confirmation in
            bobCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            presentWebCall(userID: "@bob:matrix.org", roomID: roomID)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(navigationRootCoordinator.rootCoordinator is NavigationTabCoordinator<UserSessionFlowCoordinator.HomeTab>)
    }
    
    @Test("A call stays on screen when the shown account changes")
    func callDuringAccountChange() throws {
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        let aliceRootCoordinator = navigationRootCoordinator.rootCoordinator
        _ = addBob()
        presentWebCall(userID: "@bob:matrix.org", roomID: roomID)
        let callScreen = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        userSessionManager.activeSession = userSessionManager.session(for: "@bob:matrix.org")
        userSessionManagerCallbacks.send(.didRemoveAccount(userID: "@alice:matrix.org", error: nil))
        
        #expect(navigationRootCoordinator.rootCoordinator !== aliceRootCoordinator)
        #expect(navigationRootCoordinator.overlayCoordinator === callScreen)
    }
    
    @Test("Presenting another call replaces the call screen, whose call hangs up")
    func replaceCall() throws {
        let aliceCallService = try #require(userSessionManager.session(for: "@alice:matrix.org")?.elementCallService as? ElementCallServiceMock)
        presentWebCall(userID: "@alice:matrix.org", roomID: "1")
        let firstCallScreen = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        presentWebCall(userID: "@alice:matrix.org", roomID: "2")
        
        let secondCallScreen = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        #expect(secondCallScreen !== firstCallScreen)
        #expect(aliceCallService.tearDownCallSessionRoomIDReceivedInvocations.contains("1"))
    }
    
    @Test("Dismissing the call, or minimising it without picture in picture, takes its screen off the overlay", arguments: [false, true])
    func callScreenRemoval(isMinimizing: Bool) {
        presentWebCall(userID: "@alice:matrix.org", roomID: roomID)
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        
        callManagerActions.send(.callScreen(isMinimizing ? .minimize : .dismiss))
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
    }
    
    // MARK: - Helpers
    
    /// Signs Bob in alongside Alice, returning his call service.
    private func addBob() -> ElementCallServiceMock {
        let bobCallService = ElementCallServiceMock(.init(userID: "@bob:matrix.org"))
        let bob = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@bob:matrix.org", deviceID: "bob-device-id")),
                                        elementCallService: bobCallService))
        let alice = userSessionManager.session(for: "@alice:matrix.org")
        userSessionManager.sessionForClosure = { userID in
            switch userID {
            case "@alice:matrix.org": alice
            case "@bob:matrix.org": bob
            default: nil
            }
        }
        return bobCallService
    }
    
    private func presentWebCall(userID: String, roomID: String) {
        callManagerActions.send(.callScreen(.present(userID: userID, kind: .webView(.mock(roomID: roomID)))))
    }
    
    private var chatsSplitCoordinator: NavigationSplitCoordinator? {
        let tabCoordinator = navigationRootCoordinator.rootCoordinator as? NavigationTabCoordinator<UserSessionFlowCoordinator.HomeTab>
        return tabCoordinator?.tabCoordinators.first as? NavigationSplitCoordinator
    }
}
