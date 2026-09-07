//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRtcKit
import SwiftUI

/// The full-screen call: top bar, the participants' tiles and the floating control bar. Layout
/// follows the iOS call design.
struct NativeCallScreen: View {
    @Bindable var context: NativeCallScreenViewModel.Context
    
    var body: some View {
        ZStack {
            Color.compound.bgCanvasDefault.ignoresSafeArea()
            
            VStack(spacing: 12) {
                topBar
                    .padding(.horizontal, 16)
                content
            }
            
            VStack(spacing: 0) {
                Spacer()
                NativeCallControlsView(context: context)
                    .padding(.bottom, Self.controlsBottomPadding)
            }
        }
        .environment(\.colorScheme, .dark)
        .statusBarHidden(false)
        .onAppear { UIApplication.shared.isIdleTimerDisabled = true }
        .onDisappear { UIApplication.shared.isIdleTimerDisabled = false }
    }
    
    // MARK: - Top bar
    
    private var topBar: some View {
        HStack(spacing: 8) {
            Button { context.send(viewAction: .minimize) } label: {
                CompoundIcon(\.collapse)
            }
            .buttonStyle(NativeCallRoundButtonStyle())
            .accessibilityLabel(L10n.actionBack)
            
            Spacer()
            
            VStack(spacing: 2) {
                Text(context.viewState.roomName)
                    .font(.compound.bodyLGSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .lineLimit(1)
                statusLine
            }
            
            Spacer()
            
            // Balances the collapse button so the title stays centred.
            Color.clear
                .frame(width: 44, height: 44)
        }
    }
    
    @ViewBuilder
    private var statusLine: some View {
        switch context.viewState.connection {
        case .idle, .joining:
            Text("Joining…").font(.compound.bodySM).foregroundStyle(.compound.textSecondary)
        case .connectingMedia:
            Text("Connecting…").font(.compound.bodySM).foregroundStyle(.compound.textSecondary)
        case .connected:
            if let connectedAt = context.viewState.connectedAt {
                Text(connectedAt, style: .timer)
                    .font(.compound.bodySM)
                    .foregroundStyle(context.viewState.isMediaDegraded ? .compound.textCriticalPrimary : .compound.textSecondary)
                    .monospacedDigit()
            }
        case .ended:
            Text("Call ended").font(.compound.bodySM).foregroundStyle(.compound.textSecondary)
        case .failed(let message):
            Text(message).font(.compound.bodySM).foregroundStyle(.compound.textCriticalPrimary).lineLimit(2)
        }
    }
    
    // MARK: - Content
    
    /// The floating controls: a 56 pt button in an 8 pt capsule, this far above the safe area.
    private static let controlsBottomPadding: CGFloat = 12
    private static let controlsHeight: CGFloat = 56 + 2 * 8
    
    @ViewBuilder
    private var content: some View {
        let state = context.viewState
        if state.tiles.isEmpty {
            Spacer()
            ProgressView()
                .tint(.compound.iconPrimary)
            Spacer()
        } else {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(state.tiles) { tile in
                        NativeCallTileView(tile: tile, memberCount: state.memberCount, mediaProvider: context.mediaProvider) { action in
                            context.send(viewAction: action)
                        }
                        .aspectRatio(1.2, contentMode: .fit)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, Self.controlsHeight + Self.controlsBottomPadding + 12)
            }
        }
    }
}

// MARK: - Previews

struct NativeCallScreen_Previews: PreviewProvider, TestablePreview {
    static let joiningViewModel = NativeCallScreenPreviewFactory.makeViewModel(connection: .joining)
    static let failedViewModel = NativeCallScreenPreviewFactory.makeViewModel(connection: .failed("Homeserver offers no LiveKit transport"))
    
    static var previews: some View {
        NativeCallScreen(context: joiningViewModel.context)
            .previewDisplayName("Joining")
        NativeCallScreen(context: failedViewModel.context)
            .previewDisplayName("Failed")
    }
}
