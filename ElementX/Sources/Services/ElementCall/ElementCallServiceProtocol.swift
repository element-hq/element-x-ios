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

enum ElementCallServiceAction {
    case receivedIncomingCallRequest
    case startCall(roomID: String, isVoiceCall: Bool)
    case endCall(roomID: String)
    case setAudioEnabled(_ enabled: Bool, roomID: String)
    /// CallKit activated the audio session: a native call may start its audio engine now.
    case audioSessionActivated
    case audioSessionDeactivated
    /// The native call's screen needs presenting, minimizing, restoring or dismissing.
    case nativeCall(NativeCallPresentation)
}

// sourcery: AutoMockable
protocol ElementCallServiceProtocol: AnyObject {
    var actions: AnyPublisher<ElementCallServiceAction, Never> { get }
    
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> { get }
    
    /// The controller for this session's native call stack, `nil` when native calls are unavailable.
    var nativeCallController: ElementCallController? { get }
    
    /// Builds the native call stack for the session, or releases it along with the to-device
    /// subscription it holds open. Pass `nil` when signing out.
    func setUserSession(_ userSession: UserSessionProtocol?)
    
    /// Starts, or returns to, a native call in the room, driving its screen through
    /// ``ElementCallServiceAction/nativeCall(_:)``.
    ///
    /// Returns `false` when there's no native call stack and the caller should present the Element
    /// Call web view instead.
    @discardableResult
    func handleNativeCallRequest(roomProxy: JoinedRoomProxyProtocol, isVoiceCall: Bool) -> Bool
    
    /// Asks the native call to minimize. The screen only comes down once a system window has
    /// started, which arrives as ``ElementCallServiceAction/nativeCall(_:)``.
    func minimizeNativeCall()
    
    /// Brings the native call back out of its system window.
    func restoreNativeCall()
    
    /// Registers the call with CallKit, adopting the ringing incoming call for the room if there is one.
    func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool) async
    
    /// Tells CallKit the call is connected. Does nothing for web view calls, which CallKit never tracks.
    func reportCallSessionConnected(roomID: String)
    
    /// Ends the call for the room, including an answered call the native stack never took over.
    func tearDownCallSession(roomID: String)
    
    func setAudioEnabled(_ enabled: Bool, roomID: String)
}
