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
// swiftlint:disable:next type_body_length
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
    private var callScreens: [CallScreenPresentation] = []
    private var callScreensCancellable: AnyCancellable?
    
    private let aliceID = "@alice:matrix.org"
    private let bobID = "@bob:matrix.org"
    private let roomID = "!room:example.com"
    private let otherRoomID = "!other:example.com"
    
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
        
        callScreensCancellable = manager.actionsPublisher.sink { [weak self] action in
            if case .callScreen(let presentation) = action {
                self?.callScreens.append(presentation)
            }
        }
    }
    
    isolated deinit {
        appSettings = nil
        callProvider = nil
        callController = nil
        currentDate = nil
        clock = nil
        pushRegistry = nil
    }
    
    @Test("An incoming call push is reported to CallKit with video")
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
    
    @Test("A voice call push is reported with video while calls run in the web view")
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
    
    @Test("A ringing call nobody answers ends as unanswered once its push expires")
    func unansweredCall() async throws {
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
    
    @Test("The ring is capped at 90 seconds, however late its push expires")
    func longPushLifetime() async throws {
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
    
    @Test("The call intent raw values match the spec")
    func callIntentRawValues() {
        // Test to ensure that the implicit rawValue of the string enum matches the MSC values
        #expect(CallIntent.audio.rawValue == "audio")
        #expect(CallIntent.video.rawValue == "video")
    }
    
    @Test("A ring that timed out is cleared, so the next push for its room rings as a new call")
    func pushAfterTimedOutRing() async throws {
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
    
    @Test("Setting up a call in the ringing room cancels the ring's timeout")
    func ringTimeoutAfterSetUp() async throws {
        // Schedule the 60s unanswered timer via an incoming push
        await waitForConfirmation { confirmation in
            let payload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            manager.pushRegistry(pushRegistry, didReceiveIncomingPushWith: payload, for: .voIP) {
                confirmation()
            }
        }
        
        // Make sure the cancellation below exercises a scheduled timer rather than one that never started.
        await clock.waitForScheduledSleep()
        
        // A set-up in the ringing room ends the ring, which must also cancel its timeout.
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
    
    @Test("An expired push is reported as a missed call named after its room")
    func expiredPush() async throws {
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
    
    @Test("A push for the room of the ongoing call is reported as handled, leaving the call up")
    func pushForOngoingCallRoom() async {
        // A duplicate push for an ongoing call is reported as handled, leaving the ongoing call alone.
        await startCallSession(kind: .webView)
        let pushPayload = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 30)
        await expectImmediatelyEndedCallReported(forPayload: pushPayload, expectedReason: .answeredElsewhere)
        
        // The call should be named so neither the brief system UI nor the Recents entry shows "Unknown".
        let update = callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update
        #expect(update?.localizedCallerName == "welcome")
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
    }
    
    @Test("A web view call is never tracked by CallKit")
    func webViewCallSession() async {
        // CallKit tracking a call gives this process exclusive media access, which starves the web
        // view. So a web view call is only ever tracked on the app side.
        await startCallSession(kind: .webView)
        serviceActions.send(.callSessionConnected(roomID: "!room:example.com"))
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(!callProvider.reportCallWithUpdatedCalled)
        #expect(!callProvider.reportOutgoingCallWithConnectedAtCalled)
    }
    
    @Test("The end of a replaced native call leaves the call that replaced it up")
    func endOfReplacedCall() async throws {
        appSettings.nativeCallEnabled = true
        
        // Leaving a call to start one in another room requests an end call action for the first,
        // then starts the second before the system performs it.
        await startCallSession(roomID: "!first:example.com", roomDisplayName: "first", kind: .native(takesOverAnsweredCall: false))
        let firstCallID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        
        serviceActions.send(.callSessionEnded(roomID: "!first:example.com", reason: nil))
        await startCallSession(roomID: "!second:example.com", roomDisplayName: "second", kind: .native(takesOverAnsweredCall: false))
        
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
    @Test("A native call that ended without us is reported with its reason rather than ended",
          arguments: [(CallEndReason.remoteEnded, CXCallEndedReason.remoteEnded),
                      (.unanswered, .unanswered),
                      (.failed, .failed)])
    func callEndedWithoutUs(reason: CallEndReason, callKitReason: CXCallEndedReason) async throws {
        appSettings.nativeCallEnabled = true
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
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
    
    @Test("Tearing down another room's call leaves the ongoing call up")
    func otherRoomTearDown() async {
        // A call screen that is dismissed after another room's call replaced it must not take the
        // new call down with it.
        await startCallSession(kind: .webView)
        
        serviceActions.send(.callSessionEnded(roomID: "!other:example.com", reason: nil))
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        
        serviceActions.send(.callSessionEnded(roomID: "!room:example.com", reason: nil))
        #expect(service.ongoingCallRoomIDPublisher.value == nil)
    }
    
    @Test("Starting a call in the ringing room ends the ring as answered elsewhere", arguments: [ElementCallSessionKind.webView, .native(takesOverAnsweredCall: false)])
    func startInRingingRoom(kind: ElementCallSessionKind) async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        await startCallSession(kind: kind)
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .answeredElsewhere)
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == 1)
        
        // Declining the ring that was left up used to hang up the call.
        manager.endCall(withCallKitID: ringingUUID)
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(service.systemEventReceivedReceivedInvocations.isEmpty)
    }
    
    @Test("Starting a call in another room ends the ring as missed")
    func startInOtherRoomWhileRinging() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        await startCallSession(roomID: "!other:example.com", roomDisplayName: "other", kind: .webView)
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .unanswered)
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == 1)
    }
    
    // MARK: - Busy
    
    @Test("A call while another rings is reported as missed")
    func pushWhileRinging() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        let otherCall = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            .updatingRoomID("!other:example.com")
            .updatingRTCNotificationID("$111")
        await expectImmediatelyEndedCallReported(forPayload: otherCall, expectedReason: .unanswered)
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.uuid == ringingUUID })
    }
    
    @Test("A call during a web view call is reported as missed")
    func pushDuringWebCall() async {
        await startCallSession(kind: .webView)
        
        let otherCall = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            .updatingRoomID("!other:example.com")
        await expectImmediatelyEndedCallReported(forPayload: otherCall, expectedReason: .unanswered)
    }
    
    @Test("A call during a native call is reported as missed")
    func pushDuringNativeCall() async {
        appSettings.nativeCallEnabled = true
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        
        let otherCall = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            .updatingRoomID("!other:example.com")
        await expectImmediatelyEndedCallReported(forPayload: otherCall, expectedReason: .unanswered)
    }
    
    @Test("A call while a native call is being answered is reported as missed")
    func pushWhileAnsweringNativeCall() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        try await answerReportedCall()
        
        let otherCall = PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60)
            .updatingRoomID("!other:example.com")
            .updatingRTCNotificationID("$111")
        await expectImmediatelyEndedCallReported(forPayload: otherCall, expectedReason: .unanswered)
    }
    
    @Test("The same ring pushed twice is reported as handled")
    func repeatedPush() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        await expectImmediatelyEndedCallReported(forPayload: PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60),
                                                 expectedReason: .answeredElsewhere)
        
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.uuid == ringingUUID })
    }
    
    @Test("An answered call that never opens stops blocking new calls")
    func pushAfterUnopenedAnswer() async throws {
        await reportIncomingPush(isVoiceCall: false)
        try await answerReportedCall()
        
        // The call screen couldn't open, e.g. because the room isn't joined.
        serviceActions.send(.callSessionEnded(roomID: "!room:example.com", reason: nil))
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    @Test("A call after a dropped answered call still times out")
    func timeoutAfterDroppedAnswer() async throws {
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
    
    @Test("An answered call that nothing opens is dropped after 30 seconds")
    func unopenedAnsweredCall() async throws {
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
    
    @Test("Dropping an answered call unblocks new calls")
    func pushAfterDroppedAnswer() async throws {
        await reportIncomingPush(isVoiceCall: false)
        try await answerReportedCall()
        
        manager.dropAnsweredCall(userID: "@alice:matrix.org", roomID: "!room:example.com")
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    // MARK: - Native calls
    
    @Test("With native calls on, a voice call is reported without video")
    func nativeIncomingVoiceCall() async {
        appSettings.nativeCallEnabled = true
        
        await reportIncomingPush(isVoiceCall: true)
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.hasVideo == false)
    }
    
    @Test("With native calls on, a video call is still reported with video")
    func nativeIncomingVideoCall() async {
        appSettings.nativeCallEnabled = true
        
        await reportIncomingPush(isVoiceCall: false)
        
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.hasVideo == true)
    }
    
    @Test("With native calls on, answering keeps the call up for the stack to take over")
    func nativeAnswer() async throws {
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
    
    @Test("An answered native call ends as failed when nothing takes it over")
    func nativeAnswerNotTakenOver() async throws {
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
    
    @Test("Dropping an answered native call ends it as failed")
    func dropAnsweredNativeCall() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        let answeredUUID = try await answerReportedCall()
        
        manager.dropAnsweredCall(userID: "@alice:matrix.org", roomID: "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        
        manager.dropAnsweredCall(userID: "@alice:matrix.org", roomID: "!room:example.com")
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
    }
    
    @Test("The native call stack takes over the answered call under the same CallKit call")
    func nativeAnswerTakeOver() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        let answeredUUID = try await answerReportedCall()
        
        // Answering starts the watchdog, so wait for it before asserting that the hand-over stops it.
        await clock.waitForScheduledSleep()
        
        await startCallSession(kind: .native(takesOverAnsweredCall: true))
        
        // Taking the answered call over means keeping its identifier rather than reporting a new
        // outgoing call, which is what the update below would be part of.
        #expect(!callProvider.reportCallWithUpdatedCalled)
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == true)
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
        
        // And the watchdog must be gone, otherwise it ends the call that was just taken over.
        #expect(!clock.hasPendingSleep, "The watchdog must not outlive the hand-over")
        
        manager.endCall(withCallKitID: answeredUUID)
        #expect(service.systemEventReceivedReceivedInvocations == [.endCallRequested(roomID: "!room:example.com")])
    }
    
    @Test("A native call in another room is a new CallKit call and ends the answered one")
    func nativeCallInOtherRoomAfterAnswer() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        await clock.waitForScheduledSleep()
        
        let answeredUUID = try await answerReportedCall()
        
        await startCallSession(roomID: "!other:example.com", roomDisplayName: "other", kind: .native(takesOverAnsweredCall: false))
        
        let update = try #require(callProvider.reportCallWithUpdatedReceivedArguments)
        #expect(update.uuid != answeredUUID)
        #expect(update.update.localizedCallerName == "other")
        #expect(service.ongoingCallRoomIDPublisher.value == "!other:example.com")
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
        
        // Unlike a web view call, a native one is tracked by CallKit, so it gets the connected report too.
        serviceActions.send(.callSessionConnected(roomID: "!other:example.com"))
        #expect(callProvider.reportOutgoingCallWithConnectedAtReceivedArguments?.uuid == update.uuid)
    }
    
    @Test("A web call in the answered room ends the answered native call")
    func webStartAfterNativeAnswer() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        let answeredUUID = try await answerReportedCall()
        
        await startCallSession(kind: .webView)
        
        // Left up, CallKit would keep the media from the web view.
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == 1)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
    }
    
    @Test("Taking over an answered call whose caller hung up is refused")
    func takeOverOfEndedAnswer() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false)
        try await answerReportedCall()
        
        // The caller hangs up as the call is answered.
        serviceActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded))
        let requestsBefore = callController.requestCompletionCallsCount
        
        await startCallSession(kind: .native(takesOverAnsweredCall: true))
        
        // Starting it as a new call would ring the caller back.
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == false)
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
        #expect(callController.requestCompletionCallsCount == requestsBefore)
        #expect(!service.ongoingCallChangedRoomIDReceivedInvocations.contains("!room:example.com"))
    }
    
    @Test("A refused take-over leaves the ongoing call up")
    func refusedTakeOverDuringCall() async {
        await startCallSession(roomID: "!other:example.com", roomDisplayName: "other", kind: .native(takesOverAnsweredCall: false))
        let requestsBefore = callController.requestCompletionCallsCount
        
        await startCallSession(kind: .native(takesOverAnsweredCall: true))
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == false)
        #expect(callController.requestCompletionCallsCount == requestsBefore)
        #expect(service.ongoingCallRoomIDPublisher.value == "!other:example.com")
    }
    
    // MARK: - Service
    
    @Test("A ring is watched by its receiver's service, the only one that can end it")
    func ringWatch() async {
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
    
    @Test("A ring that ended elsewhere is reported with its reason",
          arguments: [(CallEndReason.remoteEnded, CXCallEndedReason.remoteEnded),
                      (.answeredElsewhere, .answeredElsewhere),
                      (.declinedElsewhere, .declinedElsewhere)])
    func incomingCallEnd(reason: CallEndReason, callKitReason: CXCallEndedReason) async throws {
        await reportIncomingPush(isVoiceCall: false)
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        serviceActions.send(.incomingCallEnded(roomID: "!other:example.com", reason: reason))
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        
        serviceActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: reason))
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == callKitReason)
        #expect(service.stopObservingIncomingCallCalled)
    }
    
    @Test("Declining a ring sends the decline through its receiver's service")
    func decline() async throws {
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
    
    @Test("Answering a web view call reports it as answered")
    func webAnswer() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let uuid = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        let deferredAnswer = deferFulfillment(manager.actionsPublisher) { $0 == .callAnswered(userID: "@alice:matrix.org", roomID: "!room:example.com", isVoiceCall: false) }
        
        manager.provider(CXProvider(configuration: CXProviderConfiguration()), perform: CXAnswerCallAction(call: uuid))
        
        try await deferredAnswer.fulfill()
    }
    
    @Test("A web answer whose caller hung up within the hand-over never opens")
    func webAnswerAfterCallerHangUp() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let deferredAnswer = deferFailure(manager.actionsPublisher, timeout: .milliseconds(100), message: "Opening the call would ring the caller back") {
            $0 == .callAnswered(userID: "@alice:matrix.org", roomID: "!room:example.com", isVoiceCall: false)
        }
        let answeredUUID = try await answerReportedCall()
        
        // The caller hangs up before the answer is handed over to the web view.
        serviceActions.send(.incomingCallEnded(roomID: "!room:example.com", reason: .remoteEnded))
        
        // Only now, as the hang-up above reports the same call ended at once.
        let (endedCalls, endedCallsContinuation) = AsyncStream<UUID>.makeStream()
        callProvider.reportCallWithEndedAtReasonClosure = { uuid, _, _ in
            endedCallsContinuation.yield(uuid)
        }
        let deferredHandOver = deferFulfillment(endedCalls) { $0 == answeredUUID }
        try await deferredHandOver.fulfill()
        
        try await deferredAnswer.fulfill()
    }
    
    @Test("A web view call is set up at once")
    func webCallSetUp() {
        serviceActions.send(.callSessionStarted(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .webView))
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.roomID == "!room:example.com")
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == true)
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
    }
    
    @Test("A native call is set up once CallKit knows about it")
    func nativeCallSetUp() async {
        await waitForConfirmation { confirmation in
            service.callSessionSetUpRoomIDIsAcceptedClosure = { [callProvider] _, _ in
                #expect(callProvider?.reportCallWithUpdatedCalled == true)
                confirmation()
            }
            serviceActions.send(.callSessionStarted(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .native(takesOverAnsweredCall: false)))
        }
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
    }
    
    @Test("A native call is still set up when CallKit fails to start it")
    func nativeCallSetUpWithCallKitFailure() async {
        callController.requestCompletionClosure = { _, completion in
            completion(NSError(domain: "CallKit", code: 1))
        }
        
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == true)
        #expect(service.callSessionSetUpRoomIDIsAcceptedCallsCount == 1)
    }
    
    @Test("CallKit's audio activation and mute reach the call's service")
    func callKitEvents() async throws {
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        let callID = try #require(callProvider.reportCallWithUpdatedReceivedArguments?.uuid)
        let provider = CXProvider(configuration: CXProviderConfiguration())
        
        manager.provider(provider, didActivate: AVAudioSession.sharedInstance())
        manager.provider(provider, perform: CXSetMutedCallAction(call: callID, muted: true))
        
        #expect(service.systemEventReceivedReceivedInvocations == [.audioSessionActivated, .microphoneMuteChanged(isMuted: true)])
    }
    
    @Test("Muting a native call is mirrored into CallKit")
    func nativeCallMute() async {
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        
        serviceActions.send(.audioEnabledChanged(false, roomID: "!room:example.com"))
        
        #expect((callController.requestCompletionReceivedArguments?.transaction.actions.first as? CXSetMutedCallAction)?.isMuted == true)
    }
    
    @Test("A CallKit mute for another call is ignored")
    func callKitMuteForOtherCall() async {
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        
        manager.provider(CXProvider(configuration: CXProviderConfiguration()), perform: CXSetMutedCallAction(call: UUID(), muted: true))
        
        #expect(service.systemEventReceivedReceivedInvocations.isEmpty)
    }
    
    // MARK: - Provider reset
    
    @Test("A CallKit reset ends the owner's native call and deactivates the audio everywhere")
    func resetDuringNativeCall() async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        await startCallSession(kind: .native(takesOverAnsweredCall: false), service: bob, actions: bobActions)
        let requestsBefore = callController.requestCompletionCallsCount
        
        manager.providerDidReset(CXProvider(configuration: CXProviderConfiguration()))
        
        #expect(bob.systemEventReceivedReceivedInvocations == [.endCallRequested(roomID: "!room:example.com"), .audioSessionDeactivated])
        #expect(service.systemEventReceivedReceivedInvocations == [.audioSessionDeactivated])
        #expect(bob.ongoingCallRoomIDPublisher.value == nil)
        // The provider dropped every call, so there's nothing left to request or report.
        #expect(callController.requestCompletionCallsCount == requestsBefore)
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
    }
    
    @Test("A CallKit reset leaves a web call up")
    func resetDuringWebCall() async {
        await startCallSession(kind: .webView)
        
        manager.providerDidReset(CXProvider(configuration: CXProviderConfiguration()))
        
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
        #expect(service.systemEventReceivedReceivedInvocations == [.audioSessionDeactivated])
    }
    
    @Test("A CallKit reset ends the ringing call")
    func resetWhileRinging() async {
        await reportIncomingPush(isVoiceCall: false)
        
        manager.providerDidReset(CXProvider(configuration: CXProviderConfiguration()))
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
    }
    
    // MARK: - Accounts
    
    @Test("A push without a receiver is reported as failed")
    func pushWithoutReceiver() async {
        await expectImmediatelyEndedCallReported(forPayload: PKPushPayloadMock().updatingExpiration(currentDate, lifetime: 60).removingReceiverID(),
                                                 expectedReason: .failed)
    }
    
    @Test("The ongoing call has one owner, whose end alone clears it")
    func ongoingCallOwner() async {
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
    
    @Test("Another account's ring is ended, not adopted, by a native call in its room")
    func nativeStartInOtherAccountsRingingRoom() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        
        #expect(callProvider.reportCallWithUpdatedCalled, "Alice's call is a new CallKit call")
        #expect(callProvider.reportCallWithUpdatedReceivedArguments?.uuid != ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .answeredElsewhere)
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == 1)
    }
    
    @Test("A native start ends an answered call rather than taking it over", arguments: ["@alice:matrix.org", "@bob:matrix.org"])
    func nativeStartAfterAnswer(receiverID: String) async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false, receiverID: receiverID)
        let answeredUUID = try await answerReportedCall()
        
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        
        #expect(callProvider.reportCallWithUpdatedReceivedArguments?.uuid != nil, "Alice's call is a new CallKit call")
        #expect(callProvider.reportCallWithUpdatedReceivedArguments?.uuid != answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
    }
    
    @Test("Another account's answered call is never taken over as an answer")
    func takeOverOfOtherAccountsAnswer() async throws {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let answeredUUID = try await answerReportedCall()
        
        await startCallSession(kind: .native(takesOverAnsweredCall: true))
        
        #expect(service.callSessionSetUpRoomIDIsAcceptedReceivedArguments?.isAccepted == false)
        // No account here can take Bob's call over, so it must not wait for the watchdog.
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == 1)
    }
    
    @Test("Another account's reports leave the ongoing call alone")
    func otherAccountsReports() async {
        appSettings.nativeCallEnabled = true
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        manager.add(makeCallService(userID: "@bob:matrix.org", actions: bobActions))
        await startCallSession(kind: .native(takesOverAnsweredCall: false))
        
        bobActions.send(.callSessionConnected(roomID: "!room:example.com"))
        bobActions.send(.audioEnabledChanged(false, roomID: "!room:example.com"))
        bobActions.send(.callSessionEnded(roomID: "!room:example.com", reason: .remoteEnded))
        
        #expect(!callProvider.reportOutgoingCallWithConnectedAtCalled)
        #expect(callController.requestCompletionCallsCount == 1, "Only the start transaction, no CXSetMutedCallAction")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        #expect(service.ongoingCallRoomIDPublisher.value == "!room:example.com")
    }
    
    @Test("An answered call names its receiver, the only account whose drop ends it", arguments: [true, false])
    func answeredCallReceiver(nativeCallEnabled: Bool) async throws {
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
    
    @Test("CallKit's mute and end reach only the call's owner")
    func callKitMuteAndEndWithTwoAccounts() async throws {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        await startCallSession(kind: .native(takesOverAnsweredCall: false), service: bob, actions: bobActions)
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
    
    // MARK: - Late services
    
    @Test("A service added after its account's ring started watches it")
    func lateServiceWhileRinging() async {
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
    
    @Test("A decline made before its account's service was added is sent once it is")
    func lateServiceAfterDecline() async throws {
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
    
    @Test("A replaced service hands the ring's watch over to the new one")
    func replaceServiceWhileRinging() async throws {
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
    
    @Test("A service added while the audio session is active hears it")
    func lateServiceWithActiveAudio() {
        manager.provider(CXProvider(configuration: CXProviderConfiguration()), didActivate: AVAudioSession.sharedInstance())
        let bob = makeCallService(userID: "@bob:matrix.org")
        
        manager.add(bob)
        
        #expect(bob.systemEventReceivedReceivedInvocations == [.audioSessionActivated])
    }
    
    @Test("A service added after the audio session ended hears nothing", arguments: [false, true])
    func lateServiceAfterEndedAudio(isReset: Bool) {
        let provider = CXProvider(configuration: CXProviderConfiguration())
        manager.provider(provider, didActivate: AVAudioSession.sharedInstance())
        if isReset {
            manager.providerDidReset(provider)
        } else {
            manager.provider(provider, didDeactivate: AVAudioSession.sharedInstance())
        }
        let bob = makeCallService(userID: "@bob:matrix.org")
        
        manager.add(bob)
        
        #expect(bob.systemEventReceivedReceivedInvocations.isEmpty)
    }
    
    // MARK: - Removed and replaced services
    
    @Test("Removing an account ends its ring as failed")
    func removeAccountWhileRinging() async throws {
        let bob = makeCallService(userID: "@bob:matrix.org")
        manager.add(bob)
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let ringingUUID = try #require(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.uuid)
        
        manager.remove(userID: "@alice:matrix.org")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled, "Another account's removal leaves the ring")
        #expect(!bob.stopObservingIncomingCallCalled)
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == ringingUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
        #expect(bob.stopObservingIncomingCallCalled, "Cleared while its service is still there")
    }
    
    @Test("Removing an account drops its pending decline")
    func removeAccountWithPendingDecline() async throws {
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
    
    @Test("Removing an account ends its ongoing call", arguments: [ElementCallSessionKind.webView, .native(takesOverAnsweredCall: false)])
    func removeAccountWithOngoingCall(kind: ElementCallSessionKind) async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        await startCallSession(kind: kind, service: bob, actions: bobActions)
        
        manager.remove(userID: "@alice:matrix.org")
        #expect(bob.ongoingCallRoomIDPublisher.value == "!room:example.com", "Another account's removal leaves the call")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(bob.ongoingCallRoomIDPublisher.value == nil, "Bob hears the call is gone before its service is dropped")
        #expect(callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .failed } == (kind != .webView))
        #expect(bob.endNativeCallCallsCount == 1)
        #expect(!bob.systemEventReceivedReceivedInvocations.contains(.endCallRequested(roomID: "!room:example.com")), "One hang-up, through the service")
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    @Test("Removing an account ends its answered native call")
    func removeAccountWithAnsweredNativeCall() async throws {
        appSettings.nativeCallEnabled = true
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        await reportIncomingPush(isVoiceCall: false, receiverID: "@bob:matrix.org")
        let answeredUUID = try await answerReportedCall()
        
        manager.remove(userID: "@bob:matrix.org")
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredUUID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(callProvider.reportNewIncomingCallWithUpdateCompletionReceivedArguments?.update.remoteHandle?.value == "!other:example.com")
        #expect(callProvider.reportCallWithEndedAtReasonCallsCount == 1, "Nothing answered is left")
    }
    
    @Test("A native call whose account is removed during its set-up still gets its set-up reply, as a refusal")
    func removeAccountDuringSetUp() async throws {
        appSettings.nativeCallEnabled = true
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: "@bob:matrix.org", actions: bobActions)
        manager.add(bob)
        
        // Holds the start transaction open, as the system does until it has performed it.
        await waitForConfirmation(timeout: .seconds(1)) { requested in
            callController.requestCompletionClosure = { _, _ in requested() }
            bobActions.send(.callSessionStarted(roomID: "!room:example.com", roomDisplayName: "welcome", isVideo: true, kind: .native(takesOverAnsweredCall: false)))
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
    
    @Test("Replacing an account's service ends the call the old one left", arguments: [ElementCallSessionKind.webView, .native(takesOverAnsweredCall: false)])
    func replaceServiceWithOngoingCall(kind: ElementCallSessionKind) async {
        let oldBobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let oldBob = makeCallService(userID: "@bob:matrix.org", actions: oldBobActions)
        manager.add(oldBob)
        await startCallSession(kind: kind, service: oldBob, actions: oldBobActions)
        
        manager.add(makeCallService(userID: "@alice:matrix.org"))
        #expect(oldBob.ongoingCallRoomIDPublisher.value == "!room:example.com", "Replacing another account's service leaves the call")
        #expect(!callProvider.reportCallWithEndedAtReasonCalled)
        
        // E.g. a cache clear, which rebuilds the account's session.
        manager.add(makeCallService(userID: "@bob:matrix.org"))
        
        #expect(oldBob.ongoingCallRoomIDPublisher.value == nil, "The old service hears nil before it's swapped out")
        #expect(callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .failed } == (kind != .webView))
        #expect(oldBob.endNativeCallCallsCount == 1)
        #expect(!oldBob.systemEventReceivedReceivedInvocations.contains(.endCallRequested(roomID: "!room:example.com")), "One hang-up, through the service")
        
        await reportIncomingPush(isVoiceCall: false, roomID: "!other:example.com", rtcNotificationID: "$111")
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.reason == .unanswered })
    }
    
    // MARK: - Call screen
    
    @Test("A call request the service doesn't run natively presents the web view")
    func presentWebCall() {
        serviceActions.send(.callRequested(.mock()))
        
        #expect(service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitCalled, "The native call stack is asked first")
        #expect(callScreens == [.present(userID: aliceID, kind: .webView(.mock()))])
    }
    
    @Test("A native call is presented once its call stack asks for it")
    func presentNativeCall() {
        service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitReturnValue = true
        serviceActions.send(.callRequested(.mock()))
        #expect(callScreens.isEmpty, "The stack presents its call once it has started it")
        
        serviceActions.send(.nativeCallPresentation(.present))
        #expect(callScreens == [.present(userID: aliceID, kind: .native)])
    }
    
    @Test("Asking again for the call on screen returns to it")
    func restoreCall() {
        serviceActions.send(.callRequested(.mock()))
        serviceActions.send(.callRequested(.mock()))
        
        #expect(callScreens == [.present(userID: aliceID, kind: .webView(.mock())), .restore],
                "Still loading, before any call session, the same call comes back rather than opening twice")
    }
    
    @Test("A call in another room replaces the one on screen, whose hang-up leaves the new call alone")
    func replaceCall() {
        serviceActions.send(.callRequested(.mock()))
        serviceActions.send(.callRequested(.mock(roomID: otherRoomID)))
        // The replaced screen hangs up as it goes.
        serviceActions.send(.callSessionEnded(roomID: roomID, reason: nil))
        serviceActions.send(.callRequested(.mock(roomID: otherRoomID)))
        
        #expect(callScreens == [.present(userID: aliceID, kind: .webView(.mock())),
                                .present(userID: aliceID, kind: .webView(.mock(roomID: otherRoomID))),
                                .restore])
    }
    
    @Test("A web view call whose screen went is presented again when asked for")
    func presentCallAgain() {
        serviceActions.send(.callRequested(.mock()))
        serviceActions.send(.callSessionEnded(roomID: roomID, reason: nil))
        serviceActions.send(.callRequested(.mock()))
        
        #expect(callScreens == [.present(userID: aliceID, kind: .webView(.mock())),
                                .present(userID: aliceID, kind: .webView(.mock()))])
    }
    
    @Test("Minimising a web view call minimises its screen")
    func minimizeWebCall() {
        serviceActions.send(.callRequested(.mock()))
        serviceActions.send(.callMinimizeRequested)
        
        #expect(callScreens.last == .minimize)
    }
    
    @Test("Minimising a native call waits for its system window")
    func minimizeNativeCall() {
        showNativeCall()
        
        serviceActions.send(.callMinimizeRequested)
        #expect(service.minimizeNativeCallCalled)
        #expect(callScreens == [.present(userID: aliceID, kind: .native)], "The screen waits for the system window")
        
        serviceActions.send(.nativeCallPresentation(.minimize))
        #expect(callScreens.last == .minimize)
    }
    
    @Test("Minimising without a call on screen does nothing")
    func minimizeWithoutCall() {
        serviceActions.send(.callMinimizeRequested)
        
        #expect(callScreens.isEmpty)
        #expect(!service.minimizeNativeCallCalled)
    }
    
    @Test("The native call stack's restore brings its call back")
    func restoreNativeCall() {
        showNativeCall()
        
        serviceActions.send(.nativeCallPresentation(.restore))
        
        #expect(service.restoreNativeCallCalled)
        #expect(callScreens.last == .restore)
    }
    
    @Test("A dismissed native call no longer counts as on screen")
    func dismissNativeCall() {
        showNativeCall()
        
        serviceActions.send(.nativeCallPresentation(.dismiss))
        serviceActions.send(.callMinimizeRequested)
        
        #expect(callScreens == [.present(userID: aliceID, kind: .native), .dismiss])
        #expect(!service.minimizeNativeCallCalled)
    }
    
    @Test("Removing or replacing an account's call service dismisses its call", arguments: [false, true])
    func removeAccountDuringCall(replacesService: Bool) {
        serviceActions.send(.callRequested(.mock()))
        
        if replacesService {
            manager.add(makeCallService(userID: aliceID))
        } else {
            manager.remove(userID: aliceID)
        }
        
        #expect(callScreens.last == .dismiss)
    }
    
    @Test("Removing an account leaves another account's call on screen")
    func removeOtherAccountDuringCall() {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        manager.add(makeCallService(userID: bobID, actions: bobActions))
        bobActions.send(.callRequested(.mock()))
        
        manager.remove(userID: aliceID)
        
        #expect(callScreens == [.present(userID: bobID, kind: .webView(.mock()))])
    }
    
    @Test("Ending an account's calls dismisses its call and keeps its service")
    func endAccountCalls() {
        serviceActions.send(.callRequested(.mock()))
        
        serviceActions.send(.callsEndRequested)
        #expect(callScreens.last == .dismiss)
        
        serviceActions.send(.callRequested(.mock(roomID: otherRoomID)))
        #expect(callScreens.last == .present(userID: aliceID, kind: .webView(.mock(roomID: otherRoomID))))
    }
    
    @Test("Ending an account's calls hangs up its native call")
    func endAccountNativeCall() {
        showNativeCall()
        
        serviceActions.send(.callsEndRequested)
        
        #expect(service.endNativeCallCallsCount == 1)
        #expect(callScreens.last == .dismiss)
    }
    
    @Test("The system ending a web view call dismisses its screen")
    func systemEndsWebCall() async throws {
        await reportIncomingPush(isVoiceCall: false)
        let callKitID = try await answerReportedCall()
        serviceActions.send(.callRequested(.mock()))
        await startCallSession(kind: .webView)
        
        manager.endCall(withCallKitID: callKitID)
        
        #expect(callScreens.last == .dismiss)
    }
    
    // MARK: - Pending call requests
    
    @Test("A call for an account without a call service opens once the service is added")
    func pendingCallRequest() async {
        let bob = makeCallService(userID: bobID)
        bob.joinedRoomRoomIDReturnValue = JoinedRoomProxyMock(.init(id: roomID))
        manager.requestCall(userID: bobID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: true)
        
        await waitForConfirmation { confirmation in
            bob.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitClosure = { _, _, _ in
                confirmation()
                return true
            }
            manager.add(bob)
            #expect(!bob.joinedRoomRoomIDCalled, "Opened once adding the service is over, as the account's screens start in that step")
        }
        
        #expect(bob.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitReceivedArguments?.answeredFromCallKit == true)
    }
    
    @Test("A pending call request in another room drops the older one, ending its answer")
    func replacePendingCallRequest() async throws {
        let answeredCallID = try await answerNativeCall(receiverID: bobID)
        manager.requestCall(userID: bobID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: true)
        
        manager.requestCall(userID: bobID, roomID: otherRoomID, isVoiceCall: false, answeredFromCallKit: false)
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredCallID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
    }
    
    @Test("Asking again for a pending call request keeps its answer for the call to take over")
    func repeatPendingCallRequest() async throws {
        let answeredCallID = try await answerNativeCall(receiverID: bobID)
        manager.requestCall(userID: bobID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: true)
        manager.requestCall(userID: bobID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: false)
        #expect(!callProvider.reportCallWithEndedAtReasonReceivedInvocations.contains { $0.uuid == answeredCallID }, "The answered call stays up")
        
        let bob = makeCallService(userID: bobID)
        bob.joinedRoomRoomIDReturnValue = JoinedRoomProxyMock(.init(id: roomID))
        await waitForConfirmation { confirmation in
            bob.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitClosure = { _, _, _ in
                confirmation()
                return true
            }
            manager.add(bob)
        }
        
        #expect(bob.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitReceivedArguments?.answeredFromCallKit == true)
    }
    
    @Test("A pending call request is dropped with its account")
    func removeAccountWithPendingCallRequest() async {
        let bob = makeCallService(userID: bobID)
        manager.requestCall(userID: bobID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: false)
        manager.remove(userID: bobID)
        
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(500)) { confirmation in
            bob.joinedRoomRoomIDClosure = { _ in
                confirmation()
                return nil
            }
            manager.add(bob)
        }
    }
    
    @Test("Presenting a call in another room drops the pending call request")
    func presentCallWithPendingCallRequest() async throws {
        let answeredCallID = try await answerNativeCall(receiverID: bobID)
        manager.requestCall(userID: bobID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: true)
        
        serviceActions.send(.callRequested(.mock(roomID: otherRoomID)))
        
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.uuid == answeredCallID)
        #expect(callProvider.reportCallWithEndedAtReasonReceivedArguments?.reason == .failed)
    }
    
    @Test("A call in a room that isn't joined is dropped, ending its answer")
    func unjoinedRoomCallRequest() async throws {
        let answeredCallID = try await answerNativeCall()
        service.joinedRoomRoomIDReturnValue = nil
        
        await waitForConfirmation { confirmation in
            callProvider.reportCallWithEndedAtReasonClosure = { uuid, _, reason in
                if uuid == answeredCallID, reason == .failed {
                    confirmation()
                }
            }
            manager.requestCall(userID: aliceID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: true)
        }
        
        #expect(callScreens.isEmpty)
    }
    
    @Test("A call is dropped when its account goes while the room loads")
    func removeAccountWhileRoomLoads() async {
        service.joinedRoomRoomIDClosure = { [manager, aliceID] roomID in
            manager?.remove(userID: aliceID)
            return JoinedRoomProxyMock(.init(id: roomID))
        }
        
        await waitForConfirmation(expectedCount: 0, timeout: .milliseconds(500)) { confirmation in
            service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitClosure = { _, _, _ in
                confirmation()
                return false
            }
            manager.requestCall(userID: aliceID, roomID: roomID, isVoiceCall: false, answeredFromCallKit: false)
        }
        
        #expect(callScreens.isEmpty)
    }
    
    @Test("A call for another account waits for the running native call to hang up")
    func replaceOtherAccountsNativeCall() async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: bobID, actions: bobActions)
        manager.add(bob)
        showNativeCall(service: bob, actions: bobActions)
        service.joinedRoomRoomIDClosure = { roomID in JoinedRoomProxyMock(.init(id: roomID)) }
        
        // Asked twice, as a second tap while the other call hangs up.
        serviceActions.send(.callRequested(.mock(roomID: otherRoomID)))
        serviceActions.send(.callRequested(.mock(roomID: otherRoomID)))
        
        #expect(bob.endNativeCallCallsCount == 2)
        #expect(!service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitCalled, "Alice's call waits")
        
        await waitForConfirmation(timeout: .seconds(1)) { confirmation in
            service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitClosure = { _, _, _ in
                confirmation()
                return true
            }
            bobActions.send(.nativeCallPresentation(.dismiss))
        }
        
        #expect(service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitCallsCount == 1, "Asked twice, started once")
        #expect(service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitReceivedArguments?.roomProxy.id == otherRoomID)
        #expect(callScreens == [.present(userID: bobID, kind: .native), .dismiss])
    }
    
    @Test("A waiting call starts when the other account is removed or its call service replaced", arguments: [false, true])
    func removeAccountBeforeWaitingCall(replacesService: Bool) async {
        let bobActions = PassthroughSubject<ElementCallServiceAction, Never>()
        let bob = makeCallService(userID: bobID, actions: bobActions)
        manager.add(bob)
        showNativeCall(service: bob, actions: bobActions)
        service.joinedRoomRoomIDClosure = { roomID in JoinedRoomProxyMock(.init(id: roomID)) }
        serviceActions.send(.callRequested(.mock(roomID: otherRoomID)))
        
        await waitForConfirmation(timeout: .seconds(1)) { confirmation in
            service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitClosure = { _, _, _ in
                confirmation()
                return true
            }
            
            if replacesService {
                // E.g. a cache clear, which rebuilds the account's session.
                manager.add(makeCallService(userID: bobID))
            } else {
                manager.remove(userID: bobID)
            }
        }
        
        #expect(service.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitReceivedArguments?.roomProxy.id == otherRoomID)
    }
    
    // MARK: - Helpers
    
    /// Shows a native call the way its stack does. Defaults to Alice's service and actions.
    private func showNativeCall(service: ElementCallServiceMock? = nil,
                                actions: PassthroughSubject<ElementCallServiceAction, Never>? = nil) {
        guard let callService = service ?? self.service, let callActions = actions ?? serviceActions else {
            Issue.record("Missing a service to show the native call with")
            return
        }
        
        callService.handleNativeCallRequestRoomProxyIsVoiceCallAnsweredFromCallKitReturnValue = true
        callActions.send(.callRequested(.mock()))
        callActions.send(.nativeCallPresentation(.present))
    }
    
    /// Rings and answers a call for the native call stack, which keeps it up until a call takes it over or it's dropped.
    private func answerNativeCall(receiverID: String = "@alice:matrix.org") async throws -> UUID {
        appSettings.nativeCallEnabled = true
        await reportIncomingPush(isVoiceCall: false, receiverID: receiverID)
        return try await answerReportedCall()
    }
    
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
        dict[VoIPPushPayload.Key.roomID.rawValue] = "!room:example.com"
        dict[VoIPPushPayload.Key.roomDisplayName.rawValue] = "welcome"
        dict[VoIPPushPayload.Key.rtcNotifyEventID.rawValue] = "$000"
        dict[VoIPPushPayload.Key.expirationDate.rawValue] = Date(timeIntervalSince1970: 10)
        dict[VoIPPushPayload.Key.receiverID.rawValue] = "@alice:matrix.org"
    }
    
    override var dictionaryPayload: [AnyHashable: Any] {
        dict
    }
    
    func updatingExpiration(_ from: Date, lifetime: TimeInterval) -> Self {
        dict[VoIPPushPayload.Key.expirationDate.rawValue] = from.addingTimeInterval(lifetime)
        return self
    }
    
    func updateIsVoice(_ isVoice: Bool) -> Self {
        dict[VoIPPushPayload.Key.isVoiceCall.rawValue] = isVoice
        return self
    }
    
    func updatingRoomID(_ roomID: String) -> Self {
        dict[VoIPPushPayload.Key.roomID.rawValue] = roomID
        return self
    }
    
    func updatingRTCNotificationID(_ rtcNotificationID: String) -> Self {
        dict[VoIPPushPayload.Key.rtcNotifyEventID.rawValue] = rtcNotificationID
        return self
    }
    
    func updatingReceiverID(_ receiverID: String) -> Self {
        dict[VoIPPushPayload.Key.receiverID.rawValue] = receiverID
        return self
    }
    
    func removingReceiverID() -> Self {
        dict[VoIPPushPayload.Key.receiverID.rawValue] = nil
        return self
    }
}
