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

struct InvitesListScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var counterColor: Color {
        colorScheme == .light ? .element.secondaryContent : .element.tertiaryContent
    }
    
    @ObservedObject var context: InvitesListViewModel.Context
    
    var body: some View {
        ScrollView {
            if let rooms = context.viewState.invites, !rooms.isEmpty {
                LazyVStack {
                    ForEach(rooms, id: \.roomDetails.id) { invite in
                        InviteCell(invite: invite, imageProvider: context.imageProvider)
                    }
                }
            } else {
                noInvitesContent
            }
        }
        .navigationTitle(L10n.actionInvitesList)
    }
    
    // MARK: - Private
    
    private var noInvitesContent: some View {
        Text(L10n.commonNoResults)
            .font(.element.body)
            .foregroundColor(.element.tertiaryContent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
            .padding(.top, 80)
    }
}

// MARK: - Previews

struct InvitesListScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InvitesListScreen(context: InvitesListViewModel.noInvites.context)
        }
        .previewDisplayName("No Invites")
        
        NavigationView {
            InvitesListScreen(context: InvitesListViewModel.someInvite.context)
        }
        .previewDisplayName("Some Invite")
    }
}

private extension InvitesListViewModel {
    static let noInvites: InvitesListViewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let regularViewModel = InvitesListViewModel(userSession: userSession)
        return regularViewModel
    }()
    
    static let someInvite: InvitesListViewModel = {
        let clientProxy = MockClientProxy(userID: "@userid:example.com")
        clientProxy.invitesSummaryProvider = MockRoomSummaryProvider(state: .loaded(.invites))
        clientProxy.visibleRoomsSummaryProvider = MockRoomSummaryProvider(state: .loaded(.invites))
        let userSession = MockUserSession(clientProxy: clientProxy,
                                          mediaProvider: MockMediaProvider())
        let regularViewModel = InvitesListViewModel(userSession: userSession)
        return regularViewModel
    }()
}
