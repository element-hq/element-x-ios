//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RoomChangeRolesScreenSelectedItem: View {
    let member: RoomMemberDetails
    let mediaProvider: MediaProviderProtocol?
    let dismissAction: (() -> Void)?
    
    var body: some View {
        mainContent
            .accessibilityActions {
                if let dismissAction {
                    Button(L10n.actionDismiss) {
                        dismissAction()
                    }
                }
            }
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        VStack(spacing: 4) {
            avatar
            
            Text(member.name ?? member.id)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
    }
    
    var avatar: some View {
        LoadableAvatarImage(url: member.avatarURL,
                            name: member.name,
                            contentID: member.id,
                            avatarSize: .user(on: .roomChangeRoles),
                            mediaProvider: mediaProvider)
            .accessibilityHidden(true)
            .overlay(alignment: .topTrailing) {
                if let dismissAction {
                    Button(action: dismissAction) {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .scaledFrame(size: 20)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(Color.compound.iconOnSolidPrimary, Color.compound.iconPrimary)
                    }
                    // We will use the accessibility action
                    .accessibilityHidden(true)
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
                                                  mediaProvider: MediaProviderMock(configuration: .init())) { }
                    .frame(width: 72)
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
