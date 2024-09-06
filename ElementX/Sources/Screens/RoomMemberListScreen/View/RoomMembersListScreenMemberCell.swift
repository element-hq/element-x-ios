//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct RoomMembersListScreenMemberCell: View {
    let member: RoomMemberDetails
    let context: RoomMembersListScreenViewModel.Context

    var body: some View {
        Button {
            context.send(viewAction: .selectMember(member))
        } label: {
            HStack(spacing: 8) {
                LoadableAvatarImage(url: avatarURL,
                                    name: avatarName,
                                    contentID: member.id,
                                    avatarSize: .user(on: .roomDetails),
                                    mediaProvider: context.mediaProvider)
                    .accessibilityHidden(true)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(title)
                            .font(.compound.bodyMDSemibold)
                            .foregroundColor(.compound.textPrimary)
                            .lineLimit(1)
                        
                        if let subtitle {
                            Text(subtitle)
                                .font(.compound.bodySM)
                                .foregroundColor(.compound.textSecondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    if let role {
                        Text(role)
                            .font(.compound.bodyXS)
                            .foregroundStyle(.compound.textSecondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
    
    var role: String? {
        switch member.role {
        case .administrator:
            L10n.screenRoomMemberListRoleAdministrator
        case .moderator:
            L10n.screenRoomMemberListRoleModerator
        case .user:
            nil
        }
    }
    
    // Computed properties to hide the user's profile when banned.
    
    var title: String {
        guard !member.isBanned else { return member.id }
        return member.name ?? member.id
    }
    
    var subtitle: String? {
        member.isBanned ? nil : member.id
    }
    
    var avatarName: String? {
        member.isBanned ? nil : member.name
    }
    
    var avatarURL: URL? {
        member.isBanned ? nil : member.avatarURL
    }
}

struct RoomMembersListMemberCell_Previews: PreviewProvider, TestablePreview {
    static let members: [RoomMemberProxyMock] = [
        .mockAlice,
        .mockAdmin,
        .mockModerator,
        .init(with: .init(userID: "@nodisplayname:matrix.org", membership: .join)),
        .init(with: .init(userID: "@avatar:matrix.org", displayName: "Avatar", avatarURL: .picturesDirectory, membership: .join))
    ]
    
    static let bannedMembers: [RoomMemberProxyMock] = [
        .init(with: .init(userID: "@nodisplayname:matrix.org", membership: .ban)),
        .init(with: .init(userID: "@fake:matrix.org", displayName: "President", membership: .ban)),
        .init(with: .init(userID: "@badavatar:matrix.org", avatarURL: .picturesDirectory, membership: .ban))
    ]
    
    static let viewModel = RoomMembersListScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(name: "Some room",
                                                                                               members: members)),
                                                          mediaProvider: MockMediaProvider(),
                                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                          analytics: ServiceLocator.shared.analytics)
    static var previews: some View {
        VStack(spacing: 12) {
            Section("Invited/Joined") {
                ForEach(members, id: \.userID) { member in
                    RoomMembersListScreenMemberCell(member: .init(withProxy: member), context: viewModel.context)
                }
            }
            
            // Banned members should have their profiles hidden and the avatar should use the first letter from their user ID.
            Section("Banned") {
                ForEach(bannedMembers, id: \.userID) { member in
                    RoomMembersListScreenMemberCell(member: .init(withProxy: member), context: viewModel.context)
                }
            }
        }
    }
}
