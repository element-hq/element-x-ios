//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall
@testable import ElementX
import SwiftUI
import Testing

struct RootFlowCoordinatorCallTests {
    private let alice = "@alice:matrix.org"
    private let navigationRootCoordinator = NavigationRootCoordinator()
    private let elementCallService = ElementCallServiceMock(.init())
    private let aliceSession: UserSessionMock
    private let sessionsSubject: CurrentValueSubject<[UserSessionProtocol], Never>
    private let userSessionManager: UserSessionManagerMock
    private let elementCallManager = ElementCallManagerMock()
    private let appSettings: AppSettings
    private let rootFlowCoordinator: RootFlowCoordinator
    
    init() {
        aliceSession = UserSessionMock(.init(clientProxy: makeClientProxy(userID: alice), elementCallService: elementCallService))
        sessionsSubject = .init([aliceSession])
        userSessionManager = UserSessionManagerMock(.init(userSessions: sessionsSubject))
        
        let appMediator = AppMediatorMock(.init())
        (appMediator.windowManager as? WindowManagerMock)?.mainWindow = UIWindow()
        
        appSettings = AppSettings.volatile()
        // Skips loading the Classic app's accounts when an authentication flow starts.
        appSettings.hasSignedInBefore = true
        
        rootFlowCoordinator = RootFlowCoordinator(navigationRootCoordinator: navigationRootCoordinator,
                                                  userSessionManager: userSessionManager,
                                                  elementCallManager: elementCallManager,
                                                  appLockService: AppLockServiceMock(),
                                                  bugReportService: BugReportServiceMock(.init()),
                                                  appMediator: appMediator,
                                                  appSettings: appSettings,
                                                  appHooks: AppHooks(),
                                                  analyticsService: AnalyticsServiceMock(.init()),
                                                  userIndicatorController: UserIndicatorControllerMock())
    }
    
    // MARK: - Web calls
    
    @Test("A web call opens on the root overlay, after asking its account's service for a native call")
    func webCallOpensOnRootOverlay() async {
        await presentWebCall(roomID: "1")
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(elementCallService.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitCallsCount == 1)
    }
    
    @Test("With native calls on, a call without a native stack is dropped instead of opening the web view")
    func callWithoutNativeStackIsDropped() {
        appSettings.nativeCallEnabled = true
        let userSession = UserSessionMock(.init(clientProxy: aliceSession.clientProxy,
                                                userSettings: appSettings.userSettings(for: alice),
                                                elementCallService: elementCallService))
        
        rootFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, answeredFromCallKit: true, userSession: userSession)
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedArguments?.userID == alice)
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedArguments?.roomID == "1")
    }
    
    @Test("Presenting the ongoing call again keeps its screen")
    func sameCallKeepsScreen() throws {
        rootFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        rootFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        
        #expect(navigationRootCoordinator.overlayCoordinator === first)
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
    }
    
    @Test("A call in another room replaces the current one and ends it")
    func otherCallReplacesCurrent() throws {
        rootFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        rootFlowCoordinator.presentCall(roomProxy: room("2"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        
        #expect(navigationRootCoordinator.overlayCoordinator !== first)
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(elementCallService.tearDownCallSessionRoomIDReceivedInvocations == ["1"])
    }
    
    @Test("A replaced call's late end leaves the call that replaced it open")
    func replacedCallCannotCloseReplacement() async throws {
        let firstRoom = room("1")
        let firstWidgetDriver = try #require(firstRoom.elementCallWidgetDriverDeviceIDReturnValue as? ElementCallWidgetDriverMock)
        let firstWidgetActions = PassthroughSubject<ElementCallWidgetDriverAction, Never>()
        firstWidgetDriver.actions = firstWidgetActions.eraseToAnyPublisher()
        
        rootFlowCoordinator.presentCall(roomProxy: firstRoom, isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        rootFlowCoordinator.presentCall(roomProxy: room("2"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        let second = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(500)) { confirmation in
            elementCallService.tearDownCallSessionRoomIDClosure = { _ in confirmation() }
            firstWidgetActions.send(.callEnded)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator === second)
        #expect(elementCallService.tearDownCallSessionRoomIDReceivedInvocations == ["1"])
        // The replaced screen has to outlive the wait, or its late dismiss never fires.
        withExtendedLifetime(first) { }
    }
    
    @Test("A call whose screen was closed elsewhere opens a new screen")
    func callClosedElsewhereOpensAgain() throws {
        rootFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        navigationRootCoordinator.setOverlayCoordinator(nil)
        
        rootFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(navigationRootCoordinator.overlayCoordinator !== first)
    }
    
    @Test("Minimizing a web call without picture in picture ends it")
    func minimizeWithoutPictureInPictureEndsCall() {
        rootFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        
        rootFlowCoordinator.minimizeCall()
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(elementCallService.tearDownCallSessionRoomIDReceivedRoomID == "1")
    }
    
    @Test("A web call stays on screen when the root changes")
    func webCallSurvivesRootChange() async throws {
        await presentWebCall(roomID: "1")
        let callScreen = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        navigationRootCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(hideBrandChrome: false))
        
        #expect(navigationRootCoordinator.overlayCoordinator === callScreen)
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
    }
    
    // MARK: - Calls by account
    
    @Test("A call by account opens with that account's session", arguments: [true, false])
    func callOpensWithAccountSession(answeredFromCallKit: Bool) async {
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            routeCall(roomID: "1", userID: alice, answeredFromCallKit: answeredFromCallKit)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.roomID == "1")
        #expect(!elementCallManager.dropAnsweredCallUserIDRoomIDCalled)
    }
    
    @Test("A call for an account that isn't signed in is dropped", arguments: [true, false])
    func signedOutAccountCallIsDropped(answeredFromCallKit: Bool) {
        userSessionManager.userIDs = []
        
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: answeredFromCallKit)
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDCalled == answeredFromCallKit)
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
        #expect(!userSessionManager.sessionForCalled, "An account that isn't signed in has no session to wait for")
    }
    
    @Test("An answered call in a room that isn't joined is dropped for its account")
    func unjoinedRoomCallIsDropped() async {
        await waitForConfirmation { confirmation in
            elementCallManager.dropAnsweredCallUserIDRoomIDClosure = { _, _ in confirmation() }
            routeCall(roomID: "!unknown:matrix.org", userID: alice, answeredFromCallKit: true)
        }
        
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedArguments?.userID == alice)
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedArguments?.roomID == "!unknown:matrix.org")
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
    }
    
    @Test("A call held for its account opens once the account's session is live")
    func pendingCallOpensWithSession() async {
        sessionsSubject.send([])
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            sessionsSubject.send([aliceSession])
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
    }
    
    @Test("A held call answered through CallKit reaches the native stack as answered")
    func pendingCallStaysAnswered() async {
        sessionsSubject.send([])
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        
        await waitForConfirmation { confirmation in
            elementCallService.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitClosure = { _, _, answeredFromCallKit in
                #expect(answeredFromCallKit, "The native stack takes over the call answered through CallKit")
                confirmation()
                return true
            }
            sessionsSubject.send([aliceSession])
        }
        
        #expect(!(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator))
    }
    
    @Test("A held call is checked again when it opens")
    func pendingCallIsRecheckedOnOpen() async {
        // Given a call held until its account's session is live.
        sessionsSubject.send([])
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        
        // When the account signs out as its session appears, then the call is dropped.
        await waitForConfirmation { confirmation in
            elementCallManager.dropAnsweredCallUserIDRoomIDClosure = { _, _ in confirmation() }
            sessionsSubject.send([aliceSession])
            userSessionManager.userIDs = []
        }
        
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedArguments?.roomID == "1")
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
    }
    
    @Test("A newer held call drops the older one")
    func newerPendingCallDropsOlder() async {
        sessionsSubject.send([])
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        routeCall(roomID: "2", userID: alice, answeredFromCallKit: true)
        
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedInvocations.map(\.roomID) == ["1"])
        
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            sessionsSubject.send([aliceSession])
        }
        
        #expect(elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.roomID == "2")
    }
    
    @Test("A held call is dropped when its account is removed")
    func pendingCallDroppedWithAccount() {
        sessionsSubject.send([])
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        
        userSessionManager.userIDs = []
        sessionsSubject.send([])
        
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedInvocations.map(\.roomID) == ["1"])
    }
    
    @Test("A call that opens drops the held one")
    func openedCallDropsPendingCall() {
        sessionsSubject.send([])
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        
        rootFlowCoordinator.presentCall(roomProxy: room("2"), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedInvocations.map(\.roomID) == ["1"])
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
    }
    
    // MARK: - Leaving accounts
    
    @Test("Signing out closes the active account's web call")
    func signingOutClosesWebCall() async {
        startAliceFlow()
        await presentWebCall(roomID: "1")
        
        rootFlowCoordinator.handleAppRoute(.authentication, animated: false)
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(elementCallService.tearDownCallSessionRoomIDReceivedRoomID == "1", "A call left ongoing would make every later call count as busy")
    }
    
    @Test("Another account's web call stays when the active account signs out")
    func otherAccountWebCallSurvivesSignOut() async {
        let bob = "@bob:matrix.org"
        let bobService = ElementCallServiceMock(.init(userID: bob))
        let bobSession = UserSessionMock(.init(clientProxy: makeClientProxy(userID: bob), elementCallService: bobService))
        sessionsSubject.send([aliceSession, bobSession])
        userSessionManager.userIDs = [alice, bob]
        startAliceFlow()
        
        await waitForConfirmation { confirmation in
            bobService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            routeCall(roomID: "1", userID: bob, answeredFromCallKit: false)
        }
        
        rootFlowCoordinator.handleAppRoute(.authentication, animated: false)
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(!bobService.tearDownCallSessionRoomIDCalled)
    }
    
    @Test("A signing out account's calls are dropped until a user session flow starts again")
    func leavingAccountCallsAreDropped() async {
        startAliceFlow()
        rootFlowCoordinator.handleAppRoute(.authentication, animated: false)
        
        routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        #expect(elementCallManager.dropAnsweredCallUserIDRoomIDReceivedInvocations.map(\.roomID) == ["1"])
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
    }
    
    @Test("A call is dropped when its account signs out while its room loads")
    func callDroppedWhenAccountLeavesWhileRoomLoads() async throws {
        startAliceFlow()
        let clientProxy = try #require(aliceSession.clientProxy as? ClientProxyMock)
        clientProxy.roomForIdentifierClosure = { [rootFlowCoordinator] roomID in
            rootFlowCoordinator.handleAppRoute(.authentication, animated: false)
            return .joined(JoinedRoomProxyMock(.init(id: roomID)))
        }
        
        await waitForConfirmation { confirmation in
            elementCallManager.dropAnsweredCallUserIDRoomIDClosure = { _, _ in confirmation() }
            routeCall(roomID: "1", userID: alice, answeredFromCallKit: true)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(!elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindCalled)
    }
    
    @Test("Leaving the user session flow closes the native call screen at once")
    func leavingFlowClosesNativeCallScreen() throws {
        // Given a native call screen for the active account, whose stack is up.
        appSettings.nativeCallEnabled = true
        let clientProxy = makeClientProxy(userID: alice)
        clientProxy.makeNativeCallBackendReturnValue = ElementCallFakeMatrixBackend()
        let userSettings = appSettings.userSettings(for: alice)
        let service = ElementCallService(clientProxy: clientProxy, mediaProvider: MediaProviderMock(.init()), userSettings: userSettings)
        userSessionManager.activeSession = UserSessionMock(.init(clientProxy: clientProxy, userSettings: userSettings, elementCallService: service))
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
        let controller = try #require(service.nativeCallController)
        navigationRootCoordinator.setOverlayCoordinator(NativeCallScreenCoordinator(parameters: .init(controller: controller)))
        
        // When the account signs out, then the screen goes with the stack, without waiting for the service's dismiss.
        rootFlowCoordinator.handleAppRoute(.authentication, animated: false)
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(service.nativeCallController == nil)
    }
    
    // MARK: - Helpers
    
    private func presentWebCall(roomID: String) async {
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            rootFlowCoordinator.presentCall(roomProxy: room(roomID), isVoiceCall: false, answeredFromCallKit: false, userSession: aliceSession)
        }
    }
    
    private func routeCall(roomID: String, userID: String, answeredFromCallKit: Bool) {
        rootFlowCoordinator.handleAppRoute(.call(roomID: roomID, isVoiceCall: false, answeredFromCallKit: answeredFromCallKit),
                                           userID: userID,
                                           awaitsRoom: false,
                                           animated: false)
    }
    
    private func startAliceFlow() {
        userSessionManager.activeSession = aliceSession
        rootFlowCoordinator.handleAppRoute(.roomList, animated: false)
    }
    
    private func room(_ id: String) -> JoinedRoomProxyMock {
        JoinedRoomProxyMock(.init(id: id))
    }
}

private func makeClientProxy(userID: String) -> ClientProxyMock {
    ClientProxyMock(.init(userID: userID,
                          deviceID: "\(userID)-device",
                          roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
}
