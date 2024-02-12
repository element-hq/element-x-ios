//
// Copyright 2022 New Vector Ltd
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

import SwiftUI

struct RoomMembersListScreenMemberCell: View {
    let member: RoomMemberDetails
    let context: RoomMembersListScreenViewModel.Context

    var body: some View {
        Button {
            context.send(viewAction: .selectMember(id: member.id))
        } label: {
            HStack(spacing: 8) {
                LoadableAvatarImage(url: member.avatarURL,
                                    name: member.name ?? "",
                                    contentID: member.id,
                                    avatarSize: .user(on: .roomDetails),
                                    imageProvider: context.imageProvider)
                    .accessibilityHidden(true)
                
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(member.name ?? "")
                            .font(.compound.bodyMDSemibold)
                            .foregroundColor(.compound.textPrimary)
                            .lineLimit(1)
                        Text(member.id)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .lineLimit(1)
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
}

struct RoomMembersListMemberCell_Previews: PreviewProvider, TestablePreview {
    static let members: [RoomMemberProxyMock] = [
        .mockAlice,
        .mockBob,
        .mockCharlie,
        .mockModerator
    ]
    static let viewModel = RoomMembersListScreenViewModel(roomProxy: RoomProxyMock(with: .init(displayName: "Some room", members: members)),
                                                          mediaProvider: MockMediaProvider(),
                                                          userIndicatorController: ServiceLocator.shared.userIndicatorController)
    static var previews: some View {
        VStack(spacing: 12) {
            ForEach(members, id: \.userID) { member in
                RoomMembersListScreenMemberCell(member: .init(withProxy: member), context: viewModel.context)
            }
        }
    }
}
