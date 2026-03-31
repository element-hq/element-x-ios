//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ConfirmInviteUsersSheetView: View {
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
                    context.send(viewAction: .recheck)
                }
                .buttonStyle(.compound(.secondary))
                
                Button(L10n.actionInvite) {
                    context.send(viewAction: .confirm)
                }
                .buttonStyle(.compound(.primary))
            }
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
    }
}
