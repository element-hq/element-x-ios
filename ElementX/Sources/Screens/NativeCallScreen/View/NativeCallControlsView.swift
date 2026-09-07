//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import Compound
import SwiftUI

/// The floating bottom bar from the design: mic, audio route, hang up; camera and screen share come
/// with their features.
struct NativeCallControlsView: View {
    @Bindable var context: NativeCallScreenViewModel.Context
    
    var body: some View {
        HStack(spacing: 12) {
            controlButton(icon: context.viewState.isMicrophoneMuted ? \.micOffSolid : \.micOnSolid,
                          isActive: !context.viewState.isMicrophoneMuted,
                          label: context.viewState.isMicrophoneMuted ? "Unmute" : "Mute") {
                context.send(viewAction: .toggleMicrophone)
            }
            audioRouteButton
            Button {
                context.send(viewAction: .hangUp)
            } label: {
                CompoundIcon(\.endCall)
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Color.compound.bgCriticalPrimary, in: Circle())
            }
            .accessibilityLabel("Hang up")
        }
        .padding(8)
        .background(Color.compound.bgCanvasDefaultLevel1.opacity(0.9), in: Capsule())
    }
    
    /// Speaker toggles the loudspeaker; a long press opens the system route picker for
    /// Bluetooth and other outputs.
    private var audioRouteButton: some View {
        ZStack {
            controlButton(icon: context.viewState.isLoudspeaker ? \.volumeOnSolid : \.volumeOffSolid,
                          isActive: !context.viewState.isLoudspeaker,
                          label: "Audio output") {
                context.send(viewAction: .toggleLoudspeaker)
            }
            NativeAudioRoutePicker()
                .frame(width: 56, height: 56)
                .opacity(0.02)
        }
    }
    
    /// `isActive` is the resting state (dark circle); the inverse is the highlighted white circle
    /// the design uses for mic off, camera off, sharing and loudspeaker.
    private func controlButton(icon: KeyPath<CompoundIcons, Image>, isActive: Bool, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            CompoundIcon(icon)
                .foregroundStyle(isActive ? .compound.iconPrimary : .compound.iconOnSolidPrimary)
                .frame(width: 56, height: 56)
                .background(isActive ? Color.compound.bgSubtleSecondary : Color.compound.bgActionPrimaryRest, in: Circle())
        }
        .accessibilityLabel(label)
    }
}

struct NativeCallRoundButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.compound.iconPrimary)
            .frame(width: 44, height: 44)
            .background(Color.compound.bgSubtleSecondary.opacity(configuration.isPressed ? 0.6 : 1), in: Circle())
    }
}

/// The system output picker, drawn nearly transparent over the speaker button so a tap reaches it.
struct NativeAudioRoutePicker: UIViewRepresentable {
    func makeUIView(context: Context) -> AVRoutePickerView {
        let view = AVRoutePickerView()
        view.prioritizesVideoDevices = false
        return view
    }
    
    func updateUIView(_ uiView: AVRoutePickerView, context: Context) { }
}
