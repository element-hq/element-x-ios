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
        let userID: String
        let roomID: String
        let rtcNotificationID: String?
        let isVoiceCall: Bool
        var isNative = false
    }
    
    /// The call the call screen shows, from when it's presented until its screen goes away.
    private enum PresentedCall: Equatable {
        case webView(userID: String, roomID: String)
        case native(userID: String)
        
        var userID: String {
            switch self {
            case .webView(let userID, _), .native(let userID): userID
            }
        }
    }
    
    /// A call requested by room ID, from CallKit or Recents, whose room still has to be loaded.
    private struct CallRequest: Equatable {
        let userID: String
        let roomID: String
        let isVoiceCall: Bool
        let answeredFromCallKit: Bool
    }
    
    private let appSettings: AppSettings
    private let pushRegistry: PKPushRegistry
    private let callController: CXCallControllerProtocol
    private let callProvider: CXProviderProtocol
    private let timeProvider: TimeProvider
    
    private let actionsSubject = PassthroughSubject<ElementCallManagerAction, Never>()
    var actionsPublisher: AnyPublisher<ElementCallManagerAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    /// Every signed-in account's call service, by user ID.
    private var services: [String: ElementCallServiceProtocol] = [:]
    private var serviceCancellables: [String: AnyCancellable] = [:]
    
    private var incomingCallID: CallID? {
        didSet {
            guard incomingCallID != oldValue else { return }
            
            if let oldValue {
                services[oldValue.userID]?.stopObservingIncomingCall()
            }
            
            if let incomingCallID {
                observeIncomingCall(incomingCallID)
            }
        }
    }
    
    /// A ringing call declined before its account's service was added, sent once it is.
    private var pendingDecline: CallID?
    
    private var endUnansweredCallTask: Task<Void, Never>?
    /// The ringing call was answered for the web view, which has yet to set its call session up.
    private var isIncomingCallAnswered = false
    
    /// A call answered for the native stack, until the stack takes it over.
    private var answeredNativeCallID: CallID?
    private var endPendingCallTask: Task<Void, Never>?
    
    private var isAudioSessionActive = false
    
    private var presentedCall: PresentedCall?
    /// A call request waiting for its account's service to be added. One at a time, a newer one drops it unless it's for the same call.
    private var pendingCallRequest: CallRequest?
    
    /// The incoming call while nobody has answered it.
    private var ringingCallID: CallID? {
        guard !isIncomingCallAnswered, incomingCallID != answeredNativeCallID else { return nil }
        return incomingCallID
    }
    
    private var ongoingCallID: CallID? {
        didSet {
            if let oldValue, oldValue.userID != ongoingCallID?.userID {
                services[oldValue.userID]?.ongoingCallChanged(roomID: nil)
            }
            
            if let ongoingCallID {
                services[ongoingCallID.userID]?.ongoingCallChanged(roomID: ongoingCallID.roomID)
            }
        }
    }
    
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
    }
    
    func add(_ service: ElementCallServiceProtocol) {
        let userID = service.userID
        if let replacedService = services[userID], replacedService !== service {
            // While the old service is still registered, so it hears its call is gone.
            endOngoingCall(userID: userID)
            dismissCallScreen(of: userID)
            replacedService.stopObservingIncomingCall()
        }
        
        services[userID] = service
        
        // Synchronous: a call screen's set-up waits on the reply, which a web call gets straight away.
        // Replacing the entry cancels a replaced service's subscription.
        serviceCancellables[userID] = service.actionsPublisher
            .sink { [weak self, weak service] action in
                guard let self, let service else { return }
                process(action, from: service)
            }
        
        // A VoIP push can wake the app before the account's session is restored.
        if let incomingCallID, incomingCallID.userID == userID {
            observeIncomingCall(incomingCallID)
        }
        
        if let pendingDecline, pendingDecline.userID == userID {
            self.pendingDecline = nil
            decline(pendingDecline)
        }
        
        // A lock-screen answer at cold launch activates the audio before the account's service is added.
        if isAudioSessionActive {
            service.systemEventReceived(.audioSessionActivated)
        }
        
        if let pendingCallRequest, pendingCallRequest.userID == userID {
            // Deferred, as the account's screens start in the same step that adds its service.
            Task { [weak self] in await self?.handlePendingCallRequest(pendingCallRequest) }
        }
    }
    
    func remove(userID: String) {
        // First, so the service hears its calls end.
        endCalls(userID: userID)
        
        serviceCancellables[userID] = nil
        services[userID] = nil
    }
    
    /// Ends the account's calls and takes their screen down, still routing its calls.
    private func endCalls(userID: String) {
        if let pendingCallRequest, pendingCallRequest.userID == userID {
            self.pendingCallRequest = nil
            dropCallRequest(pendingCallRequest, because: "\(userID)'s calls were ended")
        }
        
        if let incomingCallID, incomingCallID.userID == userID {
            // An answered web view call is reported by its hand-over, which then finds nothing to open.
            if !isIncomingCallAnswered {
                callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .failed)
            }
            
            clearIncomingCallState()
        }
        
        if pendingDecline?.userID == userID {
            pendingDecline = nil
        }
        
        endOngoingCall(userID: userID)
        dismissCallScreen(of: userID)
    }
    
    func requestCall(userID: String, roomID: String, isVoiceCall: Bool, answeredFromCallKit: Bool) {
        let request = CallRequest(userID: userID, roomID: roomID, isVoiceCall: isVoiceCall, answeredFromCallKit: answeredFromCallKit)
        
        guard let service = services[userID] else {
            storePendingCallRequest(request)
            return
        }
        
        Task { await handleCallRequest(request, service: service) }
    }
    
    private func process(_ action: ElementCallServiceAction, from service: ElementCallServiceProtocol) {
        switch action {
        case .callRequested(let call):
            presentCallScreen(for: call, answeredFromCallKit: false, service: service)
        case .callMinimizeRequested:
            minimizeCall()
        case .callsEndRequested:
            endCalls(userID: service.userID)
        case .nativeCallPresentation(let presentation):
            relayNativeCallPresentation(presentation, from: service)
        case let .callSessionStarted(roomID, roomDisplayName, isVideo, kind):
            setupCallSession(roomID: roomID, roomDisplayName: roomDisplayName, isVideo: isVideo, kind: kind, service: service)
        case .callSessionConnected(let roomID):
            reportCallSessionConnected(userID: service.userID, roomID: roomID)
        case .callSessionEnded(let roomID, let reason):
            // Only a web view call's screen ends its session as it goes, the native stack dismisses its own.
            if presentedCall == .webView(userID: service.userID, roomID: roomID) {
                presentedCall = nil
            }
            
            if let reason {
                reportCallSessionEnded(userID: service.userID, roomID: roomID, reason: reason)
            } else {
                tearDownCallSession(userID: service.userID, roomID: roomID)
            }
        case let .audioEnabledChanged(enabled, roomID):
            setAudioEnabled(enabled, userID: service.userID, roomID: roomID)
        case let .incomingCallEnded(roomID, reason):
            incomingCallEnded(userID: service.userID, roomID: roomID, reason: reason)
        }
    }
    
    /// Makes the service's call the ongoing one, ending any previous call and reporting a new native
    /// call to CallKit. Replies to the service exactly once: straight away, or for a new native call
    /// once CallKit knows about it, refusing it if the call went in the meantime.
    private func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool, kind: ElementCallSessionKind, service: ElementCallServiceProtocol) {
        let isNative = kind != .webView
        MXLog.info("Setting up a call session, kind: \(kind), video: \(isVideo), replacing an ongoing call: \(ongoingCallID != nil)")
        
        let answeredCallID = answeredCallID(userID: service.userID, roomID: roomID, kind: kind)
        
        // The answered call ended before the native call stack took it over. Starting it as a new
        // call would ring the caller back.
        if case .native(takesOverAnsweredCall: true) = kind, answeredCallID == nil {
            MXLog.info("Refusing to set up an answered call that has ended")
            // Another account's answer in this room, which no account here can take over.
            if let answeredNativeCallID, answeredNativeCallID.roomID == roomID {
                MXLog.warning("Ending another account's answered call")
                endPendingCall()
            }
            service.callSessionSetUp(roomID: roomID, isAccepted: false)
            return
        }
        
        // Drop any ongoing calls when starting a new one
        if ongoingCallID != nil {
            tearDownCallSession(sendEndCallAction: true)
        }
        
        // Answering keeps the call CallKit already shows rather than reporting a new one.
        var callID = answeredCallID
            ?? CallID(callKitID: UUID(), userID: service.userID, roomID: roomID, rtcNotificationID: nil, isVoiceCall: !isVideo)
        callID.isNative = isNative
        let isAnsweringIncomingCall = callID.rtcNotificationID != nil
        
        endIncomingCall(notTakenOverBy: answeredCallID, roomID: roomID)
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
            
            guard let self, ongoingCallID?.callKitID == callID.callKitID else {
                MXLog.warning("The call was removed, replaced or ended while starting, refusing its set-up")
                // An end reported before the start landed was a no-op, so the system call UI would stay up.
                self?.callProvider.reportCall(with: callID.callKitID, endedAt: nil, reason: .failed)
                service.callSessionSetUp(roomID: roomID, isAccepted: false)
                return
            }
            
            // Without this the system call UI shows the handle, i.e. the room ID.
            let update = CXCallUpdate()
            update.localizedCallerName = roomDisplayName
            update.remoteHandle = handle
            update.hasVideo = isVideo
            callProvider.reportCall(with: callID.callKitID, updated: update)
            
            service.callSessionSetUp(roomID: roomID, isAccepted: true)
        }
    }
    
    /// The account's answered call in the room that a set-up of this kind takes over. A call that still
    /// rings is never taken over: its ring would stay up, and declining it would hang up the call.
    private func answeredCallID(userID: String, roomID: String, kind: ElementCallSessionKind) -> CallID? {
        let callID: CallID? = switch kind {
        case .native(let takesOverAnsweredCall): takesOverAnsweredCall ? answeredNativeCallID : nil
        case .webView: isIncomingCallAnswered ? incomingCallID : nil
        }
        
        guard let callID, callID.userID == userID, callID.roomID == roomID else { return nil }
        return callID
    }
    
    /// Ends what the incoming call left up once its state is cleared, as nothing would track it any more.
    private func endIncomingCall(notTakenOverBy answeredCallID: CallID?, roomID: String) {
        if let ringingCallID {
            let reason: CXCallEndedReason = ringingCallID.roomID == roomID ? .answeredElsewhere : .unanswered
            MXLog.info("Ending the ringing call as \(reason.rawValue), another call is starting")
            callProvider.reportCall(with: ringingCallID.callKitID, endedAt: nil, reason: reason)
        }
        
        // Nothing would end an answered call left up, and it would keep the media from a web view call.
        if let answeredNativeCallID, answeredNativeCallID != answeredCallID {
            MXLog.warning("Ending an answered call that another call replaced")
            callProvider.reportCall(with: answeredNativeCallID.callKitID, endedAt: nil, reason: .failed)
        }
    }
    
    private func reportCallSessionConnected(userID: String, roomID: String) {
        guard let ongoingCallID, ongoingCallID.userID == userID, ongoingCallID.roomID == roomID else {
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
    
    private func tearDownCallSession(userID: String, roomID: String) {
        if let ongoingCallID, ongoingCallID.userID == userID, ongoingCallID.roomID == roomID {
            tearDownCallSession(sendEndCallAction: true)
            return
        }
        
        dropAnsweredCall(userID: userID, roomID: roomID)
    }
    
    func dropAnsweredCall(userID: String, roomID: String) {
        // Answered and handed over, but the stack couldn't take it. Ending it here rather than
        // waiting for the watchdog takes the system call UI away straight away.
        if let answeredNativeCallID, answeredNativeCallID.userID == userID, answeredNativeCallID.roomID == roomID {
            MXLog.warning("Ending an answered call the native call stack didn't take over")
            endPendingCall()
            return
        }
        
        // Otherwise it would count as a call in progress, and every call after it would be missed.
        if isIncomingCallAnswered, let incomingCallID, incomingCallID.userID == userID, incomingCallID.roomID == roomID {
            MXLog.warning("Dropping an answered call that never opened")
            clearIncomingCallState()
            return
        }
        
        MXLog.info("Not dropping an answered call, none for \(userID) in room \(roomID)")
    }
    
    private func reportCallSessionEnded(userID: String, roomID: String, reason: CallEndReason) {
        guard let ongoingCallID, ongoingCallID.userID == userID, ongoingCallID.roomID == roomID else {
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
    
    private func setAudioEnabled(_ enabled: Bool, userID: String, roomID: String) {
        guard let ongoingCallID else {
            MXLog.error("Failed toggling call microphone, no calls running")
            return
        }
        
        guard ongoingCallID.userID == userID, ongoingCallID.roomID == roomID else {
            MXLog.error("Failed toggling call microphone, calls don't match: \(ongoingCallID.userID) in \(ongoingCallID.roomID) != \(userID) in \(roomID)")
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
    private func incomingCallEnded(userID: String, roomID: String, reason: CallEndReason) {
        guard let incomingCallID, incomingCallID.userID == userID, incomingCallID.roomID == roomID else {
            MXLog.info("Not ending the incoming call, no call ringing for \(userID) in room \(roomID)")
            return
        }
        
        reportEndedCall(incomingCallID: incomingCallID, reason: CXCallEndedReason(reason))
    }
    
    // MARK: - Call screen
    
    /// Loads the room of a call requested by room ID, then presents its call screen, unless its account went meanwhile.
    private func handleCallRequest(_ request: CallRequest, service: ElementCallServiceProtocol) async {
        let roomProxy = await service.joinedRoom(roomID: request.roomID)
        
        guard services[request.userID] === service else {
            dropCallRequest(request, because: "\(request.userID) left while its room loaded")
            return
        }
        
        guard let roomProxy else {
            dropCallRequest(request, because: "it isn't a joined room")
            return
        }
        
        presentCallScreen(for: .init(roomProxy: roomProxy, isVoiceCall: request.isVoiceCall),
                          answeredFromCallKit: request.answeredFromCallKit,
                          service: service)
    }
    
    /// Presents the room's call with its account's service, returning to it when it's already on screen.
    /// Any other call is replaced.
    private func presentCallScreen(for call: ElementCallServiceAction.RoomCall, answeredFromCallKit: Bool, service: ElementCallServiceProtocol) {
        let pendingRequestWasAnswered = takePendingCallRequest(replacedBy: service.userID, roomID: call.roomProxy.id)
        let answeredFromCallKit = answeredFromCallKit || pendingRequestWasAnswered
        
        // The native call stack runs the call and reports its screen as `.nativeCallPresentation`.
        if service.handleNativeCallRequest(roomProxy: call.roomProxy, isVoiceCall: call.isVoiceCall, answeredFromCallKit: answeredFromCallKit) {
            return
        }
        
        let userID = service.userID
        
        // TODO: Give every account a native call stack, until then only the active account has one.
        guard !appSettings.nativeCallEnabled else {
            dropCallRequest(.init(userID: userID, roomID: call.roomProxy.id, isVoiceCall: call.isVoiceCall, answeredFromCallKit: answeredFromCallKit),
                            because: "native calls are on and \(userID) has no native call stack")
            return
        }
        
        let webCall = PresentedCall.webView(userID: userID, roomID: call.roomProxy.id)
        
        guard presentedCall != webCall else {
            MXLog.info("Returning to the call on screen.")
            actionsSubject.send(.callScreen(.restore))
            return
        }
        
        // Set before presenting: the replaced screen hangs up as it goes, which must leave this call alone.
        presentedCall = webCall
        actionsSubject.send(.callScreen(.present(userID: userID, kind: .webView(call))))
    }
    
    private func storePendingCallRequest(_ request: CallRequest) {
        let pendingRequestWasAnswered = takePendingCallRequest(replacedBy: request.userID, roomID: request.roomID)
        
        MXLog.info("Keeping the call in \(request.roomID) pending until \(request.userID) has a call service")
        pendingCallRequest = CallRequest(userID: request.userID,
                                         roomID: request.roomID,
                                         isVoiceCall: request.isVoiceCall,
                                         answeredFromCallKit: request.answeredFromCallKit || pendingRequestWasAnswered)
    }
    
    /// Takes the pending call request for a newer one. The same call asked for again passes on its answer
    /// for the newer request to take over, any other is dropped. Returns whether an answer was passed on.
    private func takePendingCallRequest(replacedBy userID: String, roomID: String) -> Bool {
        guard let pendingCallRequest = pendingCallRequest.take() else { return false }
        
        guard pendingCallRequest.userID == userID, pendingCallRequest.roomID == roomID else {
            dropCallRequest(pendingCallRequest, because: "a newer call replaced it")
            return false
        }
        
        return pendingCallRequest.answeredFromCallKit
    }
    
    private func handlePendingCallRequest(_ request: CallRequest) async {
        // Checked again, as the request may have been replaced or its account removed since.
        guard pendingCallRequest == request, let service = services[request.userID] else { return }
        pendingCallRequest = nil
        await handleCallRequest(request, service: service)
    }
    
    private func dropCallRequest(_ request: CallRequest, because reason: String) {
        MXLog.warning("Dropping the call in \(request.roomID): \(reason)")
        
        if request.answeredFromCallKit {
            dropAnsweredCall(userID: request.userID, roomID: request.roomID)
        }
    }
    
    /// Passes on the native call stack's screen changes while its call is the one on screen.
    private func relayNativeCallPresentation(_ presentation: NativeCallPresentation, from service: ElementCallServiceProtocol) {
        let userID = service.userID
        let nativeCall = PresentedCall.native(userID: userID)
        
        switch presentation {
        case .present:
            guard presentedCall != nativeCall else {
                restoreNativeCall(of: service)
                return
            }
            
            presentedCall = nativeCall
            actionsSubject.send(.callScreen(.present(userID: userID, kind: .native)))
        case .restore:
            guard presentedCall == nativeCall else { return }
            restoreNativeCall(of: service)
        case .minimize:
            guard presentedCall == nativeCall else { return }
            actionsSubject.send(.callScreen(.minimize))
        case .dismiss:
            guard presentedCall == nativeCall else { return }
            presentedCall = nil
            actionsSubject.send(.callScreen(.dismiss))
        }
    }
    
    private func restoreNativeCall(of service: ElementCallServiceProtocol) {
        service.restoreNativeCall()
        actionsSubject.send(.callScreen(.restore))
    }
    
    private func minimizeCall() {
        switch presentedCall {
        case .none:
            break
        case .native(let userID):
            // The screen comes down once the stack reports its system window, as `.nativeCallPresentation(.minimize)`.
            services[userID]?.minimizeNativeCall()
        case .webView:
            actionsSubject.send(.callScreen(.minimize))
        }
    }
    
    /// Takes the account's call off screen, as the account goes or the system ended its web view call.
    private func dismissCallScreen(of userID: String) {
        guard presentedCall?.userID == userID else { return }
        presentedCall = nil
        actionsSubject.send(.callScreen(.dismiss))
    }
    
    // MARK: - PKPushRegistryDelegate
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) { }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        guard let push = VoIPPushPayload(dictionary: payload.dictionaryPayload) else {
            MXLog.error("Something went wrong, the incoming voip call push is missing details: \(payload)")
            reportImmediatelyEndedCall(reason: .failed, completion: completion)
            return
        }
        
        let callerInfo = (roomID: push.roomID, roomDisplayName: push.roomDisplayName)
        
        guard ongoingCallID?.roomID != push.roomID else {
            MXLog.warning("Call already ongoing for room \(push.roomID), reporting the duplicate push as handled")
            reportImmediatelyEndedCall(reason: .answeredElsewhere, callerInfo: callerInfo, completion: completion)
            return
        }
        
        guard incomingCallID?.rtcNotificationID != push.rtcNotificationID else {
            MXLog.info("Already ringing for this call, reporting the duplicate push as handled")
            reportImmediatelyEndedCall(reason: .answeredElsewhere, callerInfo: callerInfo, completion: completion)
            return
        }
        
        let isBusy = incomingCallID != nil || ongoingCallID != nil
        guard !isBusy else {
            MXLog.info("Another call is ringing or ongoing, reporting the call for room \(push.roomID) as missed")
            reportImmediatelyEndedCall(reason: .unanswered, callerInfo: callerInfo, completion: completion)
            return
        }
        
        let callID = CallID(callKitID: UUID(), userID: push.receiverID, roomID: push.roomID, rtcNotificationID: push.rtcNotificationID, isVoiceCall: push.isVoiceCall)
        incomingCallID = callID
        
        let nowDate = timeProvider.now()
        
        guard nowDate < push.expirationDate else {
            MXLog.warning("Call expired for room \(push.roomID), reporting it as missed")
            clearIncomingCallState()
            reportImmediatelyEndedCall(reason: .unanswered, callerInfo: callerInfo, completion: completion)
            return
        }
        
        let ringDuration: Duration = .seconds(min(push.expirationDate.timeIntervalSince1970 - nowDate.timeIntervalSince1970, 90))
        
        let update = CXCallUpdate()
        // Work Around: Always set video to true! https://github.com/element-hq/element-x-ios/issues/5335
        // If not for audio call the app will not be put to foreground and the webview won't be able to handle the call...
        // Consequence: The call will be presented to the user as a video call in CallKit UI,
        // but once Element Call is launched it will correctly route to a voice-only call.
        // TODO: A native voice call answered on the lock screen at cold launch has no scene to start its call from, so the watchdog ends it.
        update.hasVideo = appSettings.nativeCallEnabled ? !push.isVoiceCall : true
        update.localizedCallerName = push.roomDisplayName
        // https://stackoverflow.com/a/41230020/730924
        update.remoteHandle = .init(type: .generic, value: push.roomID)
        
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
    
    // The audio session is app-wide, and its deactivation usually lands after the call has been cleared,
    // so there's no owner left to route these to. Services without a native call stack ignore them.
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        MXLog.info("Call provider did activate audio session")
        isAudioSessionActive = true
        services.values.forEach { $0.systemEventReceived(.audioSessionActivated) }
    }
    
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        MXLog.info("Call provider did deactivate audio session")
        isAudioSessionActive = false
        services.values.forEach { $0.systemEventReceived(.audioSessionDeactivated) }
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        // CallKit activates the session and reports back through `didActivate`.
        configureNativeCallAudioSession()
        action.fulfill()
        callProvider.reportOutgoingCall(with: action.callUUID, startedConnectingAt: nil)
    }
    
    /// The provider dropped every call, so nothing here is requested from or reported to CallKit.
    func providerDidReset(_ provider: CXProvider) {
        MXLog.info("Call provider did reset: \(provider)")
        
        // A web view call isn't tracked by CallKit, so it stays up.
        if let ongoingCallID, ongoingCallID.isNative {
            services[ongoingCallID.userID]?.systemEventReceived(.endCallRequested(roomID: ongoingCallID.roomID))
            self.ongoingCallID = nil
        }
        
        isAudioSessionActive = false
        services.values.forEach { $0.systemEventReceived(.audioSessionDeactivated) }
        
        clearIncomingCallState()
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
        configureNativeCallAudioSession()
        action.fulfill()
        
        if appSettings.nativeCallEnabled {
            // The native stack owns media in this process, so the CallKit call stays up: the
            // controller attaches to it in `setupCallSession`.
            endUnansweredCallTask?.cancel()
            endCallIfLeftPending(incomingCallID)
            actionsSubject.send(.callAnswered(userID: incomingCallID.userID, roomID: incomingCallID.roomID, isVoiceCall: incomingCallID.isVoiceCall))
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
            self.callProvider.reportCall(with: incomingCallID.callKitID, endedAt: nil, reason: .remoteEnded)
            
            // The caller may have hung up meanwhile, and opening the call would ring them back.
            guard self.isIncomingCallAnswered, self.incomingCallID == incomingCallID else {
                MXLog.info("Not opening the answered call, it ended or opened before the hand-over")
                return
            }
            
            self.actionsSubject.send(.callAnswered(userID: incomingCallID.userID, roomID: incomingCallID.roomID, isVoiceCall: incomingCallID.isVoiceCall))
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if let ongoingCallID, ongoingCallID.callKitID == action.callUUID {
            services[ongoingCallID.userID]?.systemEventReceived(.microphoneMuteChanged(isMuted: action.isMuted))
        } else {
            MXLog.info("Ignoring a mute action for a call that isn't the ongoing one")
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
            services[ongoingCallID.userID]?.systemEventReceived(.endCallRequested(roomID: ongoingCallID.roomID))
            tearDownCallSession(sendEndCallAction: false)
            
            // Only the native stack hears the request, so a web view call's screen is taken down here.
            if presentedCall == .webView(userID: ongoingCallID.userID, roomID: ongoingCallID.roomID) {
                dismissCallScreen(of: ongoingCallID.userID)
            }
        }
        
        if let incomingCallID, incomingCallID.callKitID == callKitID {
            decline(incomingCallID)
            clearIncomingCallState()
        }
    }
    
    // MARK: - Private
    
    /// Has the ringing call's account service observe it, once the push has been handled.
    private func observeIncomingCall(_ callID: CallID) {
        Task { [weak self] in
            guard let self, incomingCallID == callID else { return }
            
            // Looked up here rather than before the task, by when the service may have been replaced or removed.
            guard let service = services[callID.userID] else {
                MXLog.info("No call service for \(callID.userID) to observe the incoming call with")
                return
            }
            
            await service.observeIncomingCall(roomID: callID.roomID, rtcNotificationID: callID.rtcNotificationID)
        }
    }
    
    private func decline(_ callID: CallID) {
        guard let rtcNotificationID = callID.rtcNotificationID else {
            MXLog.info("No rtc notification event to decline.")
            return
        }
        
        guard let service = services[callID.userID] else {
            MXLog.info("No call service for \(callID.userID) yet, declining the incoming call once it's added")
            pendingDecline = callID
            return
        }
        
        Task {
            await service.declineCall(roomID: callID.roomID, rtcNotificationID: rtcNotificationID)
        }
    }
    
    /// Must run before a CallKit action is fulfilled: the system activates the session with whatever
    /// category it has then, and an answered call reaches the controller only after that.
    private func configureNativeCallAudioSession() {
        guard appSettings.nativeCallEnabled else { return }
        
        do {
            try CallAudioSessionConfigurator.configure()
        } catch {
            MXLog.error("Failed configuring the call audio session with error: \(error)")
        }
    }
    
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
    
    /// Ends the account's ongoing call as its service goes or is replaced.
    private func endOngoingCall(userID: String) {
        guard let ongoingCallID, ongoingCallID.userID == userID else { return }
        
        // A backstop: the flow's `stop()` or the native stack's hang-up normally gets there first.
        MXLog.warning("Ending the ongoing call of an account whose call service is going, native: \(ongoingCallID.isNative)")
        
        if ongoingCallID.isNative {
            callProvider.reportCall(with: ongoingCallID.callKitID, endedAt: nil, reason: .failed)
            services[userID]?.systemEventReceived(.endCallRequested(roomID: ongoingCallID.roomID))
        }
        
        self.ongoingCallID = nil
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
