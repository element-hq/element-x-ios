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
import ElementCall
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
        var isNative = false
    }
    
    private let appSettings: AppSettings
    private let pushRegistry: PKPushRegistry
    private let callController: CXCallControllerProtocol
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
    private var endPendingCallTask: Task<Void, Never>?
    
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
    
    /// The native call stack, for as long as there's a session running calls through it.
    private var nativeCallStack: NativeCallStack?
    private var nativeCallCancellable: AnyCancellable?
    private var mediaProvider: MediaProviderProtocol?
    
    var nativeCallController: ElementCallController? {
        nativeCallStack?.controller
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(appSettings: AppSettings,
         callProvider: CXProviderProtocol? = nil,
         callController: CXCallControllerProtocol? = nil,
         timeProvider: TimeProvider? = nil) {
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
        
        appSettings.nativeCallEnabledPublisher
            .sink { [weak self] _ in
                self?.updateNativeCallStack()
            }
            .store(in: &cancellables)
    }
    
    func setUserSession(_ userSession: UserSessionProtocol?) {
        // A stack is built against one client proxy and can't be handed to another, which is what a
        // soft logout or a cache clear brings: a new session without the sign out that drops this one.
        if userSession?.clientProxy !== clientProxy {
            stopNativeCallStack()
        }
        
        clientProxy = userSession?.clientProxy
        mediaProvider = userSession?.mediaProvider
        
        updateNativeCallStack()
    }
    
    @discardableResult
    func handleNativeCallRequest(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool) -> Bool {
        guard let nativeCallStack else {
            return false
        }
        
        nativeCallStack.handleCallRequest(roomProxy: roomProxy, isVoiceCall: isVoiceCall)
        return true
    }
    
    func minimizeNativeCall() {
        nativeCallStack?.minimize()
    }
    
    func restoreNativeCall() {
        nativeCallStack?.restore()
    }
    
    func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool) async {
        // Unlike the push handling below, this always runs with a session, so the stack itself is
        // the answer rather than the setting that would have built one.
        let isNative = nativeCallStack != nil
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
            return
        }
        
        // Answering the ringing call: it is already reported, keep it.
        guard !isAnsweringIncomingCall else {
            return
        }
        
        let handle = CXHandle(type: .generic, value: roomID)
        let startCallAction = CXStartCallAction(call: callID.callKitID, handle: handle)
        startCallAction.contactIdentifier = roomDisplayName
        startCallAction.isVideo = isVideo
        
        // Awaited because our membership goes out straight after: a peer that sees it before the
        // system knows about the call reads the call as answered elsewhere.
        await requestTransaction(CXTransaction(action: startCallAction), describedAs: "start call")
        
        // Without this the system call UI shows the handle, i.e. the room ID.
        let update = CXCallUpdate()
        update.localizedCallerName = roomDisplayName
        update.remoteHandle = handle
        update.hasVideo = isVideo
        callProvider.reportCall(with: callID.callKitID, updated: update)
    }
    
    func reportCallSessionConnected(roomID: String) {
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
    
    func tearDownCallSession(roomID: String) {
        if ongoingCallID?.roomID == roomID {
            tearDownCallSession(sendEndCallAction: true)
            return
        }
        
        // Answered and handed over, but the stack couldn't take it. Ending it here rather than
        // waiting for the watchdog takes the system call UI away straight away.
        if answeredNativeCallID?.roomID == roomID {
            MXLog.warning("Ending an answered call the native call stack didn't take over")
            endPendingCall()
            return
        }
        
        MXLog.info("Not tearing down the call session, no call for room \(roomID)")
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
    
    // MARK: - Native calls
    
    /// Builds or releases the call stack to match the session and the setting.
    private func updateNativeCallStack() {
        guard appSettings.nativeCallEnabled, let clientProxy else {
            stopNativeCallStack()
            return
        }
        
        guard nativeCallStack == nil else { return }
        
        guard let transport = clientProxy.makeNativeCallTransport() else {
            MXLog.error("Cannot start the native call stack without a transport")
            return
        }
        
        let style = ElementCallStyle(theme: NativeCallTheme(),
                                     icons: NativeCallIcons(),
                                     avatars: NativeCallAvatars(mediaProvider: mediaProvider),
                                     strings: .init(you: L10n.commonYou,
                                                    error: L10n.commonError,
                                                    stop: L10n.actionStop,
                                                    back: L10n.actionBack))
        
        // The stats overlay is raw RTP counters, so it follows whatever already reveals developer
        // surface. Screen sharing stays off until the broadcast extension that makes it work lands.
        let options = ElementCallOptions(isDeveloperModeEnabled: appSettings.developerOptionsEnabled)
        
        let stack = NativeCallStack(transport: transport,
                                    system: NativeCallSystem(service: self),
                                    options: options,
                                    style: style)
        nativeCallStack = stack
        
        nativeCallCancellable = stack.actions
            .sink { [weak self] presentation in
                self?.actionsSubject.send(.nativeCall(presentation))
            }
        
        Task { await stack.start() }
    }
    
    private func stopNativeCallStack() {
        guard let nativeCallStack else { return }
        self.nativeCallStack = nil
        nativeCallCancellable = nil
        
        nativeCallStack.stop()
        actionsSubject.send(.nativeCall(.dismiss))
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
        
        if appSettings.nativeCallEnabled {
            // The native stack owns media in this process, so the CallKit call stays up: the
            // controller attaches to it in `setupCallSession`.
            endUnansweredCallTask?.cancel()
            endCallIfLeftPending(incomingCallID)
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
            actionsSubject.send(.endCall(roomID: ongoingCallID.roomID))
            tearDownCallSession(sendEndCallAction: false)
        }
        
        if let incomingCallID, incomingCallID.callKitID == callKitID {
            Task {
                await sendDeclineCallEvent(incomingCallID)
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
    
    private func endPendingCall() {
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
        endPendingCallTask?.cancel()
        endPendingCallTask = nil
        answeredNativeCallID = nil
        declineListenerHandle?.cancel()
        declineListenerHandle = nil
        incomingCallRoomInfoCancellable = nil
        incomingCallID = nil
    }
}
