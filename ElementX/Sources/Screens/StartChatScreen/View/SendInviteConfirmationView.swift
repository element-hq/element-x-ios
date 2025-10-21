//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SendInviteConfirmationView: View {
    let userToInvite: UserProfileProxy
    let mediaProvider: MediaProviderProtocol?
    let onInvite: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var sheetHeight: CGFloat = .zero
    private let topPadding: CGFloat = 24
    
    private var subtitle: String {
        let string: String
        if let displayName = userToInvite.displayName {
            string = L10n.commonNameAndId(displayName, userToInvite.userID)
        } else {
            string = userToInvite.userID
        }
        return L10n.screenBottomSheetCreateDmMessage(string)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                header
                actions
            }
            .readHeight($sheetHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, topPadding) // For the drag indicator
        .presentationDetents([.height(sheetHeight + topPadding)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            LoadableAvatarImage(url: userToInvite.avatarURL,
                                name: userToInvite.displayName,
                                contentID: userToInvite.userID,
                                avatarSize: .user(on: .sendInviteConfirmation),
                                mediaProvider: mediaProvider)
            VStack(spacing: 8) {
                Text(L10n.screenBottomSheetCreateDmTitle)
                    .multilineTextAlignment(.center)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                Text(subtitle)
                    .multilineTextAlignment(.center)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
            }
        }
        .padding(.horizontal, 24)
    }
    
    private var actions: some View {
        VStack(spacing: 16) {
            Button {
                dismiss()
                onInvite()
            } label: {
                Label(L10n.screenBottomSheetCreateDmConfirmationButtonTitle,
                      icon: \.userAdd,
                      iconSize: .medium,
                      relativeTo: .compound.bodyLGSemibold)
            }
            .buttonStyle(.compound(.primary))
            
            Button {
                dismiss()
            } label: {
                Text(L10n.actionCancel)
            }
            .buttonStyle(.compound(.tertiary))
        }
        .padding(.horizontal, 16)
    }
}

struct SendInviteConfirmationView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SendInviteConfirmationView(userToInvite: .mockBob,
                                   mediaProvider: nil) { }
    }
}
