//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomChangeRolesScreenSection: View {
    let members: [RoomMemberDetails]
    let role: RoomRole
    
    let context: RoomChangeRolesScreenViewModel.Context
    
    var title: String {
        switch role {
        case .creator, .owner:
            L10n.screenRoomRolesAndPermissionsOwners
        case .administrator:
            L10n.screenRoomChangeRoleSectionAdministrators
        case .moderator:
            L10n.screenRoomChangeRoleSectionModerators
        case .user:
            L10n.screenRoomChangeRoleSectionUsers
        }
    }
    
    var body: some View {
        if !members.isEmpty {
            Section {
                ForEach(members, id: \.id) { member in
                    RoomChangeRolesScreenRow(member: member,
                                             mediaProvider: context.mediaProvider,
                                             isSelected: context.viewState.isMemberSelected(member)) {
                        context.send(viewAction: .toggleMember(member))
                    }
                    .disabled(context.viewState.isMemberDisabled(member))
                }
            } header: {
                Text(title)
                    .compoundListSectionHeader()
            } footer: {
                if role == .administrator, context.viewState.mode == .moderator {
                    Text(L10n.screenRoomChangeRoleModeratorsAdminSectionFooter)
                        .compoundListSectionFooter()
                } else if role.isOwner, context.viewState.mode != .owner {
                    Text(L10n.screenRoomChangeRoleModeratorsOwnerSectionFooter)
                        .compoundListSectionFooter()
                }
            }
        }
    }
}
