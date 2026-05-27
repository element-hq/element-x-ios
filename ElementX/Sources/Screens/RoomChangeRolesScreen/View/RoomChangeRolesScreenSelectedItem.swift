//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomChangeRolesScreenSelectedItem: View {
    let member: RoomMemberDetails
    let mediaProvider: MediaProviderProtocol?
    let dismissAction: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 4) {
            if let dismissAction {
                avatar.overlayRemoveItemButton(action: dismissAction)
            } else {
                avatar
            }
            
            Text(member.name ?? member.id)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if let dismissAction {
                Button(L10n.actionDismiss) {
                    dismissAction()
                }
            }
        }
    }
    
    var avatar: some View {
        LoadableAvatarImage(url: member.avatarURL,
                            name: member.name,
                            contentID: member.id,
                            avatarSize: .user(on: .roomChangeRoles),
                            mediaProvider: mediaProvider)
            .accessibilityHidden(true)
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
                                                  mediaProvider: MediaProviderMock(.init())) { }
                    .frame(width: 72)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
