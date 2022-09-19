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
                    sessionVerificationBanner
                }
                
                List {
                    ForEach(context.viewState.visibleRooms) { room in
                        HomeScreenRoomCell(room: room, context: context)
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
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
        .navigationTitle(ElementL10n.homeScreenAllChats)
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
    
    private var sessionVerificationBanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(ElementL10n.sessionVerificationBannerTitle)
                    .font(.element.subheadlineBold)
                    .foregroundColor(.element.systemPrimaryLabel)
                Text(ElementL10n.sessionVerificationBannerMessage)
                    .font(.element.footnote)
                    .foregroundColor(.element.systemSecondaryLabel)
            }
            
            HStack(spacing: 16) {
                Button(ElementL10n.actionSkip) {
                    context.send(viewAction: .skipSessionVerification)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.elementCapsule)
                
                Button(ElementL10n.continue) {
                    context.send(viewAction: .verifySession)
                }
                .frame(maxWidth: .infinity)
                .buttonStyle(.elementCapsuleProminent)
            }
        }
        .padding(16)
        .background(Color.element.systemSecondaryBackground)
        .cornerRadius(14)
        .padding(.horizontal, 16)
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

// MARK: - Previews

struct HomeScreen_Previews: PreviewProvider {
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
        
        return NavigationView {
            HomeScreen(context: viewModel.context)
        }
    }
}
