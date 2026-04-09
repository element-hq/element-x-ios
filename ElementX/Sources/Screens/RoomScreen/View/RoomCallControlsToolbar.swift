//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomCallControlsToolbar: ToolbarContent {
    let viewState: RoomScreenViewState
    let onCallTap: (_ isVoiceCall: Bool) -> Void
    
    var body: some ToolbarContent {
        if viewState.hasOngoingCall {
            ToolbarItem(placement: .primaryAction) {
                JoinCallButton {
                    onCallTap(false)
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
                .disabled(!viewState.canJoinCall)
            }
        } else {
            if viewState.isDirectOneToOneRoom {
                ToolbarItem(placement: .primaryAction) {
                    Button { onCallTap(true) } label: {
                        CompoundIcon(\.voiceCallSolid)
                    }
                    .accessibilityLabel(L10n.a11yStartVoiceCall)
                    .accessibilityIdentifier(A11yIdentifiers.roomScreen.startVoiceCall)
                    .disabled(!viewState.canJoinCall)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button { onCallTap(false) } label: {
                    CompoundIcon(\.videoCallSolid)
                }
                .accessibilityLabel(L10n.a11yStartVideoCall)
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.startVideoCall)
                .disabled(!viewState.canJoinCall)
            }
        }
    }
}

// MARK: - Previews

struct RoomCallControlsToolbar_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 0) {
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: true)) { _ in } }
            }
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: false, isDirectOneToOneRoom: true)) { _ in } }
            }
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: false)) { _ in } }
            }
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: false, canJoinCall: false)) { _ in } }
            }
        }
        .previewDisplayName("All states")
    }
}

private extension RoomScreenViewState {
    static func mock(hasOngoingCall: Bool, isDirectOneToOneRoom: Bool = false, canJoinCall: Bool = true) -> RoomScreenViewState {
        RoomScreenViewState(roomAvatar: .room(id: "mock", name: "Mock Room", avatarURL: nil),
                            canJoinCall: canJoinCall,
                            hasOngoingCall: hasOngoingCall, isDirectOneToOneRoom: isDirectOneToOneRoom,
                            hasSuccessor: false)
    }
}
