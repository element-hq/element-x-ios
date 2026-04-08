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
    
    var body: some View {
        FullscreenDialog(topPadding: 24, horizontalPadding: 24) {
            TitleAndIcon(title: UntranslatedL10n.cryptoHistorySharingConfirmInviteDialogTitle,
                         subtitle: UntranslatedL10n.cryptoHistorySharingConfirmInviteDialogContent,
                         icon: \.userAddSolid,
                         iconStyle: .default)
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(context.viewState.usersToConfirm, id: \.userID) { user in
                        Divider()
                        UserProfileListRow(user: user,
                                           membership: nil,
                                           mediaProvider: context.mediaProvider,
                                           kind: .label)
                            .accessibilityIdentifier(A11yIdentifiers.inviteUsersScreen.userProfile)
                    }
                }
            }
        } bottomContent: {
            HStack(spacing: 16) {
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
        InviteUsersConfirmationSheetView(context: viewModel.context)
            .previewDisplayName("Default")
    }
    
    static func makeViewModel() -> InviteUsersScreenViewModel {
        let viewModel = InviteUsersScreenViewModel(userSession: UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))),
                                                   roomProxy: JoinedRoomProxyMock(.init(members: [])),
                                                   isSkippable: true,
                                                   userDiscoveryService: UserDiscoveryServiceMock(),
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   appSettings: ServiceLocator.shared.settings)
        
        viewModel.state.usersToConfirm = [.mockAlice, .mockCharlie, .mockBob, .mockDan]
        
        return viewModel
    }
}
