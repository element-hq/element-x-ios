//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct RoomHeaderView: View {
    let roomName: String
    let roomSubtitle: String?
    let roomAvatar: RoomAvatar
    var dmRecipientVerificationState: UserIdentityVerificationState?
    
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        HStack(spacing: 8) {
            avatarImage
                .accessibilityHidden(true)
            HStack(spacing: 4) {
            VStack(alignment: .leading) {
                Text(roomName)
                    .lineLimit(1)
                    .font(.zero.bodyMDSemibold)
                    .accessibilityIdentifier(A11yIdentifiers.roomScreen.name)
                if let subtitle = roomSubtitle {
                    Text(subtitle)
                        .lineLimit(1)
                        .padding(.vertical, 1)
                        .font(.zero.bodySMSemibold)
                        .foregroundStyle(.compound.textSecondary)
                }
            }
                if let dmRecipientVerificationState {
                    VerificationBadge(verificationState: dmRecipientVerificationState)
                }
            }
        }
        // Take up as much space as possible, with a leading alignment for use in the principal toolbar position.
        // .frame(idealWidth: .greatestFiniteMagnitude, maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var avatarImage: some View {
        RoomAvatarImage(avatar: roomAvatar,
                        avatarSize: .room(on: .timeline),
                        mediaProvider: mediaProvider)
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.avatar)
    }
}

struct RoomHeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 8) {
            makeHeader(avatarURL: nil, verificationState: .notVerified)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .notVerified)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .verified)
            makeHeader(avatarURL: .mockMXCAvatar, verificationState: .verificationViolation)
        }
        .previewLayout(.sizeThatFits)
    }
    
    static func makeHeader(avatarURL: URL?,
                           verificationState: UserIdentityVerificationState) -> some View {
        RoomHeaderView(roomName: "Some Room name",
                       roomSubtitle: nil,
                       roomAvatar: .room(id: "1",
                                         name: "Some Room Name",
                                         avatarURL: avatarURL),
                       dmRecipientVerificationState: verificationState,
                       mediaProvider: MediaProviderMock(configuration: .init()))
            .padding()
    }
}
