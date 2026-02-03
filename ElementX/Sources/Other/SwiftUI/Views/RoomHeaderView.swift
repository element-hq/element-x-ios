//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct RoomHeaderView: View {
    let roomName: String
    var roomSubtitle: String?
    let roomAvatar: RoomAvatar
    var dmRecipientVerificationState: UserIdentityVerificationState?
    var roomHistorySharingState: RoomHistorySharingState?
    
    let mediaProvider: MediaProviderProtocol?
    
    let action: () -> Void
    
    var body: some View {
        if #available(iOS 26.0, *) {
            // On iOS 26+ we use the toolbarRole(.editor) to leading align.
            content
                // Not using a Button here so that we get our custom padding around the avatar. This also
                // helps fix a bug where the top pixel was being clipped during the push/pop animation as
                // the Button styling results in a view that is slightly taller than a bar item should be.
                .padding(6)
                .padding(.trailing, 6)
                .glassEffect(.regular.interactive())
                .roomHeaderAction(action)
        } else {
            // On iOS 18 and lower, the editor role causes an animation glitch with the back button whenever
            // you push a screen whilst the large title is visible on the room screen.
            content
                // So take up as much space as possible, with a leading alignment for use in the default principal toolbar position
                .frame(idealWidth: .greatestFiniteMagnitude, maxWidth: .infinity, alignment: .leading)
                .roomHeaderAction(action)
        }
    }
    
    private var content: some View {
        HStack(spacing: 8) {
            avatarImage
                .accessibilityHidden(true)
            
            HStack(spacing: 4) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(roomName)
                        .lineLimit(1)
                        .font(.compound.bodyMDSemibold)
                        .accessibilityIdentifier(A11yIdentifiers.roomScreen.name)
                    if let roomSubtitle {
                        Text(roomSubtitle)
                            .lineLimit(1)
                            .font(.compound.bodyXS)
                            .foregroundStyle(.compound.textSecondary)
                    }
                }
                
                if let dmRecipientVerificationState {
                    VerificationBadge(verificationState: dmRecipientVerificationState, size: .xSmall, relativeTo: .compound.bodyMDSemibold)
                }
                
                if let historySharingIcon {
                    CompoundIcon(historySharingIcon, size: .xSmall, relativeTo: .compound.bodyMDSemibold)
                        .foregroundStyle(.compound.iconInfoPrimary)
                }
            }
        }
    }
    
    private var avatarImage: some View {
        RoomAvatarImage(avatar: roomAvatar,
                        avatarSize: .room(on: .timeline),
                        mediaProvider: mediaProvider)
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.avatar)
    }
    
    private var historySharingIcon: KeyPath<CompoundIcons, Image>? {
        switch roomHistorySharingState {
        case .shared: \.history
        case .worldReadable: \.userProfileSolid
        default: nil
        }
    }
}

extension RoomHeaderView {
    static var toolbarRole: ToolbarRole {
        if #available(iOS 26.0, *) {
            .editor
        } else {
            .automatic
        }
    }
}

private extension View {
    func roomHeaderAction(_ action: @escaping () -> Void) -> some View {
        // Using a button stops it from getting truncated in the navigation bar
        contentShape(.rect)
            .onTapGesture(perform: action)
            .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Previews

struct RoomHeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(alignment: .leading, spacing: 8) {
            makeHeader(avatarURL: nil, verificationState: .notVerified)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .notVerified)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .verified)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .verificationViolation)
            makeHeader(avatarURL: .mockMXCAvatar,
                       roomSubtitle: "Subtitle",
                       verificationState: .verified)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .notVerified, historySharingState: .shared)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .notVerified, historySharingState: .worldReadable)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .verified, historySharingState: .shared)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .verificationViolation, historySharingState: .worldReadable)
        }
        .previewLayout(.sizeThatFits)
    }
    
    static func makeHeader(avatarURL: URL?,
                           roomSubtitle: String? = nil,
                           verificationState: UserIdentityVerificationState,
                           historySharingState: RoomHistorySharingState? = nil) -> some View {
        RoomHeaderView(roomName: "Some Room name",
                       roomSubtitle: roomSubtitle,
                       roomAvatar: .room(id: "1",
                                         name: "Some Room Name",
                                         avatarURL: avatarURL),
                       dmRecipientVerificationState: verificationState,
                       roomHistorySharingState: historySharingState,
                       
                       mediaProvider: MediaProviderMock(configuration: .init())) { }
            .padding()
    }
}
