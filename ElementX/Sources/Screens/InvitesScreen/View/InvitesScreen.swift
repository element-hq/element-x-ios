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

struct InvitesScreen: View {
    @ObservedObject var context: InvitesScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            if let rooms = context.viewState.invites, !rooms.isEmpty {
                LazyVStack(spacing: 0) {
                    ForEach(rooms, id: \.roomDetails.id) { invite in
                        InvitesScreenCell(invite: invite,
                                          imageProvider: context.imageProvider,
                                          acceptAction: { context.send(viewAction: .accept(invite)) },
                                          declineAction: { context.send(viewAction: .decline(invite)) })
                    }
                }
            } else {
                noInvitesContent
            }
        }
        .background(Color.element.background.ignoresSafeArea())
        .navigationTitle(L10n.actionInvitesList)
        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    // MARK: - Private
    
    private var noInvitesContent: some View {
        Text(L10n.screenInvitesEmptyList)
            .font(.compound.bodyLG)
            .foregroundColor(.element.tertiaryContent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.invitesScreen.noInvites)
            .padding(.top, 80)
    }
}

// MARK: - Previews

struct InvitesScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            InvitesScreen(context: InvitesScreenViewModel.noInvites.context)
        }
        .previewDisplayName("No Invites")
        
        NavigationView {
            InvitesScreen(context: InvitesScreenViewModel.someInvite.context)
        }
        .previewDisplayName("Some Invite")
    }
}

private extension InvitesScreenViewModel {
    static let noInvites: InvitesScreenViewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let regularViewModel = InvitesScreenViewModel(userSession: userSession)
        return regularViewModel
    }()
    
    static let someInvite: InvitesScreenViewModel = {
        let clientProxy = MockClientProxy(userID: "@userid:example.com")
        clientProxy.invitesSummaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
        clientProxy.visibleRoomsSummaryProvider = MockRoomSummaryProvider(state: .loaded(.mockInvites))
        let userSession = MockUserSession(clientProxy: clientProxy,
                                          mediaProvider: MockMediaProvider())
        let regularViewModel = InvitesScreenViewModel(userSession: userSession)
        return regularViewModel
    }()
}
