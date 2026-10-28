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
import PushKit
import UIKit

/// Keep this class testable
struct TimeProvider {
    var clock: any Clock<Duration>
    var now: () -> Date
}

final class ElementCallManager: NSObject, ElementCallManagerProtocol, PKPushRegistryDelegate, CXProviderDelegate {
    private struct CallID: Equatable {
        let callKitID: UUID
        let roomID: String
        let rtcNotificationID: String?
        let isVoiceCall: Bool
        var isNative = false
    }
    
    private let service: ElementCallServiceProtocol
    private let appSettings: AppSettings
    private let pushRegistry: PKPushRegistry
    private let callController: CXCallControllerProtocol
    private let callProvider: CXProviderProtocol
    private let timeProvider: TimeProvider
    
    private let actionsSubject = PassthroughSubject<ElementCallManagerAction, Never>()
    var actionsPublisher: AnyPublisher<ElementCallManagerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var incomingCallID: CallID? {
        didSet {
            guard incomingCallID != oldValue else { return }
            
            if oldValue != nil {
                service.stopObservingIncomingCall()
            }
            
            if let incomingCallID {
                Task { [weak self] in
                    guard let self, self.incomingCallID == incomingCallID else { return }
                    await service.observeIncomingCall(roomID: incomingCallID.roomID, rtcNotificationID: incomingCallID.rtcNotificationID)
                }
            }
        }
    }
    
    private var endUnansweredCallTask: Task<Void, Never>?
    /// The ringing call was answered for the web view, which has yet to set its call session up.
    private var isIncomingCallAnswered = false
    
    /// A call answered for the native stack, until the stack takes it over.
    private var answeredNativeCallID: CallID?
    private var endPendingCallTask: Task<Void, Never>?
    
    private var ongoingCallID: CallID? {
        didSet { service.ongoingCallChanged(roomID: ongoingCallID?.roomID) }
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(service: ElementCallServiceProtocol,
         appSettings: AppSettings,
         callProvider: CXProviderProtocol? = nil,
         callController: CXCallControllerProtocol? = nil,
         timeProvider: TimeProvider? = nil) {
        self.service = service
        self.appSettings = appSettings
        self.callController = callController ?? CXCallController()
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
        
        // Synchronous: a call screen's set-up waits on the reply, which a web call gets straight away.
        service.actionsPublisher
            .sink { [weak self] action in
                self?.handleServiceAction(action)
            }
            .store(in: &cancellables)
    }
    
    private func handleServiceAction(_ action: ElementCallServiceAction) {
        switch action {
        case let .callSessionStarted(roomID, roomDisplayName, isVideo, kind):
            setupCallSession(roomID: roomID, roomDisplayName: roomDisplayName, isVideo: isVideo, isNative: kind != .webView)
        case .callSessionConnected(let roomID):
            reportCallSessionConnected(roomID: roomID)
        case .callSessionEnded(let roomID, .none):
            tearDownCallSession(roomID: roomID)
        case .callSessionEnded(let roomID, .some(let reason)):
            reportCallSessionEnded(roomID: roomID, reason: reason)
        case let .audioEnabledChanged(enabled, roomID):
            setAudioEnabled(enabled, roomID: roomID)
        case let .incomingCallEnded(roomID, reason):
            incomingCallEnded(roomID: roomID, reason: reason)
        }
    }
    
    /// Replies to the service exactly once, when the call is set up: at once, or for a new native
    /// call once CallKit knows about it.
    private func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool, isNative: Bool) {
        MXLog.info("Setting up a call session, native: \(isNative), video: \(isVideo), replacing an ongoing call: \(ongoingCallID != nil)")
        
        // Drop any ongoing calls when starting a new one
        if ongoingCallID != nil {
            tearDownCallSession(sendEndCallAction: true)
        }
        
        // If this starting from a ring reuse those identifiers
        // Make sure the roomID matches
        var callID = if let incomingCallID, incomingCallID.roomID == roomID {
            incomingCallID
        } else {
            CallID(callKitID: UUID(), roomID: roomID, rtcNotificationID: nil, isVoiceCall: !isVideo)
        }
        callID.isNative = isNative
        let isAnsweringIncomingCall = callID.rtcNotificationID != nil
        
        clearIncomingCallState()
        ongoingCallID = callID
        
        // A web view call must not be tracked by CallKit, as that gives this process exclusive
        // access to media and the web view runs in another (see `CXAnswerCallAction`).
        // https://developer.apple.com/forums//thread/767949?answerId=812951022#812951022
        guard isNative else {
            service.callSessionSetUp(roomID: roomID, isAccepted: true)
            return
        }
        
        // Answering the ringing call: it is already reported, keep it.
        guard !isAnsweringIncomingCall else {
            service.callSessionSetUp(roomID: roomID, isAccepted: true)
            return
        }
        
        let handle = CXHandle(type: .generic, value: roomID)
        let startCallAction = CXStartCallAction(call: callID.callKitID, handle: handle)
        startCallAction.contactIdentifier = roomDisplayName
        startCallAction.isVideo = isVideo
        
        Task { [weak self, service] in
            // Awaited because our membership goes out straight after: a peer that sees it before the
            // system knows about the call reads the call as answered elsewhere.
            await self?.requestTransaction(CXTransaction(action: startCallAction), describedAs: "start call")
            
            // Without this the system call UI shows the handle, i.e. the room ID.
            let update = CXCallUpdate()
            update.localizedCallerName = roomDisplayName
            update.remoteHandle = handle
            update.hasVideo = isVideo
            self?.callProvider.reportCall(with: callID.callKitID, updated: update)
            
            service.callSessionSetUp(roomID: roomID, isAccepted: true)
        }
    }
    
    private func reportCallSessionConnected(roomID: String) {
        guard let ongoingCallID, ongoingCallID.roomID == roomID else {
            // The system ends an outgoing call that never reports connecting, so a silent guard
            // here shows up much later as a call that hangs itself up.
            MXLog.warning("Not reporting the call as connected, no matching ongoing call")
            return
        }
        
        guard ongoingCallID.isNative else {
            MXLog.info("Not reporting a web view call as connected, CallKit doesn't track it")
            return
        }
        
        MXLog.info("Reporting the call as connected")
        callProvider.reportOutgoingCall(with: ongoingCallID.callKitID, connectedAt: nil)
    }
    
    private func tearDownCallSession(roomID: String) {
        if ongoingCallID?.roomID == roomID {
            tearDownCallSession(sendEndCallAction: true)
            return
        }
        
        dropAnsweredCall(roomID: roomID)
    }
    
    func dropAnsweredCall(roomID: String) {
        // Answered and handed over, but the stack couldn't take it. Ending it here rather than
        // waiting for the watchdog takes the system call UI away straight away.
        if answeredNativeCallID?.roomID == roomID {
            MXLog.warning("Ending an answered call the native call stack didn't take over")
            endPendingCall()
            return
        }
        
        // Otherwise it would count as a call in progress, and every call after it would be missed.
        if isIncomingCallAnswered, incomingCallID?.roomID == roomID {
            MXLog.warning("Dropping an answered call that never opened")
            clearIncomingCallState()
            return
        }
        
        MXLog.info("Not dropping an answered call, none for room \(roomID)")
    }
    
    private func reportCallSessionEnded(roomID: String, reason: CallEndReason) {
        guard let ongoingCallID, ongoingCallID.roomID == roomID else {
            MXLog.info("Not reporting the end of a call for \(roomID), it isn't the ongoing call")
            return
        }
        
        // A web view call is not tracked by CallKit, as in `reportCallSessionConnected`.
        if ongoingCallID.isNative {
            MXLog.info("Reporting the call as ended without us: \(reason)")
            callProvider.reportCall(with: ongoingCallID.callKitID, endedAt: nil, reason: CXCallEndedReason(reason))
        }
        
        self.ongoingCallID = nil
    }
    
    private func setAudioEnabled(_ enabled: Bool, roomID: String) {
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
    
    /// The service saw the ringing call end elsewhere: hung up, or answered or declined on another device.
    private func incomingCallEnded(roomID: String, reason: CallEndReason) {
        guard let incomingCallID, incomingCallID.roomID == roomID else {
            MXLog.info("Not ending the incoming call, no call ringing for room \(roomID)")
            return
        }
        
        reportEndedCall(incomingCallID: incomingCallID, reason: CXCallEndedReason(reason))
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
        
        guard incomingCallID?.rtcNotificationID != rtcNotificationID else {
            MXLog.info("Already ringing for this call, reporting the duplicate push as handled")
            reportImmediatelyEndedCall(reason: .answeredElsewhere,
                                       callerInfo: (roomID: roomID, roomDisplayName: roomDisplayName),
                                       completion: completion)
            return
        }
        
        // An ongoing native call is tracked by CallKit, which offers its own call waiting.
        let isBusy = (incomingCallID != nil && answeredNativeCallID == nil) || ongoingCallID?.isNative == false
        guard !isBusy else {
            MXLog.info("Another call is ringing or ongoing, reporting the call for room \(roomID) as missed")
            reportImmediatelyEndedCall(reason: .unanswered,
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
        update.hasVideo = appSettings.nativeCallEnabled ? !isVoiceCall : true
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
                self?.actionsSubject.send(.incomingCallReported)
                
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
        service.systemEventReceived(.audioSessionActivated)
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        MXLog.info("Call provider did deactivate audio session")
        service.systemEventReceived(.audioSessionDeactivated)
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
        
        if appSettings.nativeCallEnabled {
            // The native stack owns media in this process, so the CallKit call stays up: the
            // controller attaches to it in `setupCallSession`.
            endUnansweredCallTask?.cancel()
            endCallIfLeftPending(incomingCallID)
            actionsSubject.send(.callAnswered(roomID: incomingCallID.roomID, isVoiceCall: incomingCallID.isVoiceCall))
            return
        }
        
        // Cancelled now rather than after the delay, by when it may belong to a call that rang since.
        endUnansweredCallTask?.cancel()
        isIncomingCallAnswered = true
        dropAnsweredCallIfItNeverOpens(incomingCallID)
        
        // And delay ending the call so that the app has enough time
        // to get deeplinked into
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Then end the and call rely on `setupCallSession` to create a new one
            provider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .remoteEnded)
            
            self.actionsSubject.send(.callAnswered(roomID: incomingCallID.roomID, isVoiceCall: incomingCallID.isVoiceCall))
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if ongoingCallID != nil {
            service.systemEventReceived(.microphoneMuteChanged(isMuted: action.isMuted))
        } else {
            MXLog.info("Ignoring a mute action without an ongoing call")
        }
        
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        #if targetEnvironment(simulator)
        // This gets called for no reason on simulators, where CallKit
        // isn't even supported, ignore it.
        #else
        endCall(withCallKitID: action.callUUID)
        action.fulfill()
        #endif
    }
    
    /// Ends the call the system identified, whether that's the ongoing one, the ringing one, or
    /// neither because it has already been replaced.
    ///
    /// Kept out of the delegate method so that it's reachable on the simulator, where the provider
    /// performs end call actions of its own and the delegate has to ignore them.
    func endCall(withCallKitID callKitID: UUID) {
        MXLog.info("Ending the call for \(callKitID), ongoing: \(ongoingCallID != nil), incoming: \(incomingCallID != nil)")
        
        // Both branches are gated on the identifier. Leaving a call to start one in another room
        // requests an end call action for the old call and replaces `ongoingCallID` before the
        // system gets round to performing it, so an ungated handler reads it as the new call ending
        // and hangs up the call that was just started.
        if let ongoingCallID, ongoingCallID.callKitID == callKitID {
            service.systemEventReceived(.endCallRequested(roomID: ongoingCallID.roomID))
            tearDownCallSession(sendEndCallAction: false)
        }
        
        if let incomingCallID, incomingCallID.callKitID == callKitID {
            if let rtcNotificationID = incomingCallID.rtcNotificationID {
                Task { [service] in
                    await service.declineCall(roomID: incomingCallID.roomID, rtcNotificationID: rtcNotificationID)
                }
            } else {
                MXLog.info("No rtc notification event to decline.")
            }
            
            clearIncomingCallState()
        }
    }
    
    // MARK: - Private
    
    /// Bridges the controller's completion handler, which is all ``CXCallControllerProtocol`` can
    /// carry, back to an awaitable call.
    private func requestTransaction(_ transaction: CXTransaction, describedAs description: String) async {
        await withCheckedContinuation { continuation in
            callController.request(transaction) { error in
                if let error {
                    MXLog.error("Failed requesting \(description) action with error: \(error)")
                }
                
                continuation.resume()
            }
        }
    }
    
    private func tearDownCallSession(sendEndCallAction: Bool = true) {
        if sendEndCallAction, let ongoingCallID {
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
    
    /// Ends an answered call that the native stack never took over, which nothing else would: the
    /// call is deliberately left up for the controller to attach to in `setupCallSession`.
    private func endCallIfLeftPending(_ callID: CallID) {
        answeredNativeCallID = callID
        
        endPendingCallTask = Task { [weak self] in
            try? await self?.timeProvider.clock.sleep(for: .seconds(30))
            
            guard let self, !Task.isCancelled, answeredNativeCallID == callID else {
                return
            }
            
            MXLog.error("The native call stack never took over the answered call, ending it")
            endPendingCall()
        }
    }
    
    /// Drops a call answered for the web view that no call screen took over, e.g. one answered while signed out.
    private func dropAnsweredCallIfItNeverOpens(_ callID: CallID) {
        endPendingCallTask = Task { [weak self] in
            try? await self?.timeProvider.clock.sleep(for: .seconds(30))
            
            guard let self, !Task.isCancelled, isIncomingCallAnswered, incomingCallID == callID else {
                return
            }
            
            MXLog.error("No call screen took over the answered call, dropping it")
            clearIncomingCallState()
        }
    }
    
    private func endPendingCall() {
        guard let answeredNativeCallID else {
            return
        }
        
        callProvider.reportCall(with: answeredNativeCallID.callKitID, endedAt: nil, reason: .failed)
        clearIncomingCallState()
    }
    
    private func reportEndedCall(incomingCallID: CallID, reason: CXCallEndedReason) {
        callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: reason)
        clearIncomingCallState()
    }
    
    /// Cancels every task tied to a ringing incoming call and nils `incomingCallID`, which stops the
    /// service watching its room. Call this on every path that ends the incoming-call state (answered,
    /// declined, timed out, cancelled by remote, answered/declined elsewhere) so that follow-up calls
    /// to the same room start from a clean slate and the SDK decline-listener subscription doesn't leak.
    private func clearIncomingCallState() {
        endUnansweredCallTask?.cancel()
        endUnansweredCallTask = nil
        endPendingCallTask?.cancel()
        endPendingCallTask = nil
        answeredNativeCallID = nil
        isIncomingCallAnswered = false
        incomingCallID = nil
    }
}

private extension CXCallEndedReason {
    init(_ reason: CallEndReason) {
        self = switch reason {
        case .remoteEnded:
            .remoteEnded
        case .answeredElsewhere:
            .answeredElsewhere
        case .declinedElsewhere:
            .declinedElsewhere
        case .unanswered:
            .unanswered
        case .failed:
            .failed
        }
    }
}
