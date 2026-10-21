//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CallKit
import Combine

/// What an account's call service asks of the `ElementCallManager`, which owns CallKit and the VoIP pushes.
enum ElementCallServiceAction: Equatable {
    case callSessionStarted(roomID: String, roomDisplayName: String, isVideo: Bool)
    case callSessionEnded(roomID: String)
    case audioEnabledChanged(_ enabled: Bool, roomID: String)
    /// The call ringing for this account ended without the user: hung up, or answered or declined on another device.
    case incomingCallEnded(roomID: String, reason: CXCallEndedReason)
}

// sourcery: AutoMockable
/// An account's side of its Element Call calls: the room of a call ringing for it, its declines and its ongoing call.
protocol ElementCallServiceProtocol: AnyObject {
    var userID: String { get }
    var actionsPublisher: AnyPublisher<ElementCallServiceAction, Never> { get }
    /// The room of this account's ongoing call, `nil` when it has none.
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> { get }
    
    // MARK: Call screen
    
    func setupCallSession(roomID: String, roomDisplayName: String, isVideo: Bool)
    func tearDownCallSession(roomID: String)
    func setAudioEnabled(_ enabled: Bool, roomID: String)
    
    // MARK: Manager
    
    /// Watches the room of a call ringing for this account, reporting when it stops ringing elsewhere.
    func observeIncomingCall(roomID: String, rtcNotificationID: String?) async
    func stopObservingIncomingCall()
    func declineCall(roomID: String, rtcNotificationID: String) async
    func ongoingCallChanged(roomID: String?)
}
