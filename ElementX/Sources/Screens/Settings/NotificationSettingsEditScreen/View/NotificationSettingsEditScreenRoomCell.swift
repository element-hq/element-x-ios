//
// Copyright 2023 New Vector Ltd
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

struct NotificationSettingsEditScreenRoomCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: NotificationSettingsEditScreenRoom
    let context: NotificationSettingsEditScreenViewModel.Context
    
    var body: some View {
        ListRow(label: .action(title: room.name,
                               icon: avatar),
                details: roomDetailsLabel,
                kind: .navigationLink {
                    if let roomId = room.roomId {
                        context.send(viewAction: .selectRoom(roomIdentifier: roomId))
                    }
                })
                .lineLimit(1)
                .accessibilityIdentifier(A11yIdentifiers.notificationSettingsEditScreen.roomName(room.name))
    }
    
    @ViewBuilder @MainActor
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .notificationSettings),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
    
    @MainActor
    var roomDetailsLabel: ListRowDetails<EmptyView>? {
        guard let mode = room.notificationMode else { return nil }
        return .label(title: context.viewState.strings.string(for: mode),
                      icon: EmptyView())
    }
}

struct NotificationSettingsEditScreenRoomCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))

        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "John Doe", roomSummaryProvider: summaryProvider))))

        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getRoomsWithUserDefinedRulesReturnValue = []
        let viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat,
                                                                userSession: userSession,
                                                                notificationSettingsProxy: notificationSettingsProxy)
        
        let rooms: [NotificationSettingsEditScreenRoom] = summaryProvider.roomListPublisher.value.compactMap { summary -> NotificationSettingsEditScreenRoom? in
            NotificationSettingsEditScreenRoom(id: UUID().uuidString,
                                               roomId: summary.id,
                                               name: summary.name,
                                               avatar: summary.avatar)
        }
        
        return VStack(spacing: 0) {
            ForEach(rooms) { room in
                NotificationSettingsEditScreenRoomCell(room: room, context: viewModel.context)
            }
        }
    }
}
