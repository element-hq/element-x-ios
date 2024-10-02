//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct RoomHeaderView: View {
    let roomName: String
    let roomAvatar: RoomAvatar
    
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        HStack(spacing: 12) {
            avatarImage
                .accessibilityHidden(true)
            Text(roomName)
                .lineLimit(1)
                .font(.compound.bodyLGSemibold)
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.name)
        }
        // Leading align whilst using the principal toolbar position.
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
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
                       roomAvatar: .room(id: "1",
                                         name: "Some Room Name",
                                         avatarURL: URL.picturesDirectory),
                       mediaProvider: MockMediaProvider())
            .previewLayout(.sizeThatFits)
            .padding()
        
        RoomHeaderView(roomName: "Some Room name",
                       roomAvatar: .room(id: "1",
                                         name: "Some Room Name",
                                         avatarURL: nil),
                       mediaProvider: MockMediaProvider())
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
