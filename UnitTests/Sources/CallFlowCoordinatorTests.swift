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
struct CallFlowCoordinatorTests {
    private let navigationRootCoordinator = NavigationRootCoordinator()
    private let clientProxy: ClientProxyMock
    private let aliceSession: UserSessionMock
    private let sessionsSubject: CurrentValueSubject<[UserSessionProtocol], Never>
    private let userSessionManager: UserSessionManagerMock
    private let elementCallService = ElementCallServiceMock(.init())
    private let elementCallManager = ElementCallManagerMock()
    private let callFlowCoordinator: CallFlowCoordinator
    
    init() {
        clientProxy = makeAliceClientProxy()
        aliceSession = makeAliceSession(clientProxy: clientProxy)
        sessionsSubject = .init([aliceSession])
        userSessionManager = UserSessionManagerMock(.init(userSessions: sessionsSubject))
        
        let windowManager = WindowManagerMock()
        windowManager.mainWindow = UIWindow()
        
        callFlowCoordinator = CallFlowCoordinator(parameters: .init(navigationRootCoordinator: navigationRootCoordinator,
                                                                    userSessionManager: userSessionManager,
                                                                    elementCallService: elementCallService,
                                                                    elementCallManager: elementCallManager,
                                                                    windowManager: windowManager,
                                                                    analytics: AnalyticsServiceMock(.init())))
        callFlowCoordinator.start()
    }
    
    @Test
    func webCallOpensOnRootOverlay() async {
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(elementCallService.handleNativeCallRequestRoomProxyIsVoiceCallCallsCount == 1)
    }
    
    @Test
    func sameCallKeepsScreen() throws {
        callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        
        #expect(navigationRootCoordinator.overlayCoordinator === first)
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
    }
    
    @Test
    func otherCallReplacesCurrent() throws {
        callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        
        callFlowCoordinator.presentCall(roomProxy: room("2"), isVoiceCall: false, userSession: aliceSession)
        
        #expect(navigationRootCoordinator.overlayCoordinator !== first)
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(elementCallService.tearDownCallSessionRoomIDReceivedInvocations == ["1"])
    }
    
    @Test
    func replacedCallCannotCloseReplacement() async throws {
        let firstRoom = room("1")
        let firstWidgetDriver = try #require(firstRoom.elementCallWidgetDriverDeviceIDReturnValue as? ElementCallWidgetDriverMock)
        let firstWidgetActions = PassthroughSubject<ElementCallWidgetDriverAction, Never>()
        firstWidgetDriver.actions = firstWidgetActions.eraseToAnyPublisher()
        
        callFlowCoordinator.presentCall(roomProxy: firstRoom, isVoiceCall: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        callFlowCoordinator.presentCall(roomProxy: room("2"), isVoiceCall: false, userSession: aliceSession)
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
    
    @Test
    func callClosedElsewhereOpensAgain() throws {
        callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        let first = try #require(navigationRootCoordinator.overlayCoordinator as? CallScreenCoordinator)
        navigationRootCoordinator.setOverlayCoordinator(nil)
        
        callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(navigationRootCoordinator.overlayCoordinator !== first)
    }
    
    @Test
    func minimizeWithoutPictureInPictureEndsCall() {
        callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        
        callFlowCoordinator.minimizeCall()
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(elementCallService.tearDownCallSessionRoomIDReceivedRoomID == "1")
    }
    
    @Test(arguments: [true, false])
    func callOpensWithAccountSession(isAnswered: Bool) async {
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: isAnswered)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.roomID == "1")
        #expect(!elementCallManager.dropAnsweredCallRoomIDCalled)
    }
    
    @Test(arguments: [true, false])
    func signedOutAccountCallIsDropped(isAnswered: Bool) {
        userSessionManager.userIDs = []
        
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: isAnswered)
        
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(elementCallManager.dropAnsweredCallRoomIDCalled == isAnswered)
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
        #expect(!userSessionManager.sessionForCalled, "An account that isn't signed in has no session to wait for")
    }
    
    @Test
    func unjoinedRoomCallIsDropped() async {
        await waitForConfirmation { confirmation in
            elementCallManager.dropAnsweredCallRoomIDClosure = { _ in confirmation() }
            callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "!unknown:matrix.org", isVoiceCall: false, isAnswered: true)
        }
        
        #expect(elementCallManager.dropAnsweredCallRoomIDReceivedRoomID == "!unknown:matrix.org")
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
    }
    
    @Test
    func pendingCallOpensWithSession() async {
        sessionsSubject.send([])
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: true)
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            sessionsSubject.send([aliceSession])
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
    }
    
    @Test
    func pendingCallWaitsForSessionSetup() async {
        sessionsSubject.send([])
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: true)
        
        await waitForConfirmation { confirmation in
            elementCallService.handleNativeCallRequestRoomProxyIsVoiceCallClosure = { _, _ in
                confirmation()
                return true
            }
            sessionsSubject.send([aliceSession])
            #expect(!elementCallService.handleNativeCallRequestRoomProxyIsVoiceCallCalled, "AppCoordinator builds the session's native stack right after adding it")
        }
        
        #expect(!(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator))
    }
    
    @Test
    func pendingCallIsRecheckedOnOpen() async {
        // Given a call held until its account's session is live.
        sessionsSubject.send([])
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: true)
        
        // When the account signs out as its session appears, then the call is dropped.
        await waitForConfirmation { confirmation in
            elementCallManager.dropAnsweredCallRoomIDClosure = { _ in confirmation() }
            sessionsSubject.send([aliceSession])
            userSessionManager.userIDs = []
        }
        
        #expect(elementCallManager.dropAnsweredCallRoomIDReceivedRoomID == "1")
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
    }
    
    @Test
    func newerPendingCallDropsOlder() async {
        sessionsSubject.send([])
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: true)
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "2", isVoiceCall: false, isAnswered: true)
        
        #expect(elementCallManager.dropAnsweredCallRoomIDReceivedInvocations == ["1"])
        
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            sessionsSubject.send([aliceSession])
        }
        
        #expect(elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindReceivedArguments?.roomID == "2")
    }
    
    @Test
    func webCallEndsOnlyWithItsAccount() async {
        // Given Alice's web call, which outlives a change of root.
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            callFlowCoordinator.presentCall(roomProxy: room("1"), isVoiceCall: false, userSession: aliceSession)
        }
        
        navigationRootCoordinator.setRootCoordinator(PlaceholderScreenCoordinator(hideBrandChrome: false))
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        #expect(!elementCallService.tearDownCallSessionRoomIDCalled)
        
        // When another account ends its calls, then Alice's call stays.
        await callFlowCoordinator.endCalls(userID: "@bob:matrix.org")
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
        
        // When Alice's account ends its calls, then hers ends.
        await callFlowCoordinator.endCalls(userID: "@alice:matrix.org")
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        #expect(elementCallService.tearDownCallSessionRoomIDReceivedRoomID == "1", "A call left ongoing would make every later call count as busy")
    }
    
    @Test
    func blockedAccountDropsCallsUntilSessionChange() async {
        await callFlowCoordinator.endCalls(userID: "@alice:matrix.org")
        
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: false)
        #expect(!elementCallManager.dropAnsweredCallRoomIDCalled)
        #expect(navigationRootCoordinator.overlayCoordinator == nil)
        
        sessionsSubject.send([aliceSession])
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: true)
        #expect(elementCallManager.dropAnsweredCallRoomIDReceivedInvocations == ["1"])
        
        await waitForConfirmation { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            sessionsSubject.send([makeAliceSession()])
            callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: true)
        }
        
        #expect(navigationRootCoordinator.overlayCoordinator is CallScreenCoordinator)
    }
    
    @Test
    func endCallsDropsPendingCall() async {
        sessionsSubject.send([])
        callFlowCoordinator.presentCall(userID: "@alice:matrix.org", roomID: "1", isVoiceCall: false, isAnswered: true)
        
        await callFlowCoordinator.endCalls(userID: "@alice:matrix.org")
        
        #expect(elementCallManager.dropAnsweredCallRoomIDReceivedRoomID == "1")
        
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(500)) { confirmation in
            elementCallService.setupCallSessionRoomIDRoomDisplayNameIsVideoKindClosure = { _, _, _, _ in confirmation() }
            sessionsSubject.send([aliceSession])
        }
    }
    
    // MARK: - Helpers
    
    private func room(_ id: String) -> JoinedRoomProxyMock {
        JoinedRoomProxyMock(.init(id: id))
    }
}

private func makeAliceClientProxy() -> ClientProxyMock {
    ClientProxyMock(.init(userID: "@alice:matrix.org",
                          deviceID: "alice-device",
                          roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))))
}

private func makeAliceSession(clientProxy: ClientProxyMock = makeAliceClientProxy()) -> UserSessionMock {
    UserSessionMock(.init(clientProxy: clientProxy))
}
