//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall
import Foundation

/// Owns the call package's stack for one logged-in session, and turns what the call does into the
/// navigation the host owes it.
///
/// Built with the session rather than with the first call: the core's to-device subscription has no
/// catch-up, so a stack that starts only once a call does can miss the keys sent while it was
/// joining.
@MainActor
final class NativeCallSession {
    var controller: ElementCallController {
        stack.controller
    }
    
    var actions: AnyPublisher<NativeCallPresentation, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let stack: ElementCallStack
    private let actionsSubject = PassthroughSubject<NativeCallPresentation, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    /// A call requested while another one was still running, started once that one has ended.
    private var pendingCallRequest: (roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool)?
    
    /// The arguments are the whole integration surface: a transport, the system call provider,
    /// settings, the look and a log sink.
    init(transport: any ElementCallMatrixTransport,
         system: any ElementCallSystemProviding,
         options: any ElementCallOptions,
         style: ElementCallStyle,
         logger: (any ElementCallLogging)?) {
        stack = ElementCallStack(transport: transport,
                                 system: system,
                                 options: options,
                                 style: style,
                                 logger: logger)
        
        stack.controller.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handle(action)
            }
            .store(in: &cancellables)
    }
    
    func start() async {
        MatrixRTCLogBridge.install()
        await stack.start()
    }
    
    /// Releases the stack along with the to-device subscription it holds open for key delivery.
    func stop() {
        MXLog.info("Stopping the native call stack, in a call: \(controller.isInCall)")
        
        // Best effort: the leave this starts may not finish before the core stops, but the
        // alternative is walking away from the call without telling the room at all.
        if controller.isInCall {
            controller.hangUp()
        }
        
        stack.stop()
    }
    
    /// Starts, or returns to, the call in the room.
    func handleCallRequest(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool) {
        if controller.isInCall {
            guard controller.room?.roomID != roomProxy.id else {
                // Reached while the call is still joining, before the service has an ongoing call
                // for its own room check to match against.
                MXLog.info("Returning to the call already starting in this room.")
                actionsSubject.send(.restore)
                return
            }
            
            // The controller ignores a second call, so wait for the running one to leave its room.
            MXLog.info("Leaving the ongoing call to start the one requested in another room.")
            pendingCallRequest = (roomProxy, isVoiceCall)
            controller.hangUp()
            return
        }
        
        // Starting rings the room; joining one already running happens quietly.
        let callData = ElementCallData(isAudioCall: isVoiceCall,
                                       isStartingCall: !roomProxy.infoPublisher.value.hasRoomCall)
        controller.startCall(callData, room: NativeCallRoomContext(roomProxy: roomProxy))
        actionsSubject.send(.present)
    }
    
    // MARK: - Private
    
    private func handle(_ action: ElementCallControllerAction) {
        switch action {
        case .minimizeRequested:
            // Nothing to do until we know what the call is minimizing into: the controller follows
            // this with either window or no window.
            break
        case .restoreRequested:
            actionsSubject.send(.restore)
        case .ended:
            actionsSubject.send(.dismiss)
            controller.reset()
            startPendingCall()
        case .pictureInPictureStarted:
            // Also reached when the system started the window on backgrounding, so this isn't
            // necessarily a minimize we asked for.
            actionsSubject.send(.minimize)
        case .pictureInPictureUnavailable:
            // Hiding the screen without a window to minimize into would leave the call running with
            // no way back to mute or hang up.
            MXLog.info("Staying on the call screen: no system window is available.")
            actionsSubject.send(.restore)
        }
    }
    
    private func startPendingCall() {
        guard let pendingCallRequest else { return }
        self.pendingCallRequest = nil
        handleCallRequest(roomProxy: pendingCallRequest.roomProxy, isVoiceCall: pendingCallRequest.isVoiceCall)
    }
}
