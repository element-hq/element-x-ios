//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CallKit
import Combine
import ElementCall
import MatrixRustSDK

/// The account's side of its calls: the ringing call's room, its decline, the ongoing call and the
/// native call stack. Relays what the call screens report up to the `ElementCallManager`.
final class ElementCallService: ElementCallServiceProtocol {
    private struct ObservedCall: Equatable {
        let roomID: String
        let rtcNotificationID: String?
    }
    
    private let appSettings: AppSettings
    
    private weak var clientProxy: ClientProxyProtocol?
    private var mediaProvider: MediaProviderProtocol?
    
    private let actionsSubject = PassthroughSubject<ElementCallServiceAction, Never>()
    var actionsPublisher: AnyPublisher<ElementCallServiceAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(nil)
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        ongoingCallRoomIDSubject.asCurrentValuePublisher()
    }
    
    private let nativeCallEventsSubject = PassthroughSubject<ElementCallSystemEvent, Never>()
    var nativeCallEventsPublisher: AnyPublisher<ElementCallSystemEvent, Never> {
        nativeCallEventsSubject.eraseToAnyPublisher()
    }
    
    private let nativeCallPresentationSubject = PassthroughSubject<NativeCallPresentation, Never>()
    var nativeCallPresentationPublisher: AnyPublisher<NativeCallPresentation, Never> {
        nativeCallPresentationSubject.eraseToAnyPublisher()
    }
    
    /// The native call stack, for as long as there's a session running calls through it.
    private var nativeCallStack: NativeCallStack?
    private var nativeCallCancellable: AnyCancellable?
    
    var nativeCallController: ElementCallController? {
        nativeCallStack?.controller
    }
    
    /// Call screens waiting in `setupCallSession` for the manager's reply, by room.
    private var callSessionSetUpContinuations: [String: CheckedContinuation<Void, Never>] = [:]
    
    private var observedCall: ObservedCall?
    private var incomingCallRoomInfoCancellable: AnyCancellable?
    private var declineListenerHandle: TaskHandle?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        
        appSettings.nativeCallEnabledPublisher
            .sink { [weak self] _ in
                self?.updateNativeCallStack()
            }
            .store(in: &cancellables)
    }
    
    func setUserSession(_ userSession: UserSessionProtocol?) {
        let isNewClient = userSession?.clientProxy !== clientProxy
        
        // A stack is built against one client proxy and can't be handed to another, which is what a
        // soft logout or a cache clear brings: a new session without the sign out that drops this one.
        if isNewClient {
            stopNativeCallStack()
            stopWatchingRoom()
        }
        
        clientProxy = userSession?.clientProxy
        mediaProvider = userSession?.mediaProvider
        
        if isNewClient {
            resumeObservingIncomingCall()
        }
        
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
    
    // MARK: Call screens
    
    func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool, kind: ElementCallSessionKind) async {
        await withCheckedContinuation { continuation in
            if let staleContinuation = callSessionSetUpContinuations.removeValue(forKey: roomID) {
                MXLog.warning("Releasing a call session set-up for room \(roomID) that the manager never answered")
                staleContinuation.resume()
            }
            
            // Registered before sending, as the manager can answer from within the send.
            callSessionSetUpContinuations[roomID] = continuation
            actionsSubject.send(.callSessionStarted(roomID: roomID, roomDisplayName: roomDisplayName, isVideo: isVideo, kind: kind))
        }
    }
    
    func reportCallSessionConnected(roomID: String) {
        actionsSubject.send(.callSessionConnected(roomID: roomID))
    }
    
    func tearDownCallSession(roomID: String) {
        actionsSubject.send(.callSessionEnded(roomID: roomID, reason: nil))
    }
    
    func reportCallSessionEnded(roomID: String, reason: CXCallEndedReason) {
        actionsSubject.send(.callSessionEnded(roomID: roomID, reason: reason))
    }
    
    func setAudioEnabled(_ enabled: Bool, roomID: String) {
        actionsSubject.send(.audioEnabledChanged(enabled, roomID: roomID))
    }
    
    // MARK: Manager
    
    func observeIncomingCall(roomID: String, rtcNotificationID: String?) async {
        stopObservingIncomingCall()
        
        // Kept without a client too, as the push can come before the session does.
        let call = ObservedCall(roomID: roomID, rtcNotificationID: rtcNotificationID)
        observedCall = call
        
        await watch(call)
    }
    
    func stopObservingIncomingCall() {
        observedCall = nil
        stopWatchingRoom()
    }
    
    func declineCall(roomID: String, rtcNotificationID: String) async {
        guard let clientProxy else {
            MXLog.warning("A ClientProxy is needed to fetch the room.")
            return
        }
        
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            MXLog.warning("Failed to fetch a joined room to decline the incoming call.")
            return
        }
        
        _ = await roomProxy.declineCall(notificationID: rtcNotificationID)
    }
    
    func ongoingCallChanged(roomID: String?) {
        ongoingCallRoomIDSubject.send(roomID)
    }
    
    func callSessionSetUp(roomID: String, isAccepted: Bool) {
        guard let continuation = callSessionSetUpContinuations.removeValue(forKey: roomID) else {
            MXLog.info("No call session set-up waiting for room \(roomID)")
            return
        }
        
        continuation.resume()
    }
    
    func systemEventReceived(_ event: ElementCallSystemEvent) {
        nativeCallEventsSubject.send(event)
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
                self?.nativeCallPresentationSubject.send(presentation)
            }
        
        Task { await stack.start() }
    }
    
    private func stopNativeCallStack() {
        guard let nativeCallStack else { return }
        self.nativeCallStack = nil
        nativeCallCancellable = nil
        
        nativeCallStack.stop()
        nativeCallPresentationSubject.send(.dismiss)
    }
    
    // MARK: - Private
    
    /// Watches the ringing call with the new client, which also covers a call requested before any session.
    private func resumeObservingIncomingCall() {
        guard let call = observedCall, clientProxy != nil else { return }
        
        Task { [weak self] in
            guard let self, observedCall == call else { return }
            await watch(call)
        }
    }
    
    private func watch(_ call: ObservedCall) async {
        guard let clientProxy else {
            MXLog.info("No session yet to watch the incoming call with")
            return
        }
        
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(call.roomID) else {
            MXLog.warning("Failed to fetch a joined room for the incoming call.")
            return
        }
        
        // Stopped, another call started ringing, or the session changed while the room was being fetched.
        guard observedCall == call, self.clientProxy === clientProxy else { return }
        
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
                
                if !hasOngoingCall {
                    MXLog.info("Call cancelled by remote")
                    incomingCallEnded(call, reason: .remoteEnded)
                } else if activeRoomCallParticipants.contains(roomProxy.ownUserID) {
                    MXLog.info("Call answered elsewhere")
                    incomingCallEnded(call, reason: .answeredElsewhere)
                }
            }
        
        guard let rtcNotificationID = call.rtcNotificationID else {
            MXLog.warning("Decline: No RTC notification ID found for the incoming call.")
            return
        }
        
        MXLog.info("Observe decline events for notification \(rtcNotificationID)")
        
        let listener: CallDeclineListener = SDKListener.onMainActor { [weak self] senderID in
            guard let self else { return }
            
            MXLog.debug("Call declined event received from \(senderID)")
            
            if senderID == roomProxy.ownUserID {
                MXLog.debug("Call declined elsewhere")
                incomingCallEnded(call, reason: .declinedElsewhere)
            }
        }
        
        guard case let .success(handle) = roomProxy.subscribeToCallDeclineEvents(rtcNotificationEventID: rtcNotificationID, listener: listener) else {
            MXLog.error("Unable to listen for decline events.")
            return
        }
        
        declineListenerHandle = handle
    }
    
    /// Drops the room subscriptions and keeps the ringing call, which a session can pick up again.
    private func stopWatchingRoom() {
        incomingCallRoomInfoCancellable = nil
        declineListenerHandle?.cancel()
        declineListenerHandle = nil
    }
    
    /// Reports the end once, as the room and the decline listener can both see it.
    private func incomingCallEnded(_ call: ObservedCall, reason: CXCallEndedReason) {
        guard observedCall == call else { return }
        stopObservingIncomingCall()
        actionsSubject.send(.incomingCallEnded(roomID: call.roomID, reason: reason))
    }
}
