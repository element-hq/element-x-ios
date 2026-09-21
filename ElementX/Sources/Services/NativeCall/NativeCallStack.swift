//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall
import Foundation

/// The call package's stack for one logged-in session, turning what the call does into the
/// navigation the host owes it.
///
/// Built with the session rather than with the first call: the core's to-device subscription has no
/// catch-up, so a stack that starts only once a call does can miss the keys sent while it was
/// joining.
@MainActor
final class NativeCallStack {
    /// The call itself, for the screen that is built from it. Everything else asks this type.
    var controller: ElementCallController {
        stack.controller
    }
    
    var actions: AnyPublisher<NativeCallPresentation, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    /// Prefix for native call related logs
    nonisolated static let logPrefix = "[NativeCall]"
    
    private let stack: ElementCallStack
    private let actionsSubject = PassthroughSubject<NativeCallPresentation, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    /// A call requested while another one was still running, started once that one has ended.
    private var pendingCallRequest: (roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool)?
    
    init(transport: any ElementCallMatrixTransportProtocol,
         system: any ElementCallSystemProvidingProtocol,
         options: ElementCallOptions,
         style: ElementCallStyle) {
        stack = ElementCallStack(transport: transport,
                                 system: system,
                                 options: options,
                                 style: style,
                                 logger: Logger())
        
        stack.controller.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handle(action)
            }
            .store(in: &cancellables)
    }
    
    func start() async {
        Self.installRTCLogBridge()
        await stack.start()
    }
    
    /// Releases the stack along with the to-device subscription it holds open for key delivery.
    func stop() {
        MXLog.info("\(Self.logPrefix) Stopping the native call stack, in a call: \(controller.isInCall)")
        
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
                MXLog.info("\(Self.logPrefix) Returning to the call already starting in this room.")
                actionsSubject.send(.restore)
                return
            }
            
            // The controller ignores a second call, so wait for the running one to leave its room.
            MXLog.info("\(Self.logPrefix) Leaving the ongoing call to start the one requested in another room.")
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
    
    /// Asks the call to minimize. The screen only comes down once the controller says a system
    /// window has started, which it answers through ``actions``.
    func minimize() {
        controller.requestMinimize()
    }
    
    func restore() {
        controller.restore()
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
            MXLog.info("\(Self.logPrefix) Staying on the call screen: no system window is available.")
            actionsSubject.send(.restore)
        }
    }
    
    private func startPendingCall() {
        guard let pendingCallRequest else { return }
        self.pendingCallRequest = nil
        handleCallRequest(roomProxy: pendingCallRequest.roomProxy, isVoiceCall: pendingCallRequest.isVoiceCall)
    }
    
    /// Sends the call package's log lines to `MXLog`, keeping the package's own file and line so
    /// entries point at its source rather than at here.
    private struct Logger: ElementCallLoggingProtocol {
        func log(_ record: ElementCallLogRecord) {
            let message = "\(NativeCallStack.logPrefix) \(record.message)"
            switch record.level {
            case .debug: MXLog.debug(message, file: record.file, line: record.line)
            case .info: MXLog.info(message, file: record.file, line: record.line)
            case .warning: MXLog.warning(message, file: record.file, line: record.line)
            case .error: MXLog.error(message, file: record.file, line: record.line)
            }
        }
    }
    
    /// Feeds the Rust RTC core's own records into `MXLog` too, so they end up in rageshakes next to
    /// the SDK's. Idempotent, and must run before anything else uses the call package.
    private static func installRTCLogBridge() {
        MatrixRTCLogging.install { record in
            // The core's own position when it has one, its module path otherwise.
            let file = record.file ?? record.target
            let line = Int(record.line ?? 0)
            let message = "\(logPrefix) \(record.target): \(record.message)"
            switch record.level {
            case .error: MXLog.error(message, file: file, line: line)
            case .warning: MXLog.warning(message, file: file, line: line)
            case .info: MXLog.info(message, file: file, line: line)
            case .debug: MXLog.debug(message, file: file, line: line)
            case .verbose: MXLog.verbose(message, file: file, line: line)
            }
        }
    }
}
