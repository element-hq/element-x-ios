//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum NativeCallScreenViewModelAction {
    case minimize
    case dismiss
}

/// One tile of the call: a member as the layout sees it, video or avatar.
struct NativeCallTile: Identifiable, Equatable {
    let memberID: String
    let userID: String
    let displayName: String
    let avatarURL: URL?
    let isLocal: Bool
    /// Cannot be heard: muted, or no microphone stream reached us at all. The badge collapses the
    /// two on purpose; `hasMicrophone` keeps them apart for the stats overlay, where the question is why.
    let isMicrophoneMuted: Bool
    /// Whether a microphone stream reaches us at all, muted or not. Absent is a fault worth showing:
    /// a member the SFU relays to everyone else would otherwise read here as having muted themselves.
    let hasMicrophone: Bool
    let isSpeaking: Bool
    let audioLevel: Float
    
    var id: String {
        memberID
    }
}

struct NativeCallScreenViewState: BindableState {
    var roomName: String
    var connection: NativeCallConnection = .idle
    var connectedAt: Date?
    var memberCount = 0
    var tiles: [NativeCallTile] = []
    var isMicrophoneMuted = false
    var isLoudspeaker = false
    var isMediaDegraded = false
    
    var bindings = NativeCallScreenViewStateBindings()
}

struct NativeCallScreenViewStateBindings { }

enum NativeCallScreenViewAction {
    case toggleMicrophone
    case toggleLoudspeaker
    case minimize
    case hangUp
    case dismiss
}
