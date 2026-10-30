//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall
import MatrixRustSDK

/// One account's side of its calls, on that account's client: the ringing call's room, its decline,
/// the ongoing call and the native call stack. Relays what the call screens report up to the
/// `ElementCallManager`.
final class ElementCallService: ElementCallServiceProtocol {
    private struct ObservedCall: Equatable {
        let roomID: String
        let rtcNotificationID: String?
    }
    
    private let clientProxy: ClientProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let appSettings: AppSettings
    
    var userID: String {
        clientProxy.userID
    }
    
    private let actionsSubject = PassthroughSubject<ElementCallServiceAction, Never>()
    var actionsPublisher: AnyPublisher<ElementCallServiceAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(nil)
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        ongoingCallRoomIDSubject.asCurrentValuePublisher()
    }
    
    private let nativeCallEventsSubject = PassthroughSubject<NativeCallEvent, Never>()
    var nativeCallEventsPublisher: AnyPublisher<NativeCallEvent, Never> {
        nativeCallEventsSubject.eraseToAnyPublisher()
    }
    
    private let nativeCallPresentationSubject = PassthroughSubject<NativeCallPresentation, Never>()
    var nativeCallPresentationPublisher: AnyPublisher<NativeCallPresentation, Never> {
        nativeCallPresentationSubject.eraseToAnyPublisher()
    }
    
    /// The native call stack, while enabled and the setting is on.
    private var nativeCallStack: NativeCallStack?
    private var nativeCallCancellable: AnyCancellable?
    private var isNativeCallStackEnabled = false
    
    var nativeCallController: ElementCallController? {
        nativeCallStack?.controller
    }
    
    /// Call screens waiting in `setupCallSession` for the manager's reply, by room.
    private var callSessionSetUpContinuations: [String: CheckedContinuation<Void, Never>] = [:]
    
    private var observedCall: ObservedCall?
    private var incomingCallRoomInfoCancellable: AnyCancellable?
    private var declineListenerHandle: TaskHandle?
    
    private var cancellables = Set<AnyCancellable>()
    
    init(clientProxy: ClientProxyProtocol, mediaProvider: MediaProviderProtocol, appSettings: AppSettings) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        self.appSettings = appSettings
        
        appSettings.nativeCallEnabledPublisher
            .sink { [weak self] _ in
                self?.updateNativeCallStack()
            }
            .store(in: &cancellables)
    }
    
    func setNativeCallStackEnabled(_ isEnabled: Bool) {
        isNativeCallStackEnabled = isEnabled
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
    
    func reportCallSessionEnded(roomID: String, reason: CallEndReason) {
        actionsSubject.send(.callSessionEnded(roomID: roomID, reason: reason))
    }
    
    func setAudioEnabled(_ enabled: Bool, roomID: String) {
        actionsSubject.send(.audioEnabledChanged(enabled, roomID: roomID))
    }
    
    func observeIncomingCall(roomID: String, rtcNotificationID: String?) async {
        stopObservingIncomingCall()
        
        let call = ObservedCall(roomID: roomID, rtcNotificationID: rtcNotificationID)
        observedCall = call
        
        await watch(call)
    }
    
    func stopObservingIncomingCall() {
        observedCall = nil
        incomingCallRoomInfoCancellable = nil
        declineListenerHandle?.cancel()
        declineListenerHandle = nil
    }
    
    func declineCall(roomID: String, rtcNotificationID: String) async {
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
    
    func systemEventReceived(_ event: NativeCallEvent) {
        nativeCallEventsSubject.send(event)
    }
    
    // MARK: - Native calls
    
    /// Builds or releases the call stack to match the toggle and the setting.
    private func updateNativeCallStack() {
        guard appSettings.nativeCallEnabled, isNativeCallStackEnabled else {
            stopNativeCallStack()
            return
        }
        
        guard nativeCallStack == nil else { return }
        
        guard let backend = clientProxy.makeNativeCallBackend() else {
            MXLog.error("Cannot start the native call stack without a Matrix backend")
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
        
        let stack = NativeCallStack(backend: backend,
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
    
    private func watch(_ call: ObservedCall) async {
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(call.roomID) else {
            MXLog.warning("Failed to fetch a joined room for the incoming call.")
            return
        }
        
        // Stopped, or another call started ringing while the room was being fetched.
        guard observedCall == call else { return }
        
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
    
    /// Reports the end once, as the room and the decline listener can both see it.
    private func incomingCallEnded(_ call: ObservedCall, reason: CallEndReason) {
        guard observedCall == call else { return }
        stopObservingIncomingCall()
        actionsSubject.send(.incomingCallEnded(roomID: call.roomID, reason: reason))
    }
}
