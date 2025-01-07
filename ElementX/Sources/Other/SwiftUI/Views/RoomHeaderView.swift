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
    
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        HStack(spacing: 12) {
            avatarImage
                .accessibilityHidden(true)
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
        RoomHeaderView(roomName: "Some Room name",
                       roomSubtitle: nil,
                       roomAvatar: .room(id: "1",
                                         name: "Some Room Name",
                                         avatarURL: .mockMXCAvatar),
                       mediaProvider: MediaProviderMock(configuration: .init()))
            .previewLayout(.sizeThatFits)
            .padding()
        
        RoomHeaderView(roomName: "Some Room name",
                       roomSubtitle: nil,
                       roomAvatar: .room(id: "1",
                                         name: "Some Room Name",
                                         avatarURL: nil),
                       mediaProvider: MediaProviderMock(configuration: .init()))
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
