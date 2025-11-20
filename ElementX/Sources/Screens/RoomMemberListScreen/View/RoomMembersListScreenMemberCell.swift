//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomMembersListScreenMemberCell: View {
    let listEntry: RoomMemberListScreenEntry
    let isLast: Bool
    let context: RoomMembersListScreenViewModel.Context

    var body: some View {
        Button {
            context.send(viewAction: .selectMember(listEntry.member))
        } label: {
            HStack(spacing: 16) {
                LoadableAvatarImage(url: avatarURL,
                                    name: avatarName,
                                    contentID: listEntry.member.id,
                                    avatarSize: .user(on: .roomMembersList),
                                    mediaProvider: context.mediaProvider)
                    .accessibilityHidden(true)
                
                HStack(alignment: .center, spacing: 4) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.compound.bodyLG)
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
                    
                    VerificationBadge(verificationState: listEntry.verificationState)
                    
                    if let role {
                        Text(role)
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                    }
                }
                .overlay(alignment: .bottom) {
                    if !isLast {
                        ListRowColor.separatorTint
                            .frame(height: 1)
                            .offset(x: 0, y: ListRowPadding.vertical)
                    }
                }
            }
            .padding(ListRowPadding.insets)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
    
    var role: String? {
        switch listEntry.member.role {
        case .creator, .owner:
            L10n.screenRoomMemberListRoleOwner
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
        guard !listEntry.member.isBanned else { return listEntry.member.id }
        return listEntry.member.name ?? listEntry.member.id
    }
    
    var subtitle: String? {
        listEntry.member.isBanned ? nil : listEntry.member.id
    }
    
    var avatarName: String? {
        listEntry.member.isBanned ? nil : listEntry.member.name
    }
    
    var avatarURL: URL? {
        listEntry.member.isBanned ? nil : listEntry.member.avatarURL
    }
}

struct RoomMembersListMemberCell_Previews: PreviewProvider, TestablePreview {
    static let members: [RoomMemberListScreenEntry] = [
        .init(member: .init(withProxy: RoomMemberProxyMock.mockAlice),
              verificationState: .notVerified),
        .init(member: .init(withProxy: RoomMemberProxyMock.mockAdmin),
              verificationState: .verified),
        .init(member: .init(withProxy: RoomMemberProxyMock.mockModerator),
              verificationState: .verificationViolation),
        .init(member: .init(withProxy: RoomMemberProxyMock(with: .init(userID: "@nodisplayname:matrix.org",
                                                                       membership: .join))),
        verificationState: .notVerified),
        .init(member: .init(withProxy: RoomMemberProxyMock(with: .init(userID: "@avatar:matrix.org",
                                                                       displayName: "Avatar",
                                                                       avatarURL: .mockMXCUserAvatar,
                                                                       membership: .join))),
        verificationState: .notVerified)
    ]
    
    static let bannedMembers: [RoomMemberListScreenEntry] = [
        .init(member: .init(withProxy: RoomMemberProxyMock(with: .init(userID: "@nodisplayname:matrix.org",
                                                                       membership: .ban))),
        verificationState: .notVerified),
        .init(member: .init(withProxy: RoomMemberProxyMock(with: .init(userID: "@fake:matrix.org",
                                                                       displayName: "President",
                                                                       membership: .ban))),
        verificationState: .verified),
        .init(member: .init(withProxy: RoomMemberProxyMock(with: .init(userID: "@badavatar:matrix.org",
                                                                       avatarURL: .mockMXCUserAvatar,
                                                                       membership: .ban))),
        verificationState: .verificationViolation)
    ]
    
    static let viewModel = RoomMembersListScreenViewModel(userSession: UserSessionMock(.init()),
                                                          roomProxy: JoinedRoomProxyMock(.init(name: "Some room", members: [])),
                                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                          analytics: ServiceLocator.shared.analytics)
    static var previews: some View {
        VStack(spacing: 0) {
            Section("Invited/Joined") {
                ForEach(members, id: \.member.id) { entry in
                    RoomMembersListScreenMemberCell(listEntry: entry, isLast: members.last == entry, context: viewModel.context)
                }
            }
            
            // Banned members should have their profiles hidden and the avatar should use the first letter from their user ID.
            Section("Banned") {
                ForEach(bannedMembers, id: \.member.id) { entry in
                    RoomMembersListScreenMemberCell(listEntry: entry, isLast: bannedMembers.last == entry, context: viewModel.context)
                }
            }
        }
    }
}
