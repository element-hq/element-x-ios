//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRtcKit
import SwiftUI

/// One participant: the avatar, name and mic badge, and an outline for the active speaker.
struct NativeCallTileView: View {
    let tile: NativeCallTile
    var isSpotlight = false
    var memberCount = 0
    let mediaProvider: MediaProviderProtocol?
    let onAction: (NativeCallScreenViewAction) -> Void
    
    var body: some View {
        ZStack {
            Color.compound.bgSubtleSecondary
            
            LoadableAvatarImage(url: tile.avatarURL,
                                name: tile.displayName,
                                contentID: tile.userID,
                                avatarSize: .user(on: .memberDetails),
                                mediaProvider: mediaProvider)
            
            cardChrome
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(outlineColor, lineWidth: 3)
        }
    }
    
    private var cardChrome: some View {
        VStack(spacing: 0) {
            HStack(spacing: 4) {
                if isSpotlight, memberCount > 0 {
                    badge {
                        CompoundIcon(\.userProfileSolid, size: .xSmall, relativeTo: .compound.bodySM)
                        Text("\(memberCount)")
                    }
                }
                Spacer()
            }
            Spacer()
            HStack(alignment: .bottom, spacing: 4) {
                badge {
                    CompoundIcon(tile.isMicrophoneMuted ? \.micOffSolid : \.micOnSolid, size: .xSmall, relativeTo: .compound.bodySM)
                    Text(tile.displayName)
                        .lineLimit(1)
                }
                Spacer()
            }
        }
        .padding(8)
    }
    
    private var outlineColor: Color {
        tile.isSpeaking ? .compound.borderSuccessSubtle : .clear
    }
    
    private func badge(@ViewBuilder content: () -> some View) -> some View {
        HStack(spacing: 4) { content() }
            .font(.compound.bodySMSemibold)
            .foregroundStyle(.compound.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.5), in: Capsule())
    }
}
