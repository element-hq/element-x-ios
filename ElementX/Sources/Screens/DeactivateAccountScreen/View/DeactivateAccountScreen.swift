//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct DeactivateAccountScreen: View {
    @ObservedObject var context: DeactivateAccountScreenViewModel.Context
    
    var body: some View {
        Form {
            infoSection
            eraseDataSection
            passwordSection
        }
        .compoundList()
        .safeAreaInset(edge: .bottom) {
            Button(L10n.actionDeactivateAccount, role: .destructive) {
                context.send(viewAction: .deactivate)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.password.isEmpty)
            .padding(16)
            .background(Color.compound.bgSubtleSecondaryLevel0.ignoresSafeArea())
        }
        .navigationTitle(L10n.screenDeactivateAccountTitle)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
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
