// 
// Copyright 2021 New Vector Ltd
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

struct HomeScreen: View {
    
    @ObservedObject var context: HomeScreenViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        VStack(spacing: 0.0) {
            if context.viewState.isLoadingRooms {
                VStack {
                    Text(ElementL10n.loading)
                    ProgressView()
                }
            } else {
                
                if context.viewState.showSessionVerificationBanner {
                    HStack {
                        Text(ElementL10n.verificationVerifyDevice)
                        Spacer()
                        Button(ElementL10n.startVerification) {
                            context.send(viewAction: .verifySession)
                        }
                    }
                    .padding()
                    .background(Color.element.quaternaryContent)
                    .padding(.top, 1)
                }
                
                List {
                    Section(ElementL10n.rooms) {
                        ForEach(context.viewState.visibleRooms) { room in
                            RoomCell(room: room, context: context)
                                .listRowBackground(Color.clear)
                        }
                    }
                    
                    Section(ElementL10n.bottomActionPeople) {
                        ForEach(context.viewState.visibleDMs) { room in
                            RoomCell(room: room, context: context)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $context.searchQuery)
            }
            
            Spacer()
        }
        .background(Color.element.background)
        .transition(.slide)
        .animation(.default, value: context.viewState.showSessionVerificationBanner)
        .ignoresSafeArea(.all, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { context.send(viewAction: .tapUserAvatar) } label: {
                    HStack {
                        userAvatarImage
                            .animation(.default, value: context.viewState.userAvatar)
                            .transition(.opacity)

                        userDisplayNameView
                            .animation(.default, value: context.viewState.userDisplayName)
                            .transition(.opacity)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var userAvatarImage: some View {
        if let avatar = context.viewState.userAvatar {
            Image(uiImage: avatar)
                .resizable()
                .scaledToFill()
                .frame(width: 32, height: 32, alignment: .center)
                .clipShape(Circle())
                .accessibilityIdentifier("userAvatarImage")
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private var userDisplayNameView: some View {
        if let displayName = context.viewState.userDisplayName {
            Text(displayName)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)
        } else {
            EmptyView()
        }
    }
}

struct RoomCell: View {
    
    @ScaledMetric private var avatarSize = 32.0
    
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
                    PlaceholderAvatarImage(text: room.displayName ?? room.id)
                        .clipShape(Circle())
                        .frame(width: avatarSize, height: avatarSize)
                }
                
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(roomName(room))
                        .foregroundStyle(.primary)
                    
                    if let roomTopic = room.topic, roomTopic.count > 0 {
                        Text(roomTopic)
                            .font(.footnote.weight(.semibold))
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let lastMessage = room.lastMessage {
                        Text(lastMessage)
                            .font(.callout)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                            .padding(.top, 2)
                    }
                }
            }
            .animation(.default, value: room)
            .frame(minHeight: 60.0)
            .task {
                context.send(viewAction: .loadRoomData(roomIdentifier: room.id))
            }
        }
    }
    
    private func roomName(_ room: HomeScreenRoom) -> String {
        room.displayName ?? room.id + (room.isEncrypted ? "🛡": "")
    }
}

// MARK: - Previews

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    static var body: some View {
        let viewModel = HomeScreenViewModel(attributedStringBuilder: AttributedStringBuilder())
        
        let eventBrief = EventBrief(eventId: "id",
                                    senderId: "senderId",
                                    senderDisplayName: "Sender",
                                    body: "Some message",
                                    htmlBody: nil,
                                    date: .now)
        
        let roomSummaries = [MockRoomSummary(displayName: "Alpha", topic: "Topic"),
                             MockRoomSummary(displayName: "Beta"),
                             MockRoomSummary(displayName: "Omega", lastMessage: eventBrief)]
        
        viewModel.updateWithRoomSummaries(roomSummaries)
        viewModel.updateWithUserDisplayName("username")
        
        if let avatarImage = UIImage(systemName: "person.fill") {
            viewModel.updateWithUserAvatar(avatarImage)
        }
        
        viewModel.showSessionVerificationBanner()
        
        return NavigationView {
            HomeScreen(context: viewModel.context)
        }
    }
}
