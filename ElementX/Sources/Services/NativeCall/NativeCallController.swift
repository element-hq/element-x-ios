//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import Combine
import Foundation
import MatrixRtcKit
import Observation
import SwiftUI

/// Owns the native call above the UI, so the call is a fact about the app rather than about the
/// screen showing it: the full-screen view and a minimized bar are two renderings of one thing.
///
/// One per user session, created with the `MatrixRtcService`. Mutations are funnelled through the
/// main actor so the UI only ever sees whole snapshots.
@Observable
final class NativeCallController {
    private(set) var callData: NativeCallData?
    private(set) var connection: NativeCallConnection = .idle
    private(set) var session: MatrixRtcSession?
    private(set) var call: MatrixRtcCall?
    private(set) var connectedAt: Date?
    private(set) var isLoudspeaker = false
    
    private let rtcService: MatrixRtcService
    private let clientProxy: ClientProxyProtocol
    private let elementCallService: ElementCallServiceProtocol
    private var eventsTask: Task<Void, Never>?
    private var routeObserver: NSObjectProtocol?
    
    init(rtcService: MatrixRtcService,
         clientProxy: ClientProxyProtocol,
         elementCallService: ElementCallServiceProtocol) {
        self.rtcService = rtcService
        self.clientProxy = clientProxy
        self.elementCallService = elementCallService
        
        routeObserver = NotificationCenter.default.addObserver(forName: AVAudioSession.routeChangeNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.isLoudspeaker = CallAudioSessionConfigurator.isLoudspeaker }
        }
    }
    
    var isInCall: Bool {
        switch connection {
        case .joining, .connectingMedia, .connected: true
        default: false
        }
    }
    
    // MARK: - Lifecycle
    
    func startCall(_ callData: NativeCallData) {
        guard !isInCall else {
            MXLog.warning("NativeCall: already in a call, ignoring start for \(callData.roomID)")
            return
        }
        self.callData = callData
        connection = .joining
        runTask = Task { await runCall(callData) }
    }
    
    func hangUp() {
        Task { await endCall(leave: true) }
    }
    
    // MARK: - Media controls
    
    /// From the UI: mutes the call and tells CallKit, whose echo comes back through `applyCallKitMute`.
    func setMicrophoneMuted(_ muted: Bool) {
        guard let callData else { return }
        Task { await call?.setMicrophoneMuted(muted) }
        elementCallService.setAudioEnabled(!muted, roomID: callData.roomID)
    }
    
    /// From CallKit (lock screen, the UI's own transaction echoing back): idempotent at the call level.
    func applyCallKitMute(_ muted: Bool) {
        guard let call, call.isMicrophoneMuted != muted else { return }
        Task { await call.setMicrophoneMuted(muted) }
    }
    
    func setLoudspeaker(_ enabled: Bool) {
        do {
            try CallAudioSessionConfigurator.setLoudspeaker(enabled)
            isLoudspeaker = CallAudioSessionConfigurator.isLoudspeaker
        } catch {
            MXLog.warning("NativeCall: could not switch the audio output: \(error)")
        }
    }
    
    // MARK: - CallKit hooks
    
    private var isAudioSessionActive = false
    
    /// CallKit activated the audio session. It may happen before or after media connects, so the
    /// engine starts from whichever comes second.
    func audioSessionDidActivate() {
        isAudioSessionActive = true
        startAudioIfReady()
    }
    
    func audioSessionDidDeactivate() {
        isAudioSessionActive = false
        call?.stopAudio()
    }
    
    /// A video call is looked at, not held to an ear, so it starts on the loudspeaker; a headset
    /// still wins over both built-in outputs when one is connected.
    private func startAudioIfReady() {
        guard isAudioSessionActive, let call else { return }
        call.startAudio()
        if let callData, !callData.isAudioCall, CallAudioSessionConfigurator.isBuiltInReceiver {
            setLoudspeaker(true)
        }
    }
    
    // MARK: - Private
    
    /// The join in flight, cancelled by `endCall`. Joining takes seconds and a hang-up can land
    /// anywhere inside it; without this the join carried on, published camera and microphone into a
    /// session nobody owned any more, and the app kept both open with no screen left to stop them.
    private var runTask: Task<Void, Never>?
    
    private func runCall(_ callData: NativeCallData) async {
        MXLog.info("NativeCall: joining \(callData.roomID)")
        guard let (session, transport) = await joinSession(for: callData) else { return }
        
        connection = .connectingMedia
        let call: MatrixRtcCall
        do {
            call = try await session.connectMedia(transport: transport)
        } catch {
            await session.leave()
            await rtcService.release(roomID: callData.roomID)
            fail("Media failed: \(error)")
            return
        }
        guard !Task.isCancelled else {
            await abandon(session: session, call: call, roomID: callData.roomID)
            return
        }
        self.call = call
        
        await publishMedia(on: call, session: session, callData: callData)
    }
    
    /// Claims the CallKit call, finds a transport and joins the session (our membership goes out).
    private func joinSession(for callData: NativeCallData) async -> (MatrixRtcSession, MatrixRtcTransport)? {
        // Claim the CallKit call *before* our membership goes out: the incoming-call watcher reads
        // our own membership as "answered elsewhere" and would end the ringing call under us.
        // For an outgoing call this requests the start action; CallKit activates the audio session
        // either way and reports it through `audioSessionDidActivate`.
        do {
            try CallAudioSessionConfigurator.configure()
        } catch {
            MXLog.warning("NativeCall: could not configure the audio session: \(error)")
        }
        await elementCallService.startNativeCallSession(roomID: callData.roomID,
                                                        roomDisplayName: callData.roomDisplayName,
                                                        isVideo: !callData.isAudioCall)
        
        let discovery = RTCTransportDiscovery(homeserverURL: clientProxy.homeserver,
                                              serverName: clientProxy.userIDServerName) { [clientProxy] url in
            switch await clientProxy.getURL(url) {
            case .success(let data): return data
            case .failure(let error): throw error
            }
        }
        let transports = await discovery.discover()
        guard !Task.isCancelled else { return nil }
        guard let transport = transports.first(where: {
            if case .liveKit = $0 {
                return true
            } else {
                return false
            }
        }) else {
            fail("Homeserver offers no LiveKit transport")
            return nil
        }
        
        // Pinned while the released SDK lacks sticky events; a developer setting for the other compat
        // modes comes back once the bindings have them.
        let compat = MatrixRtcElementCallCompat.stateEvents
        MXLog.info("NativeCall: joining with Element Call compatibility \(compat)")
        
        let session: MatrixRtcSession
        do {
            session = try await rtcService.joinSession(roomID: callData.roomID,
                                                       transport: transport,
                                                       compat: compat,
                                                       notify: notify(for: callData))
        } catch {
            fail("Join failed: \(error)")
            return nil
        }
        guard !Task.isCancelled else {
            await abandon(session: session, roomID: callData.roomID)
            return nil
        }
        self.session = session
        return (session, transport)
    }
    
    /// Microphone, then camera for a video call; the call counts as connected once the microphone is up.
    private func publishMedia(on call: MatrixRtcCall, session: MatrixRtcSession, callData: NativeCallData) async {
        #if targetEnvironment(simulator)
        // CallKit never activates the session on the simulator.
        try? CallAudioSessionConfigurator.activate()
        isAudioSessionActive = true
        #endif
        // CallKit usually activated the session while we were still joining.
        startAudioIfReady()
        
        do {
            try await call.publishMicrophone()
        } catch {
            fail("Microphone failed: \(error)")
            return
        }
        guard !Task.isCancelled else {
            await abandon(session: session, call: call, roomID: callData.roomID)
            return
        }
        MXLog.info("NativeCall: connected as \(call.localMemberID)")
        
        eventsTask = Task { [weak self] in
            for await event in call.events {
                self?.handle(event)
            }
        }
        
        connection = .connected
        connectedAt = .now
        isLoudspeaker = CallAudioSessionConfigurator.isLoudspeaker
        elementCallService.reportNativeCallConnected(roomID: callData.roomID)
    }
    
    private func handle(_ event: MatrixRtcCallEvent) {
        switch event {
        case .ended:
            // From a different task than the event collector: teardown cancels that task.
            Task { await endCall(leave: false) }
        default:
            break
        }
    }
    
    /// Only when *starting* a call; joining one someone else started happens quietly. A DM rings,
    /// a group call is an invitation rather than a summons.
    private func notify(for callData: NativeCallData) -> MatrixRtcNotify? {
        guard callData.isStartingCall else { return nil }
        return MatrixRtcNotify(kind: callData.isDirect ? .ring : .notification,
                               intent: callData.isAudioCall ? .audio : .video)
    }
    
    private func fail(_ message: String) {
        MXLog.error("NativeCall: \(message)")
        connection = .failed(message)
        Task { await endCall(leave: true) }
    }
    
    /// Tears down what a join produced after the call was ended under it. `leave` is idempotent,
    /// so a session `endCall` already left costs nothing to leave again.
    private func abandon(session: MatrixRtcSession, call: MatrixRtcCall? = nil, roomID: String) async {
        MXLog.info("NativeCall: join of \(roomID) was cancelled, releasing what it set up")
        await call?.disconnect()
        await session.leave()
        await rtcService.release(roomID: roomID)
        if self.call === call {
            self.call = nil
        }
        if self.session === session {
            self.session = nil
        }
    }
    
    private func endCall(leave: Bool) async {
        guard let callData else { return }
        MXLog.info("NativeCall: ending call in \(callData.roomID) (leave=\(leave))")
        runTask?.cancel()
        runTask = nil
        eventsTask?.cancel()
        eventsTask = nil
        
        if let session {
            if leave {
                await session.leave()
            } else {
                await session.call?.disconnect()
            }
            await rtcService.release(roomID: callData.roomID)
        }
        call = nil
        session = nil
        elementCallService.endNativeCallSession(roomID: callData.roomID)
        #if targetEnvironment(simulator)
        CallAudioSessionConfigurator.deactivate()
        #endif
        
        if case .failed = connection {
            // Keep the failure visible until the screen is dismissed.
        } else {
            connection = .ended
        }
        connectedAt = nil
    }
    
    /// Previews only: shows a state without joining anything.
    func setPreviewState(callData: NativeCallData, connection: NativeCallConnection) {
        self.callData = callData
        self.connection = connection
    }
    
    /// Back to idle once the screen has gone; a new call can start.
    func reset() {
        guard !isInCall else { return }
        callData = nil
        connection = .idle
    }
}
