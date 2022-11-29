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

struct RoomMembersMemberCell: View {
    @ScaledMetric private var avatarSize = AvatarSize.user(on: .roomDetails).value

    let member: RoomDetailsMember
    let context: RoomMembersViewModel.Context

    var body: some View {
        Button {
            context.send(viewAction: .selectMember(id: member.id))
        } label: {
            HStack {
                if let avatar = member.avatar {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                } else {
                    PlaceholderAvatarImage(text: member.name ?? "", contentId: member.id)
                        .clipShape(Circle())
                        .frame(width: avatarSize, height: avatarSize)
                        .accessibilityHidden(true)
                }

                Text(member.name ?? "")
                    .font(.element.callout.bold())
                    .foregroundColor(.element.primaryContent)
                    .lineLimit(1)

                Spacer()
            }
            .accessibilityElement(children: .combine)
            .task {
                context.send(viewAction: .loadMemberData(id: member.id))
            }
        }
    }
}

struct RoomDetailsMemberCell_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
            .tint(.element.accent)
        body.preferredColorScheme(.dark)
            .tint(.element.accent)
    }

    static var body: some View {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded)

        let userSession = MockUserSession(clientProxy: MockClientProxy(userIdentifier: "John Doe", roomSummaryProvider: summaryProvider),
                                          mediaProvider: MockMediaProvider())

        let viewModel = HomeScreenViewModel(userSession: userSession,
                                            attributedStringBuilder: AttributedStringBuilder())

        let rooms: [HomeScreenRoom] = summaryProvider.roomListPublisher.value.compactMap { summary in
            guard let summary = summary.asFilled else {
                return nil
            }

            return HomeScreenRoom(id: summary.id,
                                  name: summary.name,
                                  hasUnreads: summary.unreadNotificationCount > 0,
                                  timestamp: Date.now.formatted(date: .omitted, time: .shortened))
        }

        return VStack {
            ForEach(rooms) { room in
                HomeScreenRoomCell(room: room, context: viewModel.context)
            }
        }
    }
}
