//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct PinSetupScreen: View {
    @Bindable var context: PinSetupScreenViewModel.Context

    var body: some View {
        Form {
            Section {
                PinBubbleField(pin: $context.pin,
                               length: PinSetupScreenViewState.pinLength,
                               hasError: context.viewState.errorMessage != nil)
                    .onChange(of: context.pin) {
                        context.send(viewAction: .pinChanged)
                    }
                    .id(context.viewState.step) // reset field identity between create/confirm
            } header: {
                Text(context.viewState.titleKey)
            } footer: {
                if let errorMessage = context.viewState.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.compound.textCriticalPrimary)
                } else {
                    Text(context.viewState.footerKey)
                }
            }

            Section {
                ListRow(label: .centeredAction(title: context.viewState.isSubmitting ? L10n.commonLoading : L10n.actionContinue,
                                               icon: \.arrowRight),
                        kind: .button { context.send(viewAction: .continueTapped) })
                    .disabled(!context.viewState.canContinue)
            }

            if context.viewState.step == .create, !context.viewState.isSubmitting {
                Section {
                    ListRow(label: .centeredAction(title: L10n.screenPinSetupSkip, icon: \.close),
                            kind: .button { context.send(viewAction: .skipTapped) })
                } footer: {
                    Text(L10n.screenPinSetupSkipFooter)
                }
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenPinSetupTitle)
    }
}

// MARK: - Previews

struct PinSetupScreen_Previews: PreviewProvider, TestablePreview {
    static let createViewModel = PinSetupScreenViewModel()

    static var previews: some View {
        NavigationStack {
            PinSetupScreen(context: createViewModel.context)
        }
        .previewDisplayName("Create")
    }
}
