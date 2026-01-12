//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SpaceAddRoomsScreenSelectedItem: View {
    let room: SpaceAddRoomsScreenRoom
    let mediaProvider: MediaProviderProtocol?
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            avatar
                .accessibilityHidden(true)
            
            Text(room.title)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: L10n.actionRemove, dismissAction)
    }
    
    // MARK: - Private
    
    var avatar: some View {
        RoomAvatarImage(avatar: room.avatar,
                        avatarSize: .room(on: .spaceAddRoomsSelected),
                        mediaProvider: mediaProvider)
            .overlay(alignment: .topTrailing) {
                Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledFrame(size: 20)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.compound.iconOnSolidPrimary, Color.compound.iconPrimary)
                }
            }
    }
}

struct SpaceAddRoomsScreenSelectedItem_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SpaceAddRoomsScreenSelectedItem(room: .init(id: "",
                                                    title: "Selected Room",
                                                    description: "#selected:matrix.org",
                                                    avatar: .room(id: "",
                                                                  name: "Selected Room",
                                                                  avatarURL: .mockMXCAvatar)),
                                        mediaProvider: MediaProviderMock(configuration: .init())) { }
            .frame(width: 72)
    }
}
