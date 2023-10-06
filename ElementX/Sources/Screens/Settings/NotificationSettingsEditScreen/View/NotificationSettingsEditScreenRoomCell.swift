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
            LoadableAvatarImage(url: room.avatarURL,
                                name: room.name,
                                contentID: room.roomId,
                                avatarSize: .room(on: .notificationSettings),
                                imageProvider: context.imageProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
    
    @MainActor
    var roomDetailsLabel: ListDetailsLabel<EmptyView>? {
        guard let mode = room.notificationMode else { return nil }
        return .label(title: context.viewState.strings.string(for: mode),
                      icon: EmptyView())
    }
}

struct NotificationSettingsEditScreenRoomCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockRooms))

        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "John Doe", roomSummaryProvider: summaryProvider),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())

        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        notificationSettingsProxy.getRoomsWithUserDefinedRulesReturnValue = []
        let viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat,
                                                                userSession: userSession,
                                                                notificationSettingsProxy: notificationSettingsProxy)
        
        let rooms: [NotificationSettingsEditScreenRoom] = summaryProvider.roomListPublisher.value.compactMap { summary -> NotificationSettingsEditScreenRoom? in
            switch summary {
            case .empty, .invalidated:
                return nil
            case .filled(let details):
                return NotificationSettingsEditScreenRoom(id: UUID().uuidString,
                                                          roomId: details.id,
                                                          name: details.name)
            }
        }

        return VStack(spacing: 0) {
            ForEach(rooms) { room in
                NotificationSettingsEditScreenRoomCell(room: room, context: viewModel.context)
            }
        }
    }
}
