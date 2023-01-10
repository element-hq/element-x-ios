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
    @ScaledMetric private var avatarSize = AvatarSize.room(on: .home).value
    
    let room: HomeScreenRoom
    let context: HomeScreenViewModel.Context
    
    var body: some View {
        Button {
            if let roomId = room.roomId {
                context.send(viewAction: .selectRoom(roomIdentifier: roomId))
            }
        } label: {
            HStack(spacing: 16.0) {
                if let avatar = room.avatar {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                        .accessibilityHidden(true)
                } else {
                    PlaceholderAvatarImage(text: room.name, contentId: room.roomId)
                        .clipShape(Circle())
                        .frame(width: avatarSize, height: avatarSize)
                        .accessibilityHidden(true)
                }
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(room.name)
                            .font(.element.callout.bold())
                            .foregroundColor(.element.primaryContent)
                            .lineLimit(1)
                        
                        if let lastMessage = room.lastMessage, !String(lastMessage.characters).isEmpty {
                            Text(lastMessage)
                                .font(lastMessageFont)
                                .foregroundColor(lastMessageForegroundColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 2)
                                .id(UUID())
                                .transition(.opacity.animation(.elementDefault))
                        }
                    }
                    .animation(.elementDefault, value: room)
                    
                    Spacer()
                  
                    VStack(alignment: .trailing, spacing: 3.0) {
                        if let timestamp = room.timestamp {
                            Text(timestamp)
                                .font(.element.caption1)
                                .foregroundColor(.element.secondaryContent)
                                .id(UUID())
                                .transition(.opacity.animation(.elementDefault))
                        }
                        
                        if room.hasUnreads {
                            Rectangle()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.element.primaryContent)
                                .clipShape(Circle())
                                .transition(.opacity.animation(.elementDefault))
                        }
                    }
                    .animation(.elementDefault, value: room)
                }
            }
            .frame(minHeight: 64.0)
            .accessibilityElement(children: .combine)
            .task {
                if let roomId = room.roomId {
                    context.send(viewAction: .loadRoomData(roomIdentifier: roomId))
                }
            }
        }
        .accessibilityIdentifier("roomName:\(room.name)")
    }
    
    var lastMessageFont: Font {
        if room.hasUnreads {
            return .element.subheadline.bold()
        } else {
            return .element.subheadline
        }
    }
    
    var lastMessageForegroundColor: Color {
        if room.hasUnreads {
            return .element.primaryContent
        } else {
            return .element.secondaryContent
        }
    }
}

struct HomeScreenRoomCell_Previews: PreviewProvider {
    static var previews: some View {
        body.tint(.element.accent)
    }

    static var body: some View {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded)

        let userSession = MockUserSession(clientProxy: MockClientProxy(userIdentifier: "John Doe", roomSummaryProvider: summaryProvider),
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
                                      timestamp: Date.now.formatted(date: .omitted, time: .shortened))
            }
        }

        return VStack {
            ForEach(rooms) { room in
                HomeScreenRoomCell(room: room, context: viewModel.context)
            }
        }
    }
}
