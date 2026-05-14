//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct InviteUsersConfirmationSheetView: View {
    @ObservedObject var context: InviteUsersScreenViewModel.Context
    
    /// The users whose identities we wish the user to confirm.
    var users: [UserProfileProxy]
    
    var body: some View {
        FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
            VStack(spacing: 32) {
                TitleAndIcon(title: users.count == 1 ? L10n.screenInviteUsersConfirmDialogTitleOneUser : L10n.screenInviteUsersConfirmDialogTitleMutipleUsers,
                             subtitle: users.count == 1 ? L10n.screenInviteUsersConfirmDialogSubtitleOneUser : L10n.screenInviteUsersConfirmDialogSubtitleMultipleUsers,
                             icon: \.userAddSolid,
                             iconStyle: .defaultSolid)
                VStack(spacing: 0) {
                    ForEach(users, id: \.userID) { user in
                        UserProfileListRow(user: user,
                                           membership: nil,
                                           mediaProvider: context.mediaProvider,
                                           kind: .label)
                            .rowDivider(alignment: .top)
                            .accessibilityIdentifier(A11yIdentifiers.inviteUsersScreen.userProfile)
                    }
                }
            }
        } bottomContent: {
            HStack(spacing: 32) {
                Button(L10n.actionRemove, role: .cancel) {
                    context.send(viewAction: .removeUnknownUsers)
                }
                .buttonStyle(.compound(.secondary))
                
                Button(L10n.actionInvite) {
                    context.send(viewAction: .confirmUnknownUsers)
                }
                .buttonStyle(.compound(.primary))
            }
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
    }
}

struct InviteUsersConfirmationSheetView_Previews: PreviewProvider, TestablePreview {
    static var viewModel = makeViewModel()
    
    static var previews: some View {
        InviteUsersConfirmationSheetView(context: viewModel.context, users: [.mockAlice, .mockCharlie, .mockBob, .mockDan])
            .previewDisplayName("Default")
    }
    
    static func makeViewModel() -> InviteUsersScreenViewModel {
        let viewModel = InviteUsersScreenViewModel(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))),
                                                   roomType: .room(roomProxy: JoinedRoomProxyMock(.init(members: []))),
                                                   isSkippable: true,
                                                   userDiscoveryService: UserDiscoveryServiceMock(),
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   appSettings: AppSettings())
        
        viewModel.state.usersToConfirm = [.mockAlice, .mockCharlie, .mockBob, .mockDan]
        
        return viewModel
    }
}
