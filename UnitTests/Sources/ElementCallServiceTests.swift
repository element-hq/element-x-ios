//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CallKit
import ElementCall
@testable import ElementX
import PushKit
import Testing

@MainActor
final class ElementCallServiceTests {
    private var appSettings: AppSettings!
    private var callProvider: CXProviderMock!
    private var callController: CXCallControllerMock!
    private var currentDate: Date!
    private var clock: ManualClock!
    private var pushRegistry: PKPushRegistry!
    private var service: ElementCallService!
    private var userSession: UserSessionMock!
    
    init() {
        appSettings = AppSettings.volatile()
        pushRegistry = PKPushRegistry(queue: nil)
        callProvider = CXProviderMock(.init())
        callController = CXCallControllerMock(.init())
        currentDate = Date()
        clock = ManualClock()
        let dateProvider: () -> Date = {
            self.currentDate
        }
        service = ElementCallService(appSettings: appSettings,
                                     callProvider: callProvider,
                                     callController: callController,
                                     timeProvider: TimeProvider(clock: clock, now: dateProvider))
    }
    
    isolated deinit {
        appSettings = nil
        callProvider = nil
        callController = nil
        currentDate = nil
        clock = nil
        pushRegistry = nil
        userSession = nil
    }
    
    @Test
    func incomingCall() async {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        await waitForConfirmation { confirmation in
            let pkPushPayloadMock = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
            
            service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
                confirmation()
            }
        }
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        // Verify the provider was called with a CXCallUpdate that has video enabled
        if let args = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments {
            #expect(args.update.hasVideo == true)
        } else {
            Issue.record("Expected reportNewIncomingCallWithUpdateCompletionReceivedArguments to be captured")
        }
    }
    
    @Test
    func incomingVoiceCall() async {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        await waitForConfirmation { confirmation in
            let pkPushPayloadMock = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
                .updateIsVoice(true)
            
            service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
                confirmation()
            }
        }
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        // Verify the provider was called with a CXCallUpdate that has video enabled
        if let args = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments {
            // Due to a limitation on Callkit and Webviews, we currently have to report voice calls as having video,
            // even if they are voice calls :/ If not the webview is not started and the call is not shown to the user.
            #expect(args.update.hasVideo == true)
        } else {
            Issue.record("Expected reportNewIncomingCallWithUpdateCompletionReceivedArguments to be captured")
        }
    }
    
    @Test
    func callIsTimingOut() async throws {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let (endedCalls, endedCallsContinuation) = AsyncStream<CXCallEndedReason>.makeStream()
        callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
            endedCallsContinuation.yield(reason)
        }
        let deferredEndedCall = deferFulfillment(endedCalls) { _ in true }
        
        await waitForConfirmation { confirmation in
            let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
            
            service.pushRegistry(pushRegistry,
                                 didReceiveIncomingPushWith: pushPayload,
                                 for: .voIP) {
                confirmation()
            }
        }
        
        await clock.waitForScheduledSleep()
        
        // advance past the timeout
        clock.advance(by: .seconds(30))
        
        let reason = try await deferredEndedCall.fulfill()
        #expect(reason == .unanswered, "Call should have ended as unanswered")
    }
    
    @Test
    func lifetimeIsCapped() async throws {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        let (endedCalls, endedCallsContinuation) = AsyncStream<CXCallEndedReason>.makeStream()
        callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
            endedCallsContinuation.yield(reason)
        }
        let deferredEndedCall = deferFulfillment(endedCalls, timeout: .seconds(30)) { _ in true }
        
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 300)
        
        service.pushRegistry(pushRegistry,
                             didReceiveIncomingPushWith: pushPayload,
                             for: .voIP) { }
        
        // The ring duration is capped, no matter how far away the push's expiration is.
        #expect(await clock.waitForScheduledSleep() == .seconds(90))
        
        // Advance past the max timeout but below the 300
        clock.advance(by: .seconds(100))
        
        let reason = try await deferredEndedCall.fulfill()
        #expect(reason == .unanswered, "Call should have ended as unanswered")
    }
    
    @Test
    func callIntentRawValues() {
        // Test to ensure that the implicit rawValue of the string enum matches the MSC values
        #expect(CallIntent.audio.rawValue == "audio")
        #expect(CallIntent.video.rawValue == "video")
    }
    
    @Test
    func timeoutClearsIncomingCallStateBeforeNextPush() async throws {
        // Drive push #1 to its 60s unanswered timeout
        let (endedCalls, endedCallsContinuation) = AsyncStream<CXCallEndedReason>.makeStream()
        callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
            endedCallsContinuation.yield(reason)
        }
        let deferredEndedCall = deferFulfillment(endedCalls, timeout: .seconds(30)) { $0 == .unanswered }
        
        let firstPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
        service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: firstPayload, for: .voIP) { }
        
        await clock.waitForScheduledSleep()
        clock.advance(by: .seconds(70))
        try await deferredEndedCall.fulfill()
        
        callProvider.reportCallWithEndedAtReasonClosure = nil
        let firstCallUUID = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid
        
        // Send push #2 for the same room; the previous incoming state must be cleared,
        // so the second push gets a fresh CallID.
        await waitForConfirmation { confirmation in
            let secondPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: secondPayload, for: .voIP) {
                confirmation()
            }
        }
        
        let secondCallUUID = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid
        
        #expect(firstCallUUID != nil)
        #expect(secondCallUUID != nil)
        #expect(firstCallUUID != secondCallUUID)
        
        let unansweredCount = callProvider.reportCallWithEndedAtReasonReceivedInvocations.filter { $0.reason == .unanswered }.count
        #expect(unansweredCount == 1)
    }
    
    @Test
    func setupCallSessionCancelsPendingUnansweredTimeout() async throws {
        // Schedule the 60s unanswered timer via an incoming push
        await waitForConfirmation { confirmation in
            let payload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) {
                confirmation()
            }
        }
        
        // Make sure the cancellation below exercises a scheduled timer rather than one that never started.
        await clock.waitForScheduledSleep()
        
        // Simulate the answer flow handing off to setupCallSession, which must cancel
        // the pending endUnansweredCallTask as part of clearing the incoming state.
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true)
        
        let (endedCalls, endedCallsContinuation) = AsyncStream<CXCallEndedReason>.makeStream()
        callProvider.reportCallWithEndedAtReasonClosure = { _, _, reason in
            endedCallsContinuation.yield(reason)
        }
        let deferredUnansweredCall = deferFailure(endedCalls,
                                                  timeout: .milliseconds(100),
                                                  message: "endUnansweredCallTask should have been cancelled by setupCallSession") { $0 == .unanswered }
        
        // Advance past what would have been the 60s unanswered timeout
        clock.advance(by: .seconds(120))
        
        try await deferredUnansweredCall.fulfill()
    }
    
    @Test
    func expiredPushReportsMissedCall() async {
        // An expired push is a real call we missed, so it should show up in Recents as one.
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
        currentDate = currentDate.addingTimeInterval(60)
        await expectImmediatelyEndedCallReported(forPayload: pushPayload, expectedReason: .unanswered)
        
        let update = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update
        #expect(update?.localizedCallerName == "welcome")
        #expect(update?.remoteHandle?.value == "!room:example.com")
    }
    
    @Test
    func duplicateRoomPushReportsCallAsHandled() async {
        // A duplicate push for an ongoing call is reported as handled, leaving the ongoing call alone.
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true)
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
        await expectImmediatelyEndedCallReported(forPayload: pushPayload, expectedReason: .answeredElsewhere)
        
        // The call should be named so neither the brief system UI nor the Recents entry shows "Unknown".
        let update = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update
        #expect(update?.localizedCallerName == "welcome")
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
    }
    
    @Test
    func webViewCallSessionIsNotTrackedByCallKit() async {
        // CallKit tracking a call gives this process exclusive media access, which starves the web
        // view. So a web view call is only ever tracked on the app side.
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true)
        service.reportCallSessionConnected(roomID: "!room:example.com")
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(!callProvider.reportCallWithUpdatedCalled)
        #expect(!callProvider.reportOutgoingCallWithConnectedAtCalled)
    }
    
    @Test
    func endingAReplacedCallLeavesTheCallThatReplacedItUp() async throws {
        enableNativeCalls()
        
        // Leaving a call to start one in another room requests an end call action for the first,
        // then starts the second before the system performs it.
        await service.setupCallSession(roomID: "!first:example.com", roomDisplayName: "first", isVideo: true)
        let firstCallID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        
        service.tearDownCallSession(roomID: "!first:example.com")
        await service.setupCallSession(roomID: "!second:example.com", roomDisplayName: "second", isVideo: true)
        
        var endedRooms: [String] = []
        let cancellable = service.actions.sink { action in
            if case .endCall(let roomID) = action {
                endedRooms.append(roomID)
            }
        }
        defer { cancellable.cancel() }
        
        service.endCall(withCallKitID: firstCallID)
        
        #expect(endedRooms.isEmpty, "The first call's end action must not hang up the second call")
        #expect(service.ongoingCallRoomIDPublisher.value == "!second:example.com")
        
        // And the second call still ends when it's the one the system means.
        let secondCallID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        service.endCall(withCallKitID: secondCallID)
        
        #expect(endedRooms == ["!second:example.com"])
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
    }
    
    @Test
    func tearingDownAnotherRoomLeavesTheOngoingCallUp() async {
        // A call screen that is dismissed after another room's call replaced it must not take the
        // new call down with it.
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true)
        
        service.tearDownCallSession(roomID: "!other:example.com")
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        
        service.tearDownCallSession(roomID: "!room:example.com")
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
    }
    
    // MARK: - Native calls
    
    @Test
    func nativeModeReportsVoiceCallsWithoutVideo() async {
        appSettings.nativeCallEnabled = true
        
        await reportIncomingPush(isVoiceCall: true)
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.hasVideo == false)
    }
    
    @Test
    func nativeModeStillReportsVideoCallsWithVideo() async {
        appSettings.nativeCallEnabled = true
        
        await reportIncomingPush(isVoiceCall: false)
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.hasVideo == true)
    }
    
    @Test
    func answeringInNativeModeKeepsTheCallUp() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        try await answerReportedCall()
        
        // The webview path ends the call a second after answering so that `setupCallSession` can
        // start a new one. The native stack takes this one over instead, so it has to survive.
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
    }
    
    @Test
    func answeredNativeCallEndsWhenNothingTakesItOver() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        let answeredUUID = try await answerReportedCall()
        
        let (endedCalls, endedCallsContinuation) = AsyncStream<(UUID, CXCallEndedReason)>.makeStream()
        callProvider.reportCallWithEndedAtReasonClosure = { uuid, _, reason in
            endedCallsContinuation.yield((uuid, reason))
        }
        let deferredEndedCall = deferFulfillment(endedCalls) { _ in true }
        
        // Answering swaps the unanswered timer for the watchdog that catches a hand-off that never
        // happens — the room isn't joined, there's no transport, a call is already running.
        #expect(await clock.waitForScheduledSleep() == .seconds(30))
        clock.advance(by: .seconds(30))
        
        let (uuid, reason) = try await deferredEndedCall.fulfill()
        #expect(uuid == answeredUUID)
        #expect(reason == .failed)
    }
    
    @Test
    func nativeCallStackTakesOverTheAnsweredCall() async throws {
        enableNativeCalls()
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        try await answerReportedCall()
        
        // Answering starts the watchdog, so wait for it before asserting that the hand-over stops it.
        await clock.waitForScheduledSleep()
        
        await service.setupCallSession(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true)
        
        // Taking the answered call over means keeping its identifier rather than reporting a new
        // outgoing call, which is what the update below would be part of.
        #expect(!callProvider.reportCallWithUpdatedCalled)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        
        // And the watchdog must be gone, otherwise it ends the call that was just taken over.
        #expect(!clock.hasPendingSleep, "The watchdog must not outlive the hand-over")
    }
    
    @Test
    func nativeCallStackForAnotherRoomReportsANewCall() async throws {
        enableNativeCalls()
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        let answeredUUID = try await answerReportedCall()
        
        await service.setupCallSession(roomID: "!other:example.com", roomDisplayName: "other", isVideo: true)
        
        let update = try #require(callProvider.reportCallWithUpdatedReceivedArguments)
        #expect(update.uuid != answeredUUID)
        #expect(update.update.localizedCallerName == "other")
        #expect(service.ongoingCallRoomIDPublisher.value == "!other:example.com")
        
        // Unlike a web view call, a native one is tracked by CallKit, so it gets the connected report too.
        service.reportCallSessionConnected(roomID: "!other:example.com")
        #expect(callProvider.reportOutgoingCallWithConnectedAtReceivedArguments?.uuid == update.uuid)
    }
    
    @Test
    func nativeCallStackNeedsBothTheSettingAndASession() {
        #expect(service.nativeCallController == nil)
        
        appSettings.nativeCallEnabled = true
        #expect(service.nativeCallController == nil, "The setting alone has no transport to run a call over")
        
        service.setUserSession(nativeUserSession())
        #expect(service.nativeCallController != nil)
        
        service.setUserSession(nil)
        #expect(service.nativeCallController == nil, "Signing out has to release the stack's to-device subscription")
    }
    
    @Test
    func turningTheSettingOnMidSessionBuildsTheStack() {
        service.setUserSession(nativeUserSession())
        #expect(service.nativeCallController == nil)
        
        // The transport is built on demand, so the setting takes effect without an app restart.
        appSettings.nativeCallEnabled = true
        #expect(service.nativeCallController != nil)
    }
    
    @Test
    func aNewSessionGetsANewStack() {
        appSettings.nativeCallEnabled = true
        service.setUserSession(nativeUserSession())
        let firstController = service.nativeCallController
        
        // A soft logout or a cache clear brings a new session without the sign out that drops this
        // one, and the stack is built against the client proxy it was given.
        service.setUserSession(nativeUserSession())
        
        #expect(service.nativeCallController !== firstController)
    }
    
    @Test
    func callsFallBackToTheWebViewWithoutAStack() {
        let roomProxy = JoinedRoomProxyMock(.init(id: "!room:example.com"))
        
        #expect(!service.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: false))
        
        appSettings.nativeCallEnabled = true
        service.setUserSession(nativeUserSession())
        
        #expect(service.handleNativeCallRequest(roomProxy: roomProxy, isVoiceCall: false))
    }
    
    /// Builds a session whose client proxy can serve the native call stack, and holds on to it: the
    /// service only keeps a weak reference, as the app owns the session.
    private func nativeUserSession() -> UserSessionMock {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.makeNativeCallTransportReturnValue = ElementCallFakeTransport()
        let session = UserSessionMock(.init(clientProxy: clientProxy))
        userSession = session
        return session
    }
    
    /// Puts the service in native mode, with the stack the CallKit paths check for.
    private func enableNativeCalls() {
        appSettings.nativeCallEnabled = true
        service.setUserSession(nativeUserSession())
    }
    
    /// Delivers a VoIP push and waits for it to be reported, returning once the call is ringing.
    private func reportIncomingPush(isVoiceCall: Bool) async {
        await waitForConfirmation { confirmation in
            let payload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
                .updateIsVoice(isVoiceCall)
            
            service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) {
                confirmation()
            }
        }
    }
    
    /// Answers the call the provider last reported, returning its identifier.
    @discardableResult
    private func answerReportedCall() async throws -> UUID {
        let uuid = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        let provider = CXProvider(configuration: CXProviderConfiguration())
        
        service.provider(provider, perform: CXAnswerCallAction(call: uuid))
        
        return uuid
    }
    
    private func expectImmediatelyEndedCallReported(forPayload payload: PKPushPayloadMock,
                                                    expectedReason: CXCallEndedReason) async {
        let baselineNewIncomingCount = callProvider.reportNewIncomingCallWithUpdateCompletionCallsCount
        let baselineEndedCount = callProvider.reportCallWithEndedAtReasonCallsCount
        
        await waitForConfirmation { confirmation in
            service.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) {
                confirmation()
            }
        }
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionCallsCount == baselineNewIncomingCount + 1)
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == baselineEndedCount + 1)
        
        let reportedCall = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments
        let endedCall = callProvider.reportCallWithEndedAtReasonReceivedArguments
        #expect(reportedCall?.uuid == endedCall?.uuid)
        #expect(endedCall?.reason == expectedReason)
    }
}

private nonisolated class PKPushPayloadMock: PKPushPayload {
    var dict: [AnyHashable: Any] = [:]
    
    override init() {
        dict[ElementCallServiceNotificationKey.roomID.rawValue] = "!room:example.com"
        dict[ElementCallServiceNotificationKey.roomDisplayName.rawValue] = "welcome"
        dict[ElementCallServiceNotificationKey.rtcNotifyEventID.rawValue] = "$000"
        dict[ElementCallServiceNotificationKey.expirationDate.rawValue] = Date(timeIntervalSince1970: 10)
    }
    
    override var dictionaryPayload: [AnyHashable: Any] {
        dict
    }
    
    func updatingExpiration(_ from: Date, lifetime: TimeInterval) -> Self {
        dict[ElementCallServiceNotificationKey.expirationDate.rawValue] = from.addingTimeInterval(lifetime)
        return self
    }
    
    func updateIsVoice(_ isVoice: Bool) -> Self {
        dict[ElementCallServiceNotificationKey.isVoiceCall.rawValue] = isVoice
        return self
    }
}
