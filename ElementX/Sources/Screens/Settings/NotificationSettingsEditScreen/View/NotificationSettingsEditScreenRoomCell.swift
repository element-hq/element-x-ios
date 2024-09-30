//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
