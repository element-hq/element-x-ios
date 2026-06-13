//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
//

import Compound
import SwiftUI

struct ProfileSetupScreen: View {
    @Bindable var context: ProfileSetupScreenViewModel.Context

    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: L10n.screenProfileSetupUsernamePlaceholder),
                        kind: .textField(text: $context.username))
                    .keyboardType(.asciiCapable)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: context.username) { _, _ in
                        context.send(viewAction: .usernameChanged)
                    }
                usernameStatusRow
            } header: {
                Text(L10n.screenProfileSetupUsernameHeader)
            } footer: {
                Group {
                    if let errorMessage = context.viewState.errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.compound.textCriticalPrimary)
                    } else {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.screenProfileSetupUsernameHint)
                            Text(L10n.screenProfileSetupUsernamePermanent)
                                .foregroundStyle(.compound.textSecondary)
                                .font(.compound.bodySMSemibold)
                        }
                    }
                }
            }

            Section {
                ListRow(label: .plain(title: L10n.screenProfileSetupDisplayNamePlaceholder),
                        kind: .textField(text: $context.displayName))
                    .textInputAutocapitalization(.words)
            } header: {
                Text(L10n.screenProfileSetupDisplayNameHeader)
            }

            Section {
                ListRow(label: .centeredAction(title: context.viewState.isSubmitting ? L10n.commonLoading : L10n.actionContinue,
                                               icon: \.arrowRight),
                        kind: .button {
                            context.send(viewAction: .submitTapped)
                        })
                        .disabled(!context.viewState.canSubmit)
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenProfileSetupTitle)
        .interactiveDismissDisabled(context.viewState.isSubmitting)
    }

    @ViewBuilder
    private var usernameStatusRow: some View {
        switch context.viewState.usernameStatus {
        case .idle:
            EmptyView()
        case .checking:
            statusLabel(text: L10n.screenProfileSetupUsernameChecking,
                        systemImage: "ellipsis.circle",
                        color: .compound.textSecondary)
        case .available:
            statusLabel(text: L10n.screenProfileSetupUsernameAvailable,
                        systemImage: "checkmark.circle.fill",
                        color: .compound.textSuccessPrimary)
        case .taken:
            statusLabel(text: L10n.screenProfileSetupUsernameTaken,
                        systemImage: "xmark.circle.fill",
                        color: .compound.textCriticalPrimary)
        case let .invalid(reason):
            statusLabel(text: reason ?? L10n.screenProfileSetupUsernameInvalid,
                        systemImage: "exclamationmark.triangle.fill",
                        color: .compound.textCriticalPrimary)
        }
    }

    private func statusLabel(text: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
            Text(text)
            Spacer()
        }
        .font(.compound.bodySM)
        .foregroundStyle(color)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets())
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    }
}

// MARK: - Previews

struct ProfileSetupScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ProfileSetupScreenViewModel(phoneNumber: "+15551234567")

    static var previews: some View {
        NavigationStack {
            ProfileSetupScreen(context: viewModel.context)
        }
    }
}
