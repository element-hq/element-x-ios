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

import Combine
import SwiftUI

struct NotificationSettingsEditScreenRoomCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: NotificationSettingsEditScreenRoom
    let context: NotificationSettingsEditScreenViewModel.Context
    
    private let verticalInsets = 4.0
    
    var body: some View {
        Button {
            if let roomId = room.roomId {
                context.send(viewAction: .selectRoom(roomIdentifier: roomId))
            }
        } label: {
            LabeledContent {
                if let notificationMode = room.notificationMode {
                    Text(context.viewState.strings.string(for: notificationMode))
                        .fixedSize()
                }
            } label: {
                HStack(spacing: 16.0) {
                    avatar
                    content
                }
            }
            .padding(.vertical, verticalInsets)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(.compoundForm(accessory: .navigationLink))
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
    
    var content: some View {
        Text(room.name)
            .font(.compound.bodyLG)
            .foregroundColor(.compound.textPrimary)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct NotificationSettingsEditScreenRoomCellButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isSelected ? Color.compound.bgSubtleSecondary : Color.compound.bgCanvasDefault)
            .contentShape(Rectangle())
            .animation(.elementDefault, value: isSelected)
    }
}

struct NotificationSettingsEditScreenRoomCell_Previews: PreviewProvider {
    static var previews: some View {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockRooms))

        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "John Doe", roomSummaryProvider: summaryProvider),
                                          mediaProvider: MockMediaProvider())

        let notificationSettingsProxy = NotificationSettingsProxyMock(with: .init())
        let viewModel = NotificationSettingsEditScreenViewModel(isDirect: false,
                                                                userSession: userSession,
                                                                notificationSettingsProxy: notificationSettingsProxy)
        
        let rooms: [NotificationSettingsEditScreenRoom] = summaryProvider.roomListPublisher.value.compactMap { summary -> NotificationSettingsEditScreenRoom? in
            switch summary {
            case .empty:
                return nil
            case .invalidated(let details), .filled(let details):
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
