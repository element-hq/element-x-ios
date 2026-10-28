//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import ElementCall

/// What the host has to do about a native call, beyond running it.
enum NativeCallPresentation: Equatable {
    case present
    case restore
    case minimize
    case dismiss
}

/// What CallKit asks of the native call.
enum NativeCallEvent: Equatable {
    case audioSessionActivated
    case audioSessionDeactivated
    /// The mute changed outside the call screen, from the lock screen or the system call UI.
    case microphoneMuteChanged(isMuted: Bool)
    /// The system ended the call, from the lock screen or because the user hung up elsewhere.
    case endCallRequested(roomID: String)
}

/// Why a call ended without us, which the system shows in the call log.
enum CallEndReason: Equatable {
    case remoteEnded
    case answeredElsewhere
    case declinedElsewhere
    case unanswered
    case failed
}

enum ElementCallSessionKind: Equatable {
    case webView
    case native
    case nativeAnswer
}

/// What the service asks of the `ElementCallManager`, which owns CallKit and the VoIP pushes.
enum ElementCallServiceAction: Equatable {
    case callSessionStarted(roomID: String, roomDisplayName: String, isVideo: Bool, kind: ElementCallSessionKind)
    case callSessionConnected(roomID: String)
    /// A `nil` reason means the call ended here: our hang-up, or the call screen closing.
    case callSessionEnded(roomID: String, reason: CallEndReason?)
    case audioEnabledChanged(_ enabled: Bool, roomID: String)
    /// The ringing call ended without the user: hung up, or answered or declined on another device.
    case incomingCallEnded(roomID: String, reason: CallEndReason)
}

// sourcery: AutoMockable
protocol ElementCallServiceProtocol: AnyObject {
    var actionsPublisher: AnyPublisher<ElementCallServiceAction, Never> { get }
    
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> { get }
    
    /// What CallKit asks of the native call: audio session changes, mutes and hang-ups.
    var nativeCallEventsPublisher: AnyPublisher<NativeCallEvent, Never> { get }
    
    /// The native call's screen needs presenting, minimizing, restoring or dismissing.
    var nativeCallPresentationPublisher: AnyPublisher<NativeCallPresentation, Never> { get }
    
    /// The controller for this session's native call stack, `nil` when native calls are unavailable.
    var nativeCallController: ElementCallController? { get }
    
    /// Builds the native call stack for the session, or releases it along with the to-device
    /// subscription it holds open. Pass `nil` when signing out.
    func setUserSession(_ userSession: UserSessionProtocol?)
    
    /// Starts, or returns to, a native call in the room, driving its screen through
    /// ``nativeCallPresentationPublisher``.
    ///
    /// Returns `false` when there's no native call stack and the caller should present the Element
    /// Call web view instead.
    @discardableResult
    func handleNativeCallRequest(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool) -> Bool
    
    /// Asks the native call to minimize. The screen only comes down once a system window has
    /// started, which arrives through ``nativeCallPresentationPublisher``.
    func minimizeNativeCall()
    
    /// Brings the native call back out of its system window.
    func restoreNativeCall()
    
    // MARK: Call screens
    
    /// Registers the call with CallKit, adopting the ringing incoming call for the room if there is one.
    /// Returns once the manager has set the call up.
    func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool, kind: ElementCallSessionKind) async
    
    /// Tells CallKit the call is connected. Does nothing for web view calls, which CallKit never tracks.
    func reportCallSessionConnected(roomID: String)
    
    /// Ends the call for the room, including an answered call the native stack never took over.
    func tearDownCallSession(roomID: String)
    
    /// The call for the room ended without us: declined, unanswered, the other side gone, or failed.
    /// Reported to the system as such rather than as an end call action, which would log it as one
    /// we hung up and ask the call stack to end a call it already has.
    func reportCallSessionEnded(roomID: String, reason: CallEndReason)
    
    /// Mirrors the native call's mute into CallKit. Web view calls aren't tracked there, so they
    /// never call this.
    func setAudioEnabled(_ enabled: Bool, roomID: String)
    
    // MARK: Manager
    
    /// Watches the room of the ringing call, reporting when it stops ringing elsewhere.
    func observeIncomingCall(roomID: String, rtcNotificationID: String?) async
    func stopObservingIncomingCall()
    func declineCall(roomID: String, rtcNotificationID: String) async
    func ongoingCallChanged(roomID: String?)
    /// Completes the room's `setupCallSession`.
    func callSessionSetUp(roomID: String, isAccepted: Bool)
    /// CallKit's side of the native call: the audio session, mutes and hang-ups.
    func systemEventReceived(_ event: NativeCallEvent)
}
