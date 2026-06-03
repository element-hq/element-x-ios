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
                JoinCallButton(isVoiceCall: viewState.activeRoomCallIntent == .audio) {
                    onCallTap(viewState.activeRoomCallIntent == .audio)
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
                .disabled(!viewState.canJoinCall)
            }
        } else {
            if viewState.isDM {
                if viewState.roomThreadListEnabled {
                    // If the developer mode room thread list option is enabled there
                    // is not enough place for 2 calls buttons
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                onCallTap(true)
                            } label: {
                                Label(L10n.a11yStartVoiceCall, icon: \.voiceCallSolid)
                            }
                            
                            Button {
                                onCallTap(false)
                            } label: {
                                Label(L10n.a11yStartVideoCall, icon: \.videoCallSolid)
                            }
                        } label: {
                            CompoundIcon(\.voiceCallSolid)
                        }
                        .accessibilityLabel(L10n.a11yStartCall)
                        .disabled(!viewState.canJoinCall)
                    }
                } else {
                    ToolbarItem(placement: .primaryAction) {
                        Button { onCallTap(false) } label: {
                            CompoundIcon(\.videoCallSolid)
                        }
                        .accessibilityLabel(L10n.a11yStartVideoCall)
                        .accessibilityIdentifier(A11yIdentifiers.roomScreen.startVideoCall)
                        .disabled(!viewState.canJoinCall)
                    }
                    
                    ToolbarItem(placement: .primaryAction) {
                        Button { onCallTap(true) } label: {
                            CompoundIcon(\.voiceCallSolid)
                        }
                        .accessibilityLabel(L10n.a11yStartVoiceCall)
                        .accessibilityIdentifier(A11yIdentifiers.roomScreen.startVoiceCall)
                        .disabled(!viewState.canJoinCall)
                    }
                }
            } else {
                ToolbarItem(placement: .primaryAction) {
                    Button { onCallTap(false) } label: {
                        CompoundIcon(\.videoCallSolid)
                    }
                    .accessibilityLabel(L10n.a11yStartVideoCall)
                    .disabled(!viewState.canJoinCall)
                }
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
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: false, isDM: true)) { _ in } }
            }
            
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: false, isDM: true, roomThreadListEnabled: true)) { _ in } }
            }
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: false)) { _ in } }
            }
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: false, canJoinCall: false)) { _ in } }
            }
            ElementNavigationStack {
                Color.clear.toolbar { RoomCallControlsToolbar(viewState: .mock(hasOngoingCall: true, activeRoomCallIntent: .audio)) { _ in } }
            }
        }
        .previewDisplayName("All states")
    }
}

private extension RoomScreenViewState {
    static func mock(hasOngoingCall: Bool, isDM: Bool = false, canJoinCall: Bool = true, activeRoomCallIntent: CallIntent? = nil, roomThreadListEnabled: Bool = false) -> RoomScreenViewState {
        RoomScreenViewState(roomAvatar: .room(id: "mock", name: "Mock Room", avatarURL: nil),
                            canJoinCall: canJoinCall,
                            hasOngoingCall: hasOngoingCall,
                            activeRoomCallIntent: activeRoomCallIntent,
                            isDM: isDM,
                            roomThreadListEnabled: roomThreadListEnabled,
                            hasSuccessor: false)
    }
}
