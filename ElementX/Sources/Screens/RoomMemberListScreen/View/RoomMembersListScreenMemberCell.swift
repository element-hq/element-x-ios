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
            HStack {
                LoadableAvatarImage(url: member.avatarURL,
                                    name: member.name ?? "",
                                    contentID: member.id,
                                    avatarSize: .user(on: .roomDetails),
                                    imageProvider: context.imageProvider)
                    .accessibilityHidden(true)

                Text(member.name ?? "")
                    .font(.compound.bodyMDSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)

                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }
}

struct RoomMembersListMemberCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        let viewModel = RoomMembersListScreenViewModel(roomProxy: RoomProxyMock(with: .init(displayName: "Some room", members: members)),
                                                       mediaProvider: MockMediaProvider(),
                                                       userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        return VStack {
            ForEach(members, id: \.userID) { member in
                RoomMembersListScreenMemberCell(member: .init(withProxy: member), context: viewModel.context)
            }
        }
    }
}
