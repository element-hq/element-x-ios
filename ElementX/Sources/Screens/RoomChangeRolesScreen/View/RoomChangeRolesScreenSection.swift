//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
