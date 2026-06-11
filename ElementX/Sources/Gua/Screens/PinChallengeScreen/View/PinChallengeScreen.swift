//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct PinChallengeScreen: View {
    @Bindable var context: PinChallengeScreenViewModel.Context

    var body: some View {
        Form {
            Section {
                PinBubbleField(pin: $context.pin,
                               length: PinChallengeScreenViewState.pinLength,
                               hasError: context.viewState.errorMessage != nil)
                    .onChange(of: context.pin) {
                        context.send(viewAction: .pinChanged)
                    }
            } header: {
                Text(L10n.screenPinChallengeHeader)
            } footer: {
                if let errorMessage = context.viewState.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.compound.textCriticalPrimary)
                } else {
                    Text(L10n.screenPinChallengeFooter(context.viewState.phoneNumber))
                }
            }

            Section {
                ListRow(label: .centeredAction(title: context.viewState.isVerifying ? L10n.commonLoading : L10n.actionContinue,
                                               icon: \.arrowRight),
                        kind: .button { context.send(viewAction: .verifyTapped) })
                    .disabled(!context.viewState.canVerify)
            }

            Section {
                ListRow(label: .centeredAction(title: L10n.screenPinChallengeForgot, icon: \.info),
                        kind: .button { context.send(viewAction: .forgotPinTapped) })
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenPinChallengeTitle)
        .interactiveDismissDisabled()
    }
}

// MARK: - Previews

struct PinChallengeScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = PinChallengeScreenViewModel(phoneNumber: "+15551234567")

    static var previews: some View {
        NavigationStack {
            PinChallengeScreen(context: viewModel.context)
        }
        .previewDisplayName("Default")
    }
}
