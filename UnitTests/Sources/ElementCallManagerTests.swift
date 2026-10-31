//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import CallKit
import Combine
@testable import ElementX
import PushKit
import Testing

@MainActor
final class ElementCallManagerTests {
    private var appSettings: AppSettings!
    private var callProvider: CXProviderMock!
    private var callController: CXCallControllerMock!
    private var currentDate: Date!
    private var clock: ManualClock!
    private var pushRegistry: PKPushRegistry!
    private var service: ElementCallServiceMock!
    private var serviceActions: PassthroughSubject<ElementCallServiceAction, Never>!
    private var manager: ElementCallManager!
    
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
        serviceActions = .init()
        service = ElementCallServiceMock(.init(userID: "@alice:matrix.org"))
        service.actionsPublisher = serviceActions.eraseToAnyPublisher()
        manager = ElementCallManager(appSettings: appSettings,
                                     callProvider: callProvider,
                                     callController: callController,
                                     timeProvider: TimeProvider(clock: clock, now: dateProvider))
        manager.add(service)
    }
    
    isolated deinit {
        appSettings = nil
        callProvider = nil
        callController = nil
        currentDate = nil
        clock = nil
        pushRegistry = nil
    }
    
    @Test
    func incomingCall() async throws {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        let deferredReport = deferFulfillment(manager.actionsPublisher) { $0 == .incomingCallReported }
        
        await waitForConfirmation { confirmation in
            let pkPushPayloadMock = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
            
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
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
        try await deferredReport.fulfill()
    }
    
    @Test
    func incomingVoiceCall() async {
        #expect(!callProvider.reportNewIncomingCallWithUpdateCompletionCalled)
        
        await waitForConfirmation { confirmation in
            let pkPushPayloadMock = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
                .updateIsVoice(true)
            
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: pkPushPayloadMock, for: .voIP) {
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
            
            manager.pushRegistry(pushRegistry,
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
        
        manager.pushRegistry(pushRegistry,
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
        manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: firstPayload, for: .voIP) { }
        
        await clock.waitForScheduledSleep()
        clock.advance(by: .seconds(70))
        try await deferredEndedCall.fulfill()
        
        callProvider.reportCallWithEndedAtReasonClosure = nil
        let firstCallUUID = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid
        
        // Send push #2 for the same room; the previous incoming state must be cleared,
        // so the second push gets a fresh CallID.
        await waitForConfirmation { confirmation in
            let secondPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: secondPayload, for: .voIP) {
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
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) {
                confirmation()
            }
        }
        
        // Make sure the cancellation below exercises a scheduled timer rather than one that never started.
        await clock.waitForScheduledSleep()
        
        // Simulate the answer flow handing off to setupCallSession, which must cancel
        // the pending endUnansweredCallTask as part of clearing the incoming state.
        await startCallSession(kind: .webView)
        
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
    func expiredPushReportsMissedCall() async throws {
        // An expired push is a real call we missed, so it should show up in Recents as one.
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 20)
        currentDate = currentDate.addingTimeInterval(60)
        let deferredReport = deferFailure(manager.actionsPublisher, timeout: .milliseconds(100)) { $0 == .incomingCallReported }
        await expectImmediatelyEndedCallReported(forPayload: pushPayload, expectedReason: .unanswered)
        
        let update = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update
        #expect(update?.localizedCallerName == "welcome")
        #expect(update?.remoteHandle?.value == "!room:example.com")
        try await deferredReport.fulfill()
        
        await Task.yield()
        #expect(!service.observeIncomingCallRoomIDRtcNotificationIDCalled)
    }
    
    @Test
    func duplicateRoomPushReportsCallAsHandled() async {
        // A duplicate push for an ongoing call is reported as handled, leaving the ongoing call alone.
        await startCallSession(kind: .webView)
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
        await startCallSession(kind: .webView)
        serviceActions.send(.callSessionConnected(roomID: "!room:example.com"))
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(!callProvider.reportCallWithUpdatedCalled)
        #expect(!callProvider.reportOutgoingCallWithConnectedAtCalled)
    }
    
    @Test
    func endingAReplacedCallLeavesTheCallThatReplacedItUp() async throws {
        appSettings.nativeCallEnabled = true
        
        // Leaving a call to start one in another room requests an end call action for the first,
        // then starts the second before the system performs it.
        await startCallSession(roomID: "!first:example.com", roomDisplayName: "first", kind: .native)
        let firstCallID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        
        serviceActions.send(.callSessionEnded(roomID: "!first:example.com", reason: nil))
        await startCallSession(roomID: "!second:example.com", roomDisplayName: "second", kind: .native)
        
        manager.endCall(withCallKitID: firstCallID)
        
        #expect(service.systemEventReceivedReceivedInvocations.isEmpty, "The first call's end action must not hang up the second call")
        #expect(service.ongoingCallRoomIDPublisher.value == "!second:example.com")
        
        // And the second call still ends when it's the one the system means.
        let secondCallID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        manager.endCall(withCallKitID: secondCallID)
        
        #expect(service.systemEventReceivedReceivedInvocations == [.endCallRequested(roomID: "!second:example.com")])
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 2)
    }
    
    /// A declined or unanswered call is the system's to log as such: reported with its reason, and
    /// never as an end call action, which would log it as one we hung up.
    @Test(arguments: [(CallEndReason.remoteEnded, CXCallEndedReason.remoteEnded),
                      (.unanswered, .unanswered),
                      (.failed, .failed)])
    func aCallThatEndedWithoutUsIsReportedRatherThanEnded(reason: CallEndReason, callKitReason: CXCallEndedReason) async throws {
        appSettings.nativeCallEnabled = true
        await startCallSession(kind: .native)
        let callID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        let requestsBeforeTheEnd = callController.requestCompletionCallsCount
        
        serviceActions.send(.callSessionEnded(roomID: "!other:example.com", reason: reason))
        #expect(!callProvider.reportCallWithEndedAtReasonCalled, "Another room's end is not this call's")
        
        serviceActions.send(.callSessionEnded(roomID: "!room:example.com", reason: reason))
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == callID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == callKitReason)
        #expect(callController.requestCompletionCallsCount == requestsBeforeTheEnd)
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
    }
    
    @Test
    func tearingDownAnotherRoomLeavesTheOngoingCallUp() async {
        // A call screen that is dismissed after another room's call replaced it must not take the
        // new call down with it.
        await startCallSession(kind: .webView)
        
        serviceActions.send(.callSessionEnded(roomID: "!other:example.com", reason: nil))
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        
        serviceActions.send(.callSessionEnded(roomID: "!room:example.com", reason: nil))
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
    }
    
    // MARK: - Busy
    
    @Test
    func aCallWhileAnotherRingsIsReportedAsMissed() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        let otherCall = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            .updatingRoomID("!other:example.com")
            .updatingRTCNotificationID("$111")
        await expectImmediatelyEndedCallReported(forPayload: otherCall, expectedReason: .unanswered)
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.uuid == ringingUUID })
    }
    
    @Test
    func aCallDuringAWebViewCallIsReportedAsMissed() async {
        await startCallSession(kind: .webView)
        
        let otherCall = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            .updatingRoomID("!other:example.com")
        await expectImmediatelyEndedCallReported(forPayload: otherCall, expectedReason: .unanswered)
    }
    
    @Test
    func aCallDuringANativeCallStillRings() async {
        // An ongoing native call is tracked by CallKit, which offers its own call waiting.
        appSettings.nativeCallEnabled = true
        await startCallSession(kind: .native)
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com")
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
    }
    
    @Test
    func theSameRingPushedTwiceIsReportedAsHandled() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        await expectImmediatelyEndedCallReported(forPayload: PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60),
                                                 expectedReason: .answeredElsewhere)
        
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.uuid == ringingUUID })
    }
    
    @Test
    func anAnsweredCallThatNeverOpensStopsBlockingNewCalls() async throws {
        await reportIncomingPush(isVoiceCall: false)
        try await answerReportedCall()
        
        // The call screen couldn't open, e.g. because the room isn't joined.
        serviceActions.send(.callSessionEnded(roomID: "!room:example.com", reason: nil))
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    @Test
    func aCallAfterADroppedAnsweredCallStillTimesOut() async throws {
        await reportIncomingPush(isVoiceCall: false)
        try await answerReportedCall()
        serviceActions.send(.callSessionEnded(roomID: "!room:example.com", reason: nil))
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com")
        let newCallUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        await clock.waitForScheduledSleep()
        
        let (endedCalls, endedCallsContinuation) = AsyncStream<(UUID, CXCallEndedReason)>.makeStream()
        callProvider.reportCallWithEndedAtReasonClosure = { uuid, _, reason in
            endedCallsContinuation.yield((uuid, reason))
        }
        let deferredTimeout = deferFulfillment(endedCalls) { $0 == newCallUUID && $1 == .unanswered }
        
        // The answer hands over to the web view a second later, which must leave the new call's timeout alone.
        try await Task.sleep(for: .seconds(1.5))
        clock.advance(by: .seconds(70))
        
        try await deferredTimeout.fulfill()
    }
    
    @Test
    func unopenedAnsweredCallIsDropped() async throws {
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        try await answerReportedCall()
        
        // Nothing opens the call, e.g. it was answered while signed out.
        #expect(await clock.waitForScheduledSleep() == .seconds(30))
        await waitForConfirmation("The dropped call stops being watched") { confirmation in
            service.stopObservingIncomingCallClosure = { confirmation() }
            clock.advance(by: .seconds(30))
        }
        service.stopObservingIncomingCallClosure = nil
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    @Test
    func droppedAnsweredCallUnblocksNewCalls() async throws {
        await reportIncomingPush(isVoiceCall: false)
        try await answerReportedCall()
        
        manager.dropAnsweredCall(userID: "@alice:matrix.org", roomID: "!room:example.com")
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
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
        let deferredAnswer = deferFulfillment(manager.actionsPublisher) { $0 == .callAnswered(userID: "@alice:matrix.org", roomID: "!room:example.com", isVoiceCall: false) }
        
        try await answerReportedCall()
        try await deferredAnswer.fulfill()
        
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
    func droppedAnsweredNativeCallEndsAsFailed() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        let answeredUUID = try await answerReportedCall()
        
        manager.dropAnsweredCall(userID: "@alice:matrix.org", roomID: "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        
        manager.dropAnsweredCall(userID: "@alice:matrix.org", roomID: "!room:example.com")
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
    }
    
    @Test
    func nativeCallStackTakesOverTheAnsweredCall() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        try await answerReportedCall()
        
        // Answering starts the watchdog, so wait for it before asserting that the hand-over stops it.
        await clock.waitForScheduledSleep()
        
        await startCallSession(kind: .native)
        
        // Taking the answered call over means keeping its identifier rather than reporting a new
        // outgoing call, which is what the update below would be part of.
        #expect(!callProvider.reportCallWithUpdatedCalled)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
        
        // And the watchdog must be gone, otherwise it ends the call that was just taken over.
        #expect(!clock.hasPendingSleep, "The watchdog must not outlive the hand-over")
    }
    
    @Test
    func nativeCallStackForAnotherRoomReportsANewCall() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        let answeredUUID = try await answerReportedCall()
        
        await startCallSession(roomID: "!other:example.com", roomDisplayName: "other", kind: .native)
        
        let update = try #require(callProvider.reportCallWithUpdatedReceivedArguments)
        #expect(update.uuid != answeredUUID)
        #expect(update.update.localizedCallerName == "other")
        #expect(service.ongoingCallRoomIDPublisher.value == "!other:example.com")
        
        // Unlike a web view call, a native one is tracked by CallKit, so it gets the connected report too.
        serviceActions.send(.callSessionConnected(roomID: "!other:example.com"))
        #expect(callProvider.reportOutgoingCallWithConnectedAtReceivedArguments?.uuid == update.uuid)
    }
    
    // MARK: - Service
    
    @Test
    func ringIsWatchedByReceiver() async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        
        await waitForConfirmation { confirmation in
            bob.observeIncomingCallRoomIDRtcNotificationIDClosure = { _, _ in confirmation() }
            let payload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60).updatingReceiverID("@bob:matrix.org")
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) { }
        }
        
        #expect(bob.observeIncomingCallRoomIDRtcNotificationIDReceivedArguments?.roomID == "!room:example.com")
        #expect(bob.observeIncomingCallRoomIDRtcNotificationIDReceivedArguments?.rtcNotificationID == "$000")
        #expect(!service.observeIncomingCallRoomIDRtcNotificationIDCalled)
        
        serviceActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded))
        #expect(!callProvider.reportCallWithEndedAtReasonCalled, "Only the receiver speaks for its ring")
        
        bobActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded))
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .remoteEnded)
    }
    
    @Test(arguments: [(CallEndReason.remoteEnded, CXCallEndedReason.remoteEnded),
                      (.answeredElsewhere, .answeredElsewhere),
                      (.declinedElsewhere, .declinedElsewhere)])
    func incomingCallEndReportsReason(reason: CallEndReason, callKitReason: CXCallEndedReason) async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        serviceActions.send(.incomingCallEnded(roomID: "!other:example.com", reason: reason))
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        
        serviceActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: reason))
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == callKitReason)
        #expect(service.stopObservingIncomingCallCalled)
    }
    
    @Test
    func declineGoesThroughReceiver() async throws {
        let bob = makeCallService(userID: "@bob:matrix.org")
        manager.add(bob)
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let callID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        await waitForConfirmation { confirmation in
            bob.declineCallRoomIDRtcNotificationIDClosure = { _, _ in confirmation() }
            manager.endCall(withCallKitID: callID)
        }
        
        #expect(bob.declineCallRoomIDRtcNotificationIDReceivedArguments?.roomID == "!room:example.com")
        #expect(bob.declineCallRoomIDRtcNotificationIDReceivedArguments?.rtcNotificationID == "$000")
        
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(100)) { aliceDeclined in
            service.declineCallRoomIDRtcNotificationIDClosure = { _, _ in aliceDeclined() }
        }
        #expect(!service.declineCallRoomIDRtcNotificationIDCalled)
    }
    
    @Test
    func answeredWebCallOpens() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let uuid = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        let deferredAnswer = deferFulfillment(manager.actionsPublisher) { $0 == .callAnswered(userID: "@alice:matrix.org", roomID: "!room:example.com", isVoiceCall: false) }
        
        manager.provider(CXProvider(configuration: CXProviderConfiguration()), perform: CXAnswerCallAction(call: uuid))
        
        try await deferredAnswer.fulfill()
    }
    
    @Test
    func webCallSetupIsImmediate() {
        serviceActions.send(.callSessionStarted(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .webView))
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.roomID == "!room:example.com")
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == true)
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
    }
    
    @Test
    func nativeCallSetupWaitsForCallKit() async {
        await waitForConfirmation { confirmation in
            service.callSessionSetUpRoomIDIsAcceptedClosure = { [callProvider] _, _ in
                #expect(callProvider?.reportCallWithUpdatedCalled == true)
                confirmation()
            }
            serviceActions.send(.callSessionStarted(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .native))
        }
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
    }
    
    @Test
    func failedNativeCallStartIsStillSetUp() async {
        callController.requestCompletionClosure = { _, completion in
            completion(NSError(domain: "CallKit", code: 1))
        }
        
        await startCallSession(kind: .native)
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == true)
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
    }
    
    @Test
    func callKitEventsReachService() async throws {
        await startCallSession(kind: .native)
        let callID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        let provider = CXProvider(configuration: CXProviderConfiguration())
        
        manager.provider(provider, didActivate: AVAudioSession.sharedInstance())
        manager.provider(provider, perform: CXSetMutedCallAction(call: callID, muted: true))
        
        #expect(service.systemEventReceivedReceivedInvocations == [.audioSessionActivated, .microphoneMuteChanged(isMuted: true)])
    }
    
    @Test
    func nativeCallMuteReachesCallKit() async {
        await startCallSession(kind: .native)
        
        serviceActions.send(.audioEnabledChanged(false, roomID: "!room:example.com"))
        
        #expect((callController.requestCompletionReceivedArguments?.transaction.actions.first as? CXSetMutedCallAction)?.isMuted == true)
    }
    
    // MARK: - Accounts
    
    @Test
    func pushWithoutReceiverFails() async {
        await expectImmediatelyEndedCallReported(forPayload: PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60).removingReceiverID(),
                                                 expectedReason: .failed)
    }
    
    @Test
    func ongoingCallHasOneOwner() async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        
        await startCallSession(kind: .webView, service: bob, actions: bobActions)
        await startCallSession(kind: .webView)
        
        #expect(bob.ongoingCallRoomIDPublisher.value == nil)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        
        bobActions.send(.callSessionEnded(roomID: "!room:example.com", reason: nil))
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com", "Bob's late end leaves Alice's call")
    }
    
    @Test
    func ringOfOtherAccountIsNotAdopted() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        await startCallSession(kind: .native)
        
        #expect(callProvider.reportCallWithUpdatedCalled, "Alice's call is a new CallKit call")
        #expect(callProvider.reportCallWithUpdatedReceivedArguments?.uuid != ringingUUID)
    }
    
    @Test
    func otherAccountsReportsLeaveOngoingCall() async {
        appSettings.nativeCallEnabled = true
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        manager.add(makeCallService(userID: "@bob:matrix.org", actions: bobActions))
        await startCallSession(kind: .native)
        
        bobActions.send(.callSessionConnected(roomID: "!room:example.com"))
        bobActions.send(.audioEnabledChanged(false, roomID: "!room:example.com"))
        bobActions.send(.callSessionEnded(roomID: "!room:example.com", reason: .remoteEnded))
        
        #expect(!callProvider.reportOutgoingCallWithConnectedAtCalled)
        #expect(callController.requestCompletionCallsCount == 1, "Only the start transaction, no CXSetMutedCallAction")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
    }
    
    @Test(arguments: [true, false])
    func answeredCallNamesReceiver(nativeCallEnabled: Bool) async throws {
        appSettings.nativeCallEnabled = nativeCallEnabled
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        await clock.waitForScheduledSleep()
        let deferredAnswer = deferFulfillment(manager.actionsPublisher) { $0 == .callAnswered(userID: "@bob:matrix.org", roomID: "!room:example.com", isVoiceCall: false) }
        
        let answeredUUID = try await answerReportedCall()
        try await deferredAnswer.fulfill()
        
        manager.dropAnsweredCall(userID: "@alice:matrix.org", roomID: "!room:example.com")
        
        if nativeCallEnabled {
            #expect(!callProvider.reportCallWithEndedAtReasonCalled, "Alice's drop leaves Bob's call")
        } else {
            // Bob's answered call is kept, so it still counts as a call in progress.
            let otherCall = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
                .updatingRoomID("!other:example.com")
                .updatingRTCNotificationID("$111")
            await expectImmediatelyEndedCallReported(forPayload: otherCall, expectedReason: .unanswered)
        }
        
        manager.dropAnsweredCall(userID: "@bob:matrix.org", roomID: "!room:example.com")
        
        if nativeCallEnabled {
            #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
            #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
        } else {
            let endedCallsBeforePush = callProvider.reportCallWithEndedAtReasonCallsCount
            await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$222")
            
            #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
            #expect(callProvider.reportCallWithEndedAtReasonCallsCount == endedCallsBeforePush, "The new call rings")
        }
    }
    
    @Test
    func callKitMuteAndEndReachOwnerOnly() async throws {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        await startCallSession(kind: .native, service: bob, actions: bobActions)
        let callID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        let provider = CXProvider(configuration: CXProviderConfiguration())
        
        manager.provider(provider, didActivate: AVAudioSession.sharedInstance())
        manager.provider(provider, perform: CXSetMutedCallAction(call: callID, muted: true))
        manager.endCall(withCallKitID: callID)
        
        #expect(service.systemEventReceivedReceivedInvocations == [.audioSessionActivated])
        #expect(bob.systemEventReceivedReceivedInvocations == [.audioSessionActivated,
                                                               .microphoneMuteChanged(isMuted: true),
                                                               .endCallRequested(roomID: "!room:example.com")])
    }
    
    @Test
    func sameRingForTwoAccountsRingsOnce() async {
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        
        await expectImmediatelyEndedCallReported(forPayload: PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60),
                                                 expectedReason: .answeredElsewhere)
    }
    
    @Test
    func ringInRoomOfAnotherAccountsCallIsHandled() async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        await startCallSession(kind: .webView, service: bob, actions: bobActions)
        
        await expectImmediatelyEndedCallReported(forPayload: PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60).updatingRTCNotificationID("$111"),
                                                 expectedReason: .answeredElsewhere)
    }
    
    // MARK: - Late services
    
    @Test
    func lateServiceWatchesRing() async {
        let bob = makeCallService(userID: "@bob:matrix.org")
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        
        // Lets the ring's own watch run first, with no service to watch through.
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(100)) { watched in
            bob.observeIncomingCallRoomIDRtcNotificationIDClosure = { _, _ in watched() }
        }
        
        await waitForConfirmation(timeout: .seconds(1)) { watched in
            bob.observeIncomingCallRoomIDRtcNotificationIDClosure = { _, _ in watched() }
            manager.add(bob)
        }
        
        #expect(bob.observeIncomingCallRoomIDRtcNotificationIDReceivedArguments?.roomID == "!room:example.com")
        #expect(bob.observeIncomingCallRoomIDRtcNotificationIDReceivedArguments?.rtcNotificationID == "$000")
    }
    
    @Test
    func lateServiceSendsPendingDecline() async throws {
        let bob = makeCallService(userID: "@bob:matrix.org")
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let callID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        manager.endCall(withCallKitID: callID)
        
        await waitForConfirmation(timeout: .seconds(1)) { declined in
            bob.declineCallRoomIDRtcNotificationIDClosure = { _, _ in declined() }
            manager.add(bob)
        }
        
        #expect(bob.declineCallRoomIDRtcNotificationIDReceivedArguments?.roomID == "!room:example.com")
        #expect(bob.declineCallRoomIDRtcNotificationIDReceivedArguments?.rtcNotificationID == "$000")
        
        // A declined call isn't ringing any more.
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(100)) { watched in
            bob.observeIncomingCallRoomIDRtcNotificationIDClosure = { _, _ in watched() }
        }
        #expect(!bob.observeIncomingCallRoomIDRtcNotificationIDCalled)
    }
    
    @Test
    func replacedServiceHandsOverWatch() async throws {
        let oldBobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let oldBob = makeCallService(userID: "@bob:matrix.org", actions: oldBobActions)
        manager.add(oldBob)
        
        await waitForConfirmation(timeout: .seconds(1)) { watched in
            oldBob.observeIncomingCallRoomIDRtcNotificationIDClosure = { _, _ in watched() }
            let payload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60).updatingReceiverID("@bob:matrix.org")
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) { }
        }
        let callID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        // E.g. a cache clear, which rebuilds the account's session.
        let newBobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let newBob = makeCallService(userID: "@bob:matrix.org", actions: newBobActions)
        await waitForConfirmation(timeout: .seconds(1)) { watched in
            newBob.observeIncomingCallRoomIDRtcNotificationIDClosure = { _, _ in watched() }
            manager.add(newBob)
        }
        
        #expect(oldBob.stopObservingIncomingCallCalled)
        
        oldBobActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded))
        #expect(!callProvider.reportCallWithEndedAtReasonCalled, "The replaced service doesn't speak for the account any more")
        
        newBobActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded))
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == callID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .remoteEnded)
    }
    
    // MARK: - Removed and replaced services
    
    @Test
    func removingAccountEndsRing() async throws {
        let bob = makeCallService(userID: "@bob:matrix.org")
        manager.add(bob)
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
        #expect(bob.stopObservingIncomingCallCalled, "Cleared while its service is still there")
    }
    
    @Test
    func removingUnaddedAccountEndsRing() async throws {
        // E.g. a session that failed to restore, so its service was never added.
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
    }
    
    @Test
    func removingAccountLeavesAnsweredWebCallToHandOver() async throws {
        let bob = makeCallService(userID: "@bob:matrix.org")
        manager.add(bob)
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        try await answerReportedCall()
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(!callProvider.reportCallWithEndedAtReasonCalled, "The hand-over a second after answering reports it")
        #expect(bob.stopObservingIncomingCallCalled)
    }
    
    @Test
    func removingOtherAccountKeepsRing() async {
        await reportIncomingPush(isVoiceCall: false)
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        #expect(!service.stopObservingIncomingCallCalled)
    }
    
    @Test
    func removingAccountDropsPendingDecline() async throws {
        let bob = makeCallService(userID: "@bob:matrix.org")
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let callID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        manager.endCall(withCallKitID: callID)
        
        manager.remove(userID: "@bob:matrix.org")
        
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(500)) { declined in
            bob.declineCallRoomIDRtcNotificationIDClosure = { _, _ in declined() }
            manager.add(bob)
        }
        #expect(!bob.declineCallRoomIDRtcNotificationIDCalled)
    }
    
    @Test(arguments: [ElementCallSessionKind.webView, .native])
    func removingAccountEndsOngoingCall(kind: ElementCallSessionKind) async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        await startCallSession(kind: kind, service: bob, actions: bobActions)
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(bob.ongoingCallRoomIDPublisher.value == nil, "Bob hears the call is gone before its service is dropped")
        #expect(callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .failed } == (kind == .native))
        #expect(bob.systemEventReceivedReceivedInvocations.contains(.endCallRequested(roomID: "!room:example.com")) == (kind == .native))
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    @Test
    func removingAccountEndsAnsweredNativeCall() async throws {
        appSettings.nativeCallEnabled = true
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let answeredUUID = try await answerReportedCall()
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
        
        // C1's busy rule lets a ring through here anyway, so a ringing next push proves nothing.
        manager.dropAnsweredCall(userID: "@bob:matrix.org", roomID: "!room:example.com")
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == 1, "Nothing answered is left")
    }
    
    @Test
    func removalDuringSetUpStillReplies() async throws {
        appSettings.nativeCallEnabled = true
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        
        // Holds the start transaction open, as the system does until it has performed it.
        await waitForConfirmation(timeout: .seconds(1)) { requested in
            callController.requestCompletionClosure = { _, _ in requested() }
            bobActions.send(.callSessionStarted(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .native))
        }
        let completeStart = try #require(callController.requestCompletionReceivedArguments?.completion)
        let startedCall = try #require(callController.requestCompletionReceivedArguments?.transaction.actions.first as? CXStartCallAction)
        
        manager.remove(userID: "@bob:matrix.org")
        
        await waitForConfirmation(timeout: .seconds(1)) { replied in
            bob.callSessionSetUpRoomIDIsAcceptedClosure = { _, _ in replied() }
            completeStart(nil)
        }
        
        #expect(bob.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == false)
        #expect(bob.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
        #expect(!callProvider.reportCallWithUpdatedCalled)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedInvocations.last?.uuid == startedCall.callUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedInvocations.count == 2, "Once at removal, again once the start has landed")
    }
    
    @Test
    func removingOtherAccountKeepsCall() async {
        await startCallSession(kind: .webView)
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
    }
    
    @Test(arguments: [ElementCallSessionKind.webView, .native])
    func replacingServiceEndsLeftoverCall(kind: ElementCallSessionKind) async {
        let oldBobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let oldBob = makeCallService(userID: "@bob:matrix.org", actions: oldBobActions)
        manager.add(oldBob)
        await startCallSession(kind: kind, service: oldBob, actions: oldBobActions)
        
        // E.g. a cache clear, which rebuilds the account's session.
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        
        #expect(oldBob.ongoingCallRoomIDPublisher.value == nil, "The old service hears nil before it's swapped out")
        #expect(callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .failed } == (kind == .native))
        #expect(oldBob.systemEventReceivedReceivedInvocations.contains(.endCallRequested(roomID: "!room:example.com")) == (kind == .native))
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    @Test
    func replacingServiceKeepsOtherAccountsCall() async {
        await startCallSession(kind: .webView)
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
    }
    
    // MARK: - Helpers
    
    /// Builds an account's call service whose actions the test sends itself.
    private func makeCallService(userID: String,
                                 actions: PassthroughSubject<ElementCallServiceAction, Never> = .init()) -> ElementCallServiceMock {
        let callService = ElementCallServiceMock(.init(userID: userID))
        callService.actionsPublisher = actions.eraseToAnyPublisher()
        return callService
    }
    
    /// Starts a call session the way a call screen does, returning once the manager has set it up.
    /// Defaults to Alice's service and actions.
    private func startCallSession(roomID: String = "!room:example.com",
                                  roomDisplayName: String = "welcome",
                                  kind: ElementCallSessionKind,
                                  service: ElementCallServiceMock? = nil,
                                  actions: PassthroughSubject<ElementCallServiceAction, Never>? = nil) async {
        guard let callService = service ?? self.service, let callActions = actions ?? serviceActions else {
            Issue.record("Missing a service to start the call session with")
            return
        }
        
        await waitForConfirmation { confirmation in
            callService.callSessionSetUpRoomIDIsAcceptedClosure = { _, _ in confirmation() }
            callActions.send(.callSessionStarted(roomID: roomID, roomDisplayName: roomDisplayName, isVideo: true, kind: kind))
        }
    }
    
    /// Delivers a VoIP push and waits for it to be reported, returning once the call is ringing.
    private func reportIncomingPush(isVoiceCall: Bool,
                                    roomID: String = "!room:example.com",
                                    rtcNotificationID: String = "$000",
                                    receiverID: String = "@alice:matrix.org") async {
        await waitForConfirmation { confirmation in
            let payload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
                .updateIsVoice(isVoiceCall)
                .updatingRoomID(roomID)
                .updatingRTCNotificationID(rtcNotificationID)
                .updatingReceiverID(receiverID)
            
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) {
                confirmation()
            }
        }
    }
    
    /// Answers the call the provider last reported, returning its identifier.
    @discardableResult
    private func answerReportedCall() async throws -> UUID {
        let uuid = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        let provider = CXProvider(configuration: CXProviderConfiguration())
        
        manager.provider(provider, perform: CXAnswerCallAction(call: uuid))
        
        return uuid
    }
    
    private func expectImmediatelyEndedCallReported(forPayload payload: PKPushPayloadMock,
                                                    expectedReason: CXCallEndedReason) async {
        let baselineNewIncomingCount = callProvider.reportNewIncomingCallWithUpdateCompletionCallsCount
        let baselineEndedCount = callProvider.reportCallWithEndedAtReasonCallsCount
        
        await waitForConfirmation { confirmation in
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) {
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
        dict[ElementCallServiceNotificationKey.receiverID.rawValue] = "@alice:matrix.org"
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
    
    func updatingRoomID(_ roomID: String) -> Self {
        dict[ElementCallServiceNotificationKey.roomID.rawValue] = roomID
        return self
    }
    
    func updatingRTCNotificationID(_ rtcNotificationID: String) -> Self {
        dict[ElementCallServiceNotificationKey.rtcNotifyEventID.rawValue] = rtcNotificationID
        return self
    }
    
    func updatingReceiverID(_ receiverID: String) -> Self {
        dict[ElementCallServiceNotificationKey.receiverID.rawValue] = receiverID
        return self
    }
    
    func removingReceiverID() -> Self {
        dict[ElementCallServiceNotificationKey.receiverID.rawValue] = nil
        return self
    }
}
