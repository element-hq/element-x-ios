//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomChangeRolesScreenSection: View {
    let members: [RoomMemberDetails]
    let title: String
    var isAdministratorsSection = false
    
    @ObservedObject var context: RoomChangeRolesScreenViewModel.Context
    
    var body: some View {
        if !members.isEmpty {
            Section {
                ForEach(members, id: \.id) { member in
                    RoomChangeRolesScreenRow(member: member,
                                             mediaProvider: context.mediaProvider,
                                             isSelected: isMemberSelected(member)) {
                        context.send(viewAction: .toggleMember(member))
                    }
                    .disabled(member.role == .administrator)
                }
            } header: {
                Text(title)
                    .compoundListSectionHeader()
            } footer: {
                if isAdministratorsSection, context.viewState.mode == .moderator {
                    Text(L10n.screenRoomChangeRoleModeratorsAdminSectionFooter)
                        .compoundListSectionFooter()
                }
            }
        }
    }
    
    private func isMemberSelected(_ member: RoomMemberDetails) -> Bool {
        // We always show administrators as selected, even on the moderators screen.
        member.role == .administrator || context.viewState.isMemberSelected(member)
    }
}
