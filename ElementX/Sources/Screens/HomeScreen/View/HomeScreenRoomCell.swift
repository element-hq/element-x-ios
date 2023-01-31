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

struct HomeScreenRoomCell: View {
    let room: HomeScreenRoom
    let context: HomeScreenViewModel.Context
    
    var body: some View {
        Button {
            if let roomId = room.roomId {
                context.send(viewAction: .selectRoom(roomIdentifier: roomId))
            }
        } label: {
            HStack(spacing: 16.0) {
                avatar
                
                VStack(alignment: .leading, spacing: 2) {
                    header
                    footer
                }
            }
            .frame(minHeight: 84.0)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(HomeScreenRoomCellButtonStyle())
        .accessibilityIdentifier("roomName:\(room.name)")
        .overlay(alignment: .bottom) {
            Divider()
                .frame(height: 0.5)
                .background(Color.element.quinaryContent)
                .padding(.leading, 84)
        }
    }
    
    @ViewBuilder
    var avatar: some View {
        LoadableAvatarImage(url: room.avatarURL,
                            name: room.name,
                            contentID: room.roomId,
                            avatarSize: .room(on: .home),
                            imageProvider: context.imageProvider)
            .accessibilityHidden(true)
    }
    
    @ViewBuilder
    var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(room.name)
                .font(.element.headline)
                .foregroundColor(.element.primaryContent)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let timestamp = room.timestamp {
                Text(timestamp)
                    .font(.element.footnote)
                    .foregroundColor(room.hasUnreads ? .element.brand : .element.tertiaryContent)
            }
        }
    }
    
    @ViewBuilder
    var footer: some View {
        HStack(alignment: .firstTextBaseline) {
            ZStack(alignment: .topLeading) {
                // Hidden text with 2 lines to maintain consistent height, scaling with dynamic text.
                Text(" \n ").lastMessageFormatting().hidden()
                
                if let lastMessage = room.lastMessage, !String(lastMessage.characters).isEmpty {
                    Text(lastMessage)
                        .lastMessageFormatting()
                } else {
                    Text(ElementL10n.newMessage)
                        .lastMessageFormatting()
                }
            }
            
            Spacer()
            
            if room.hasUnreads {
                Rectangle()
                    .frame(width: 12, height: 12)
                    .foregroundColor(.element.brand)
                    .clipShape(Circle())
                    .padding(.leading, 12)
            } else {
                // Force extra padding between last message text and the right border of the screen if there is no unread dot
                Rectangle()
                    .fill(Color.clear)
                    .frame(width: 12, height: 12)
            }
        }
    }
}

struct HomeScreenRoomCellButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .roomCellBackground(configuration.isPressed ? .element.system : .clear)
            .contentShape(Rectangle())
    }
}

private extension View {
    func lastMessageFormatting() -> some View {
        font(.element.subheadline)
            .foregroundColor(.element.tertiaryContent)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
    
    // To be used to indicate the selected room too
    func roomCellBackground(_ background: Color) -> some View {
        padding(.horizontal, 8)
            .padding(.horizontal, 8)
            .background { background }
    }
}

struct HomeScreenRoomCell_Previews: PreviewProvider {
    static var previews: some View {
        body.tint(.element.accent)
    }

    static var body: some View {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded)

        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "John Doe", roomSummaryProvider: summaryProvider),
                                          mediaProvider: MockMediaProvider())

        let viewModel = HomeScreenViewModel(userSession: userSession,
                                            attributedStringBuilder: AttributedStringBuilder())
        
        let rooms: [HomeScreenRoom] = summaryProvider.roomListPublisher.value.compactMap { summary -> HomeScreenRoom? in
            switch summary {
            case .empty:
                return nil
            case .filled(let details), .invalidated(let details):
                return HomeScreenRoom(id: UUID().uuidString,
                                      roomId: details.id,
                                      name: details.name,
                                      hasUnreads: details.unreadNotificationCount > 0,
                                      timestamp: Date.now.formattedMinimal(),
                                      lastMessage: details.lastMessage)
            }
        }

        return VStack(spacing: 0) {
            ForEach(rooms) { room in
                HomeScreenRoomCell(room: room, context: viewModel.context)
            }
        }
    }
}
