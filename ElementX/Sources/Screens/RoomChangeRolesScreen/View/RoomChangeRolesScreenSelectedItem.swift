//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct RoomChangeRolesScreenSelectedItem: View {
    let member: RoomMemberDetails
    let mediaProvider: MediaProviderProtocol?
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            avatar
            
            Text(member.name ?? member.id)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
    }
    
    // MARK: - Private
    
    var avatar: some View {
        LoadableAvatarImage(url: member.avatarURL,
                            name: member.name,
                            contentID: member.id,
                            avatarSize: .user(on: .inviteUsers),
                            mediaProvider: mediaProvider)
            .overlay(alignment: .topTrailing) {
                if member.role != .administrator {
                    Button(action: dismissAction) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledFrame(size: 20)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.compound.iconOnSolidPrimary, Color.compound.iconPrimary)
                    }
                    .offset(x: 4)
                }
            }
    }
}

struct RoomChangeRolesScreenSelectedItem_Previews: PreviewProvider, TestablePreview {
    static let members: [RoomMemberDetails] = [
        RoomMemberProxyMock.mockAlice,
        RoomMemberProxyMock.mockDan,
        RoomMemberProxyMock.mockVerbose,
        RoomMemberProxyMock(with: .init(userID: "@someone:server.org", membership: .join)),
        RoomMemberProxyMock.mockAdmin
    ]
    .map { .init(withProxy: $0) }
    
    static var previews: some View {
        HStack(spacing: 12) {
            ForEach(members, id: \.id) { member in
                RoomChangeRolesScreenSelectedItem(member: member,
                                                  mediaProvider: MockMediaProvider(),
                                                  dismissAction: { })
                    .frame(width: 72)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
