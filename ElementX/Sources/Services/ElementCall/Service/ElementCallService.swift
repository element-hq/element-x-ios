//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CallKit
import Combine
import MatrixRustSDK

final class ElementCallService: ElementCallServiceProtocol {
    private struct ObservedCall: Equatable {
        let roomID: String
        let rtcNotificationID: String?
    }
    
    private let clientProxy: ClientProxyProtocol
    
    private let actionsSubject = PassthroughSubject<ElementCallServiceAction, Never>()
    var actionsPublisher: AnyPublisher<ElementCallServiceAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let ongoingCallRoomIDSubject = CurrentValueSubject<String?, Never>(nil)
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        ongoingCallRoomIDSubject.asCurrentValuePublisher()
    }
    
    var userID: String {
        clientProxy.userID
    }
    
    private var observedCall: ObservedCall?
    private var incomingCallRoomInfoCancellable: AnyCancellable?
    private var declineListenerHandle: TaskHandle?
    
    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
    }
    
    // MARK: Call screen
    
    func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool) {
        actionsSubject.send(.callSessionStarted(roomID: roomID, roomDisplayName: roomDisplayName, isVideo: isVideo))
    }
    
    func tearDownCallSession(roomID: String) {
        actionsSubject.send(.callSessionEnded(roomID: roomID))
    }
    
    func setAudioEnabled(_ enabled: Bool, roomID: String) {
        actionsSubject.send(.audioEnabledChanged(enabled, roomID: roomID))
    }
    
    // MARK: Manager
    
    func observeIncomingCall(roomID: String, rtcNotificationID: String?) async {
        stopObservingIncomingCall()
        
        let call = ObservedCall(roomID: roomID, rtcNotificationID: rtcNotificationID)
        observedCall = call
        
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            MXLog.warning("Failed to fetch a joined room for the incoming call.")
            return
        }
        
        // Stopped, or another call started ringing, while the room was being fetched.
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
        
        guard let rtcNotificationID else {
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
    
    // MARK: - Private
    
    /// Reports the end once, as the room and the decline listener can both see it.
    private func incomingCallEnded(_ call: ObservedCall, reason: CXCallEndedReason) {
        guard observedCall == call else { return }
        stopObservingIncomingCall()
        actionsSubject.send(.incomingCallEnded(roomID: call.roomID, reason: reason))
    }
}
