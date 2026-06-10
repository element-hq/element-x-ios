//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct DeactivateAccountScreen: View {
    @Bindable var context: DeactivateAccountScreenViewModel.Context
    
    var body: some View {
        Form {
            infoSection
            eraseDataSection
            if context.viewState.identityServiceAvailable {
                reauthSection
            } else {
                passwordSection
            }
        }
        .compoundList()
        .safeAreaInset(edge: .bottom) {
            Button(L10n.actionDeactivateAccount, role: .destructive) {
                context.send(viewAction: .deactivate)
            }
            .buttonStyle(.compound(.primary))
            .disabled(!canSubmit)
            .padding(16)
            .background(Color.compound.bgSubtleSecondaryLevel0.ignoresSafeArea())
        }
        .navigationTitle(L10n.screenDeactivateAccountTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    private var canSubmit: Bool {
        if context.viewState.identityServiceAvailable {
            if case .verified = context.viewState.reauthPhase { return true }
            return false
        }
        return !context.password.isEmpty
    }
    
    private var infoSection: some View {
        ListRow(kind: .custom {
            VStack(alignment: .leading, spacing: 16) {
                Text(context.viewState.info)
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoItem(title: context.viewState.infoPoint1)
                    InfoItem(title: context.viewState.infoPoint2)
                    InfoItem(title: context.viewState.infoPoint3)
                    InfoItem(title: context.viewState.infoPoint4, isSuccess: true)
                }
            }
            .foregroundColor(.compound.textSecondary)
            .font(.compound.bodyMD)
            .listRowBackground(Color.clear)
        })
    }
    
    private var eraseDataSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenDeactivateAccountDeleteAllMessages),
                    kind: .toggle($context.eraseData))
        } footer: {
            Text(L10n.screenDeactivateAccountDeleteAllMessagesNotice)
                .compoundListSectionFooter()
        }
    }
    
    private var passwordSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.commonPassword),
                    kind: .secureField(text: $context.password))
                .submitLabel(.done)
        } header: {
            Text(L10n.actionConfirmPassword)
                .compoundListSectionHeader()
        }
    }
    
    @ViewBuilder
    private var reauthSection: some View {
        Section {
            switch context.viewState.reauthPhase {
            case .idle, .error:
                ListRow(label: .action(title: L10n.screenAccountReauthSendCode,
                                       icon: \.lockSolid),
                        kind: .button {
                            context.send(viewAction: .sendReauthCode)
                        })
                if case let .error(message) = context.viewState.reauthPhase {
                    ListRow(kind: .custom {
                        Text(message)
                            .foregroundStyle(.compound.textCriticalPrimary)
                            .font(.compound.bodySM)
                    })
                }
            case .sendingCode:
                ListRow(kind: .custom {
                    HStack {
                        ProgressView()
                        Text(L10n.commonPleaseWait).foregroundStyle(.compound.textSecondary)
                    }
                })
            case .awaitingCode, .verifyingCode:
                ListRow(label: .plain(title: L10n.screenAccountReauthCodeLabel),
                        kind: .textField(text: $context.otpCode))
                    .submitLabel(.done)
                ListRow(label: .action(title: L10n.actionConfirm, icon: \.checkCircleSolid),
                        kind: .button {
                            context.send(viewAction: .verifyReauthCode)
                        })
                if case .verifyingCode = context.viewState.reauthPhase {
                    ListRow(kind: .custom {
                        ProgressView()
                    })
                }
            case .verified:
                ListRow(kind: .custom {
                    HStack {
                        CompoundIcon(\.checkCircleSolid).foregroundStyle(.compound.iconSuccessPrimary)
                        Text(L10n.screenAccountReauthVerified).foregroundStyle(.compound.textSuccessPrimary)
                    }
                })
            }
        } header: {
            Text(L10n.screenAccountReauthSectionTitle)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenAccountReauthSectionFooter)
                .compoundListSectionFooter()
        }
    }
}

private struct InfoItem: View {
    let title: AttributedString
    var isSuccess = false
    
    var body: some View {
        Label {
            Text(title).padding(.vertical, 1)
        } icon: {
            CompoundIcon(isSuccess ? \.check : \.close,
                         size: .small,
                         relativeTo: .compound.bodyMD)
                .foregroundStyle(isSuccess ? .compound.iconSuccessPrimary : .compound.iconCriticalPrimary)
        }
        .labelStyle(.custom(spacing: 8, alignment: .top))
    }
}

// MARK: - Previews

struct DeactivateAccountScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = DeactivateAccountScreenViewModel(clientProxy: ClientProxyMock(.init()),
                                                            userIndicatorController: UserIndicatorControllerMock())
    static var previews: some View {
        NavigationStack {
            DeactivateAccountScreen(context: viewModel.context)
        }
    }
}
