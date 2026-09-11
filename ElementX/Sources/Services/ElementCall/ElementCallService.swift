//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import CallKit
import Combine
import Foundation
import MatrixRustSDK
import PushKit
import UIKit

/// Keep this class testable
struct TimeProvider {
    var clock: any Clock<Duration>
    var now: () -> Date
}

class ElementCallService: NSObject, ElementCallServiceProtocol, PKPushRegistryDelegate, CXProviderDelegate {
    private struct CallID: Equatable {
        let callKitID: UUID
        let roomID: String
        let rtcNotificationID: String?
        let isVoiceCall: Bool
        /// A native call keeps its CallKit call alive; a web view call must not (see `CXAnswerCallAction`).
        var isNative = false
    }
    
    private var isNativeCallModeEnabled = false
    
    func setNativeCallModeEnabled(_ enabled: Bool) {
        isNativeCallModeEnabled = enabled
    }
    
    private let pushRegistry: PKPushRegistry
    private let callController = CXCallController()
    private let callProvider: CXProviderProtocol
    private let timeProvider: TimeProvider
    
    private weak var clientProxy: ClientProxyProtocol? {
        didSet {
            // There's a race condition where a call starts when the app has been killed and the
            // observation set in `incomingCallID` occurs *before* the user session is restored.
            // So observe when the client proxy is set to fix this (the method guards for the call).
            Task { await observeIncomingCall() }
        }
    }
    
    private var incomingCallRoomInfoCancellable: AnyCancellable?
    private var incomingCallID: CallID? {
        didSet {
            Task { await observeIncomingCall() }
        }
    }
    
    private var endUnansweredCallTask: Task<Void, Never>?
    
    /// A call answered for the native stack, until the stack takes it over.
    private var answeredNativeCallID: CallID?
    private var endUnattachedCallTask: Task<Void, Never>?
    
    private var ongoingCallID: CallID? {
        didSet { ongoingCallRoomIDSubject.send(ongoingCallID?.roomID) }
    }
    
    let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(nil)
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        ongoingCallRoomIDSubject.asCurrentValuePublisher()
    }
    
    private let actionsSubject: PassthroughSubject<ElementCallServiceAction, Never> = .init()
    var actions: AnyPublisher<ElementCallServiceAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var declineListenerHandle: TaskHandle?
    
    init(callProvider: CXProviderProtocol? = nil, timeProvider: TimeProvider? = nil) {
        pushRegistry = PKPushRegistry(queue: nil)
        
        self.timeProvider = timeProvider ?? TimeProvider(clock: ContinuousClock(), now: Date.init)
        
        if let callProvider {
            self.callProvider = callProvider
        } else {
            let configuration = CXProviderConfiguration()
            configuration.supportsVideo = true
            configuration.includesCallsInRecents = true
            
            if let callKitIcon = UIImage(named: "images/app-logo") {
                configuration.iconTemplateImageData = callKitIcon.pngData()
            }
            
            // https://stackoverflow.com/a/46077628/730924
            configuration.supportedHandleTypes = [.generic]
            
            self.callProvider = CXProvider(configuration: configuration)
        }
        
        super.init()
        
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
        
        self.callProvider.setDelegate(self, queue: nil)
    }
    
    func setClientProxy(_ clientProxy: any ClientProxyProtocol) {
        self.clientProxy = clientProxy
    }
    
    func setupCallSession(roomID: String, roomDisplayName: String) async {
        // Drop any ongoing calls when starting a new one
        if ongoingCallID != nil {
            tearDownCallSession()
        }
        
        // If this starting from a ring reuse those identifiers
        // Make sure the roomID matches
        let callID = if let incomingCallID, incomingCallID.roomID == roomID {
            incomingCallID
        } else {
            CallID(callKitID: UUID(), roomID: roomID, rtcNotificationID: nil, isVoiceCall: false)
        }
        
        clearIncomingCallState()
        ongoingCallID = callID
        
        // Don't bother starting another CallKit session as it won't work properly
        // https://developer.apple.com/forums//thread/767949?answerId=812951022#812951022
        
        // let handle = CXHandle(type: .generic, value: roomDisplayName)
        // let startCallAction = CXStartCallAction(call: callID.callKitID, handle: handle)
        // startCallAction.isVideo = true
        
        // do {
        //     try await callController.request(CXTransaction(action: startCallAction))
        // } catch {
        //     MXLog.error("Failed requesting start call action with error: \(error)")
        // }
    }
    
    func tearDownCallSession() {
        tearDownCallSession(sendEndCallAction: true)
    }
    
    // MARK: - Native calls
    
    func startNativeCallSession(roomID: String, roomDisplayName: String, isVideo: Bool) async {
        MXLog.info("Starting a native call session, video: \(isVideo), replacing an ongoing call: \(ongoingCallID != nil)")
        
        if ongoingCallID != nil {
            tearDownCallSession()
        }
        
        if let incomingCallID, incomingCallID.roomID == roomID {
            // Answering the ringing call: it is already reported, keep it.
            var callID = incomingCallID
            callID.isNative = true
            clearIncomingCallState()
            ongoingCallID = callID
            return
        }
        
        let callID = CallID(callKitID: UUID(), roomID: roomID, rtcNotificationID: nil, isVoiceCall: !isVideo, isNative: true)
        clearIncomingCallState()
        ongoingCallID = callID
        
        let handle = CXHandle(type: .generic, value: roomID)
        let startCallAction = CXStartCallAction(call: callID.callKitID, handle: handle)
        startCallAction.contactIdentifier = roomDisplayName
        startCallAction.isVideo = isVideo
        
        do {
            try await callController.request(CXTransaction(action: startCallAction))
        } catch {
            MXLog.error("Failed requesting start call action with error: \(error)")
        }
        
        // Without this the system call UI shows the handle, i.e. the room ID.
        let update = CXCallUpdate()
        update.localizedCallerName = roomDisplayName
        update.remoteHandle = handle
        update.hasVideo = isVideo
        callProvider.reportCall(with: callID.callKitID, updated: update)
    }
    
    func reportNativeCallConnected(roomID: String) {
        guard let ongoingCallID, ongoingCallID.roomID == roomID, ongoingCallID.isNative else {
            // The system ends an outgoing call that never reports connecting, so a silent guard
            // here shows up much later as a call that hangs itself up.
            MXLog.warning("Not reporting a native call as connected, no matching ongoing call")
            return
        }
        MXLog.info("Reporting the native call as connected")
        callProvider.reportOutgoingCall(with: ongoingCallID.callKitID, connectedAt: nil)
    }
    
    func endNativeCallSession(roomID: String) {
        if ongoingCallID?.roomID == roomID {
            tearDownCallSession(sendEndCallAction: true)
            return
        }
        
        // Answered and handed over, but the stack couldn't take it. Ending it here rather than
        // waiting for the watchdog takes the system call UI away straight away.
        if answeredNativeCallID?.roomID == roomID {
            MXLog.warning("Ending an answered call the native call stack didn't take over")
            endUnattachedCall()
        }
    }
    
    func setAudioEnabled(_ enabled: Bool, roomID: String) {
        guard let ongoingCallID else {
            MXLog.error("Failed toggling call microphone, no calls running")
            return
        }
        
        guard ongoingCallID.roomID == roomID else {
            MXLog.error("Failed toggling call microphone, rooms don't match: \(ongoingCallID.roomID) != \(roomID)")
            return
        }
        
        let transaction = CXTransaction(action: CXSetMutedCallAction(call: ongoingCallID.callKitID, muted: !enabled))
        callController.request(transaction) { error in
            if let error {
                MXLog.error("Failed toggling call microphone with error: \(error)")
            }
        }
    }
    
    // MARK: - PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) { }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard let roomID = payload.dictionaryPayload[ElementCallServiceNotificationKey.roomID.rawValue] as? String else {
            MXLog.error("Something went wrong, missing room identifier for incoming voip call: \(payload)")
            assertionFailure("Incoming voip push is missing the room identifier")
            reportImmediatelyEndedCall(reason: .failed, completion: completion)
            return
        }
        
        guard let rtcNotificationID = payload.dictionaryPayload[ElementCallServiceNotificationKey.rtcNotifyEventID.rawValue] as? String else {
            MXLog.error("Something went wrong, missing rtc notification event identifier for incoming voip call: \(payload)")
            assertionFailure("Incoming voip push is missing the rtc notification event identifier")
            reportImmediatelyEndedCall(reason: .failed, completion: completion)
            return
        }
        
        let roomDisplayName = payload.dictionaryPayload[ElementCallServiceNotificationKey.roomDisplayName.rawValue] as? String
        
        guard ongoingCallID?.roomID != roomID else {
            MXLog.warning("Call already ongoing for room \(roomID), reporting the duplicate push as handled")
            reportImmediatelyEndedCall(reason: .answeredElsewhere,
                                       callerInfo: (roomID: roomID, roomDisplayName: roomDisplayName),
                                       completion: completion)
            return
        }
        
        let isVoiceCall = payload.dictionaryPayload[ElementCallServiceNotificationKey.isVoiceCall.rawValue] as? Bool ?? false
        
        let callID = CallID(callKitID: UUID(), roomID: roomID, rtcNotificationID: rtcNotificationID, isVoiceCall: isVoiceCall)
        incomingCallID = callID
        
        guard let expirationDate = (payload.dictionaryPayload[ElementCallServiceNotificationKey.expirationDate.rawValue] as? Date) else {
            MXLog.error("Something went wrong, missing expiration timestamp for incoming voip call: \(payload)")
            assertionFailure("Incoming voip push is missing the expiration timestamp")
            clearIncomingCallState()
            reportImmediatelyEndedCall(reason: .failed, completion: completion)
            return
        }
        
        let nowDate = timeProvider.now()
        
        guard nowDate < expirationDate else {
            MXLog.warning("Call expired for room \(roomID), reporting it as missed")
            clearIncomingCallState()
            reportImmediatelyEndedCall(reason: .unanswered,
                                       callerInfo: (roomID: roomID, roomDisplayName: roomDisplayName),
                                       completion: completion)
            return
        }
        
        let ringDuration: Duration = .seconds(min(expirationDate.timeIntervalSince1970 - nowDate.timeIntervalSince1970, 90))
        
        let update = CXCallUpdate()
        // Work Around: Always set video to true! https://github.com/element-hq/element-x-ios/issues/5335
        // If not for audio call the app will not be put to foreground and the webview won't be able to handle the call...
        // Consequence: The call will be presented to the user as a video call in CallKit UI,
        // but once Element Call is launched it will correctly route to a voice-only call.
        // The native stack streams from the background like any VoIP app, so an audio call answered
        // from the lock screen stays in the system UI and only a video call opens the app.
        update.hasVideo = isNativeCallModeEnabled ? !isVoiceCall : true
        update.localizedCallerName = roomDisplayName
        // https://stackoverflow.com/a/41230020/730924
        update.remoteHandle = .init(type: .generic, value: roomID)
        
        // The push registry uses the main queue so the completion is main actor bound,
        // whereas CallKit invokes its completion on a background queue.
        let mainActorCompletion = { @MainActor @Sendable in completion() }
        callProvider.reportNewIncomingCall(with: callID.callKitID, update: update) { [weak self] error in
            if let error {
                MXLog.error("Failed reporting new incoming call with error: \(error)")
            }
            
            Task { @MainActor in
                self?.actionsSubject.send(.receivedIncomingCallRequest)
                
                mainActorCompletion()
            }
        }
        
        endUnansweredCallTask = Task { [weak self] in
            try? await self?.timeProvider.clock.sleep(for: ringDuration)
            
            guard let self, !Task.isCancelled else {
                return
            }
            
            if let incomingCallID, incomingCallID.callKitID == callID.callKitID {
                callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .unanswered)
                clearIncomingCallState()
            }
        }
    }
    
    // MARK: - CXProviderDelegate
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        MXLog.info("Call provider did activate audio session")
        actionsSubject.send(.audioSessionActivated)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        MXLog.info("Call provider did deactivate audio session")
        actionsSubject.send(.audioSessionDeactivated)
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        // The native controller configured the audio session already; CallKit activates it and
        // reports back through `didActivate`.
        action.fulfill()
        callProvider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
    }
    
    func providerDidReset(_ provider: CXProvider) {
        MXLog.info("Call provider did reset: \(provider)")
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        guard let incomingCallID else {
            MXLog.error("Failed answering incoming call, missing incomingCallID")
            return
        }
        
        // Fixes broken videos on EC web when a CallKit session is established.
        //
        // Reporting an ongoing call through `reportNewIncomingCall` + `CXAnswerCallAction`
        // or `reportOutgoingCall:connectedAt:` will give exclusive access for media to the
        // ongoing process, which is different than the WKWebKit is running on, making EC
        // unable to aquire media streams.
        // Reporting the call as ended imediately after answering it works around that
        // as EC gets access to media again and EX builds the right UI in `setupCallSession`
        //
        // https://developer.apple.com/forums//thread/767949?answerId=812951022#812951022
        //
        // https://github.com/element-hq/element-x-ios/issues/3041
        // https://forums.developer.apple.com/forums/thread/685268
        // https://stackoverflow.com/questions/71483732/webrtc-running-from-wkwebview-avaudiosession-development-roadblock
        
        // First fullfill the action
        action.fulfill()
        
        if isNativeCallModeEnabled {
            // The native stack owns media in this process, so the CallKit call stays up: the
            // controller attaches to it in `startNativeCallSession`.
            endUnansweredCallTask?.cancel()
            endCallIfLeftUnattached(incomingCallID)
            actionsSubject.send(.startCall(roomID: incomingCallID.roomID, isVoiceCall: incomingCallID.isVoiceCall))
            return
        }
        
        // And delay ending the call so that the app has enough time
        // to get deeplinked into
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Then end the and call rely on `setupCallSession` to create a new one
            provider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .remoteEnded)
            
            self.actionsSubject.send(.startCall(roomID: incomingCallID.roomID, isVoiceCall: incomingCallID.isVoiceCall))
            self.endUnansweredCallTask?.cancel()
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if let ongoingCallID {
            actionsSubject.send(.setAudioEnabled(!action.isMuted, roomID: ongoingCallID.roomID))
        } else {
            // CallKit un-mutes a call as it ends, so this is expected right after a hang-up.
            MXLog.info("Ignoring a mute action without an ongoing call")
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        #if targetEnvironment(simulator)
        // This gets called for no reason on simulators, where CallKit
        // isn't even supported, ignore it.
        #else
        // Logged because the system ends a call for reasons of its own, and a native call that
        // disappears looks like the app's doing until you can see this line.
        MXLog.info("Call provider performed an end call action, ongoing: \(ongoingCallID != nil), incoming: \(incomingCallID != nil)")
        
        if let ongoingCallID {
            actionsSubject.send(.endCall(roomID: ongoingCallID.roomID))
        }
        
        if let incomingCallID {
            Task {
                await sendDeclineCallEvent(incomingCallID)
            }
        }
        
        if incomingCallID?.callKitID == action.callUUID {
            clearIncomingCallState()
        }
        
        tearDownCallSession(sendEndCallAction: false)
        
        action.fulfill()
        #endif
    }
    
    // MARK: - Private
    
    private func tearDownCallSession(sendEndCallAction: Bool = true) {
        if sendEndCallAction, let ongoingCallID {
            // Logged so that the end call action the provider performs next can be told apart from
            // one the system raised by itself, which otherwise look identical.
            MXLog.info("Requesting an end call action for the ongoing call")
            let transaction = CXTransaction(action: CXEndCallAction(call: ongoingCallID.callKitID))
            callController.request(transaction) { error in
                if let error {
                    MXLog.error("Failed transaction with error: \(error)")
                }
            }
        }
        
        ongoingCallID = nil
    }
    
    /// Every VoIP push must be reported to CallKit via `reportNewIncomingCall`, otherwise iOS
    /// terminates the app with `NSInternalInconsistencyException`. On early-return paths we report
    /// a call and immediately end it. `callerInfo` names the call after the room so the brief
    /// system UI and the Recents entry show the room rather than "Unknown", and the entry can be
    /// tapped to call back.
    private func reportImmediatelyEndedCall(reason: CXCallEndedReason,
                                            callerInfo: (roomID: String, roomDisplayName: String?)? = nil,
                                            completion: @escaping () -> Void) {
        let callID = UUID()
        let update = CXCallUpdate()
        // Never answered through CallKit, so the hasVideo workaround for #5335 isn't needed.
        update.hasVideo = false
        
        if let callerInfo {
            update.localizedCallerName = callerInfo.roomDisplayName
            update.remoteHandle = .init(type: .generic, value: callerInfo.roomID)
        }
        
        // CallKit invokes the completion on a background queue, so hop back to the main actor
        // to report the ended call and to run the (main actor bound) completion.
        let mainActorCompletion = { @MainActor @Sendable in completion() }
        callProvider.reportNewIncomingCall(with: callID, update: update) { [weak self] error in
            if let error {
                MXLog.error("Failed reporting immediately ended call with error: \(error)")
            }
            
            Task { @MainActor in
                self?.callProvider.reportCall(with: callID, endedAt: nil, reason: reason)
                mainActorCompletion()
            }
        }
    }
    
    /// Ends an answered call that the native stack never took over.
    ///
    /// Nothing else would. The call is deliberately left up for the controller to attach to in
    /// `startNativeCallSession`, so any way that hand-off falls through — the room isn't joined,
    /// there's no transport, another call is already running — leaves the system showing a call
    /// the app knows nothing about and can no longer hang up.
    private func endCallIfLeftUnattached(_ callID: CallID) {
        answeredNativeCallID = callID
        
        endUnattachedCallTask = Task { [weak self] in
            try? await self?.timeProvider.clock.sleep(for: .seconds(30))
            
            guard let self, !Task.isCancelled, answeredNativeCallID == callID else {
                return
            }
            
            MXLog.error("The native call stack never took over the answered call, ending it")
            endUnattachedCall()
        }
    }
    
    private func endUnattachedCall() {
        guard let answeredNativeCallID else {
            return
        }
        
        callProvider.reportCall(with: answeredNativeCallID.callKitID, endedAt: nil, reason: .failed)
        clearIncomingCallState()
    }
    
    private func sendDeclineCallEvent(_ incomingCallID: CallID) async {
        guard let rtcNotificationID = incomingCallID.rtcNotificationID else {
            MXLog.info("No rtc notification event to decline.")
            return
        }
        
        guard let clientProxy else {
            MXLog.warning("A ClientProxy is needed to fetch the room.")
            return
        }
        
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(incomingCallID.roomID) else {
            MXLog.warning("Failed to fetch a joined room for the incoming call.")
            return
        }
        
        _ = await roomProxy.declineCall(notificationID: rtcNotificationID)
    }
    
    private func observeIncomingCall() async {
        incomingCallRoomInfoCancellable = nil
        
        guard let incomingCallID else {
            MXLog.info("No incoming call to observe for.")
            return
        }
        
        guard let clientProxy else {
            MXLog.warning("A ClientProxy is needed to fetch the room.")
            return
        }
        
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(incomingCallID.roomID) else {
            MXLog.warning("Failed to fetch a joined room for the incoming call.")
            return
        }
        
        roomProxy.subscribeToRoomInfoUpdates()
        
        incomingCallRoomInfoCancellable = roomProxy
            .infoPublisher
            .compactMap { ($0.hasRoomCall, $0.activeRoomCallParticipants) }
            .removeDuplicates { $0 == $1 }
            .drop { hasRoomCall, _ in
                // Filter all updates before hasRoomCall becomes `true`. Then we can correctly
                // detect its change to `false` to stop ringing when the caller hangs up.
                !hasRoomCall
            }
            .sink { [weak self] hasOngoingCall, activeRoomCallParticipants in
                guard let self else { return }
                
                let participants: [String] = activeRoomCallParticipants
                
                if !hasOngoingCall {
                    MXLog.info("Call cancelled by remote")
                    reportEndedCall(incomingCallID: incomingCallID, reason: .remoteEnded)
                } else if participants.contains(roomProxy.ownUserID) {
                    MXLog.info("Call answered elsewhere")
                    reportEndedCall(incomingCallID: incomingCallID, reason: .answeredElsewhere)
                }
            }
        
        guard let rtcNotificationID = incomingCallID.rtcNotificationID else {
            MXLog.warning("Decline: No RTC notification ID found for the incoming call.")
            return
        }
        
        MXLog.info("Observe decline events for notification \(rtcNotificationID)")
        
        let listener: CallDeclineListener = SDKListener.onMainActor { [weak self] senderID in
            guard let self else { return }
            
            MXLog.debug("Call declined event received from \(senderID)")
            
            if senderID == roomProxy.ownUserID {
                // Stop ringing!
                MXLog.debug("Call declined elsewhere")
                reportEndedCall(incomingCallID: incomingCallID, reason: .declinedElsewhere)
            }
        }
        
        guard case let .success(handle) = roomProxy.subscribeToCallDeclineEvents(rtcNotificationEventID: rtcNotificationID, listener: listener) else {
            MXLog.error("Unable to listen for decline events.")
            return
        }
        
        declineListenerHandle = handle
    }
    
    private func reportEndedCall(incomingCallID: CallID, reason: CXCallEndedReason) {
        callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: reason)
        clearIncomingCallState()
    }
    
    /// Cancels every subscription and task tied to a ringing incoming call and nils `incomingCallID`.
    /// Call this on every path that ends the incoming-call state (answered, declined, timed out,
    /// cancelled by remote, answered/declined elsewhere) so that follow-up calls to the same room
    /// start from a clean slate and the SDK decline-listener subscription doesn't leak.
    private func clearIncomingCallState() {
        endUnansweredCallTask?.cancel()
        endUnansweredCallTask = nil
        endUnattachedCallTask?.cancel()
        endUnattachedCallTask = nil
        answeredNativeCallID = nil
        declineListenerHandle?.cancel()
        declineListenerHandle = nil
        incomingCallRoomInfoCancellable = nil
        incomingCallID = nil
    }
}
