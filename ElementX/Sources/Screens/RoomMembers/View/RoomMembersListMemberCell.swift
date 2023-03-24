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

struct RoomMembersListMemberCell: View {
    @ScaledMetric private var avatarSize = AvatarSize.user(on: .roomDetails).value

    let member: RoomDetailsMember
    let context: RoomMembersListViewModel.Context

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
                    .font(.element.calloutBold)
                    .foregroundColor(.element.primaryContent)
                    .lineLimit(1)

                Spacer()
            }
            .accessibilityElement(children: .combine)
        }
    }
}

struct RoomMembersListMemberCell_Previews: PreviewProvider {
    static var previews: some View {
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        let viewModel = RoomMembersListViewModel(mediaProvider: MockMediaProvider(),
                                                 members: members)
        
        return VStack {
            ForEach(members, id: \.userID) { member in
                RoomMembersListMemberCell(member: .init(withProxy: member), context: viewModel.context)
            }
        }
    }
}
