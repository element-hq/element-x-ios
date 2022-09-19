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
    @ScaledMetric private var avatarSize = 44.0
    
    let room: HomeScreenRoom
    let context: HomeScreenViewModel.Context
    
    var body: some View {
        Button {
            context.send(viewAction: .selectRoom(roomIdentifier: room.id))
        } label: {
            HStack(spacing: 16.0) {
                if let avatar = room.avatar {
                    Image(uiImage: avatar)
                        .resizable()
                        .scaledToFill()
                        .frame(width: avatarSize, height: avatarSize)
                        .clipShape(Circle())
                } else {
                    PlaceholderAvatarImage(text: room.name)
                        .clipShape(Circle())
                        .frame(width: avatarSize, height: avatarSize)
                }
                
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2.0) {
                        Text(room.name)
                            .font(.element.callout.bold())
                            .foregroundColor(.element.primaryContent)
                        
                        if let lastMessage = room.lastMessage {
                            Text(lastMessage)
                                .font(lastMessageFont)
                                .foregroundColor(lastMessageForegroundColor)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                                .padding(.top, 2)
                                .animation(nil, value: UUID()) // Text animations look ugly
                        }
                    }
                    
                    Spacer()
                  
                    VStack(alignment: .trailing, spacing: 3.0) {
                        if let timestamp = room.timestamp {
                            Text(timestamp)
                                .font(.element.caption1)
                                .foregroundColor(.element.secondaryContent)
                        }
                        
                        if room.hasUnreads {
                            Rectangle()
                                .frame(width: 12, height: 12)
                                .foregroundColor(.element.primaryContent)
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .frame(minHeight: 64.0)
            .task {
                context.send(viewAction: .loadRoomData(roomIdentifier: room.id))
            }
        }
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
        body.preferredColorScheme(.light)
            .tint(.element.accent)
        body.preferredColorScheme(.dark)
            .tint(.element.accent)
    }
    
    static var body: some View {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userIdentifier: "John Doe"),
                                          mediaProvider: MockMediaProvider())
        
        let viewModel = HomeScreenViewModel(userSession: userSession,
                                            attributedStringBuilder: AttributedStringBuilder())
        
        return VStack {
            ForEach(viewModel.context.viewState.rooms) { room in
                HomeScreenRoomCell(room: room, context: viewModel.context)
            }
        }
    }
}
