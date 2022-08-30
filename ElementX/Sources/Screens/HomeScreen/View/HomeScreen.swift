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
                    ForEach(context.viewState.visibleRooms) { room in
                        RoomCell(room: room, context: context)
                            .listRowBackground(Color.clear)
                    }
                }
                .listStyle(.plain)
                .animation(.default, value: context.viewState.visibleRooms)
                .searchable(text: $context.searchQuery)
            }
            
            Spacer()
        }
        .transition(.slide)
        .animation(.elementDefault, value: context.viewState.showSessionVerificationBanner)
        .ignoresSafeArea(.all, edges: .bottom)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                userMenuButton
            }
        }
    }

    @ViewBuilder
    private var userMenuButton: some View {
        Menu {
            Section {
                Button(action: settings) {
                    Label(ElementL10n.settingsUserSettings, systemImage: "gearshape")
                }
            }
            Section {
                Button(action: inviteFriends) {
                    Label(ElementL10n.inviteFriends, systemImage: "square.and.arrow.up")
                }
                Button(action: feedback) {
                    Label(ElementL10n.feedback, systemImage: "questionmark.circle")
                }
            }
            Section {
                Button(role: .destructive, action: signOut) {
                    Label(ElementL10n.actionSignOut, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            userAvatarImageView
                .animation(.elementDefault, value: context.viewState.userAvatar)
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var userAvatarImageView: some View {
        userAvatarImage
            .resizable()
            .scaledToFill()
            .frame(width: 32, height: 32, alignment: .center)
            .clipShape(Circle())
            .accessibilityIdentifier("userAvatarImage")
    }

    private var userAvatarImage: Image {
        if let avatar = context.viewState.userAvatar {
            return Image(uiImage: avatar)
        } else {
            return .empty
        }
    }

    private func settings() {
        context.send(viewAction: .userMenu(action: .settings))
    }

    private func inviteFriends() {
        context.send(viewAction: .userMenu(action: .inviteFriends))
    }

    private func feedback() {
        context.send(viewAction: .userMenu(action: .feedback))
    }

    private func signOut() {
        context.send(viewAction: .userMenu(action: .signOut))
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
                    PlaceholderAvatarImage(text: room.name)
                        .clipShape(Circle())
                        .frame(width: avatarSize, height: avatarSize)
                }
                
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(room.name)
                        .font(.element.callout)
                        .foregroundColor(.element.primaryContent)
                    
                    if let lastMessage = room.lastMessage {
                        Text(lastMessage)
                            .font(.element.subheadline)
                            .foregroundColor(.element.secondaryContent)
                            .lineLimit(2)
                            .padding(.top, 2)
                            .animation(nil, value: UUID()) // Text animations look ugly
                    }
                }
                
                Spacer()
            }
            .frame(minHeight: 60.0)
            .overlay(Badge(count: room.unreadNotificationCount))
            .task {
                context.send(viewAction: .loadRoomData(roomIdentifier: room.id))
            }
        }
    }
}

struct Badge: View {
    let count: UInt

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.clear
            Text(String(count))
                .font(.element.footnote)
                .padding(6)
                .foregroundColor(.element.primaryContent)
                .background(Color.element.quaternaryContent)
                .clipShape(Circle())
                // custom positioning in the top-right corner
                .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.25 }
        }
        .opacity(count == 0 ? 0.0 : 1.0)
    }
}

// MARK: - Previews

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
            .tint(.element.accent)
        body.preferredColorScheme(.dark)
            .tint(.element.accent)
    }
    
    static var body: some View {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userIdentifier: "John Doe"), mediaProvider: MockMediaProvider())
        let viewModel = HomeScreenViewModel(userSession: userSession, attributedStringBuilder: AttributedStringBuilder())
        
        return NavigationView {
            HomeScreen(context: viewModel.context)
        }
    }
}
