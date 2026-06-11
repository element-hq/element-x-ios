//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct OtpEntryScreen: View {
    @Bindable var context: OtpEntryScreenViewModel.Context

    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: "000000"),
                        kind: .textField(text: $context.code))
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .onChange(of: context.code) {
                        context.send(viewAction: .codeChanged)
                    }
            } header: {
                Text(L10n.screenOtpSentTo(context.viewState.phoneNumber))
            } footer: {
                if let errorMessage = context.viewState.errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.compound.textCriticalPrimary)
                } else {
                    Text(L10n.screenOtpFooterEnter)
                }
            }

            Section {
                ListRow(label: .centeredAction(title: context.viewState.isVerifying ? L10n.commonLoading : L10n.actionContinue,
                                               icon: \.arrowRight),
                        kind: .button { context.send(viewAction: .verifyTapped) })
                    .disabled(!context.viewState.canVerify)
            }

            Section {
                if context.viewState.resendCountdownSeconds > 0 {
                    ListRow(label: .centeredAction(title: L10n.screenOtpResendCountdown(context.viewState.resendCountdownSeconds),
                                                   icon: \.restart),
                            kind: .label)
                } else {
                    ListRow(label: .centeredAction(title: L10n.screenOtpResend, icon: \.restart),
                            kind: .button { context.send(viewAction: .resendTapped) })
                        .disabled(!context.viewState.canResend)
                }

                ListRow(label: .centeredAction(title: L10n.screenOtpChangePhone, icon: \.edit),
                        kind: .button { context.send(viewAction: .changePhoneTapped) })
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenOtpVerifyNumberTitle)
    }
}

// MARK: - Previews

struct OtpEntryScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = OtpEntryScreenViewModel(phoneNumber: "+15551234567", initialResendCountdown: 0)
    static let countingViewModel = OtpEntryScreenViewModel(phoneNumber: "+15551234567", initialResendCountdown: 30)

    static var previews: some View {
        NavigationStack {
            OtpEntryScreen(context: viewModel.context)
        }
        .previewDisplayName("Resend ready")

        NavigationStack {
            OtpEntryScreen(context: countingViewModel.context)
        }
        .previewDisplayName("Countdown")
    }
}
