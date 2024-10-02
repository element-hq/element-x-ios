//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupRecoveryKeyScreen: View {
    @ObservedObject var context: SecureBackupRecoveryKeyScreenViewModel.Context
    @FocusState private var focused
    private let textFieldIdentifier = "textFieldIdentifier"
    
    var body: some View {
        FullscreenDialog {
            ScrollViewReader { reader in
                mainContent
                    .padding(16)
                    .onChange(of: focused) { newValue in
                        guard newValue == true else { return }
                        reader.scrollTo(textFieldIdentifier)
                    }
            }
        } bottomContent: {
            footer
        }
        .toolbar { toolbar }
        .toolbar(.visible, for: .navigationBar)
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
        .alert(item: $context.alertInfo)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        VStack(spacing: 48) {
            switch context.viewState.mode {
            case .setupRecovery, .changeRecovery:
                header
                generateRecoveryKeySection
            case .fixRecovery:
                header
                confirmRecoveryKeySection
            case .unknown:
                header
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            HeroImage(icon: \.keySolid)
            
            Text(context.viewState.title)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
            
            if let subtitle = context.viewState.subtitle {
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyMD)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        switch context.viewState.mode {
        case .setupRecovery, .changeRecovery:
            recoveryCreatedActionButtons
        case .fixRecovery:
            incompleteVerificationActionButtons
        case .unknown:
            EmptyView()
        }
    }
    
    private var incompleteVerificationActionButtons: some View {
        VStack(spacing: 16) {
            Button {
                context.send(viewAction: .confirmKey)
            } label: {
                Text(L10n.actionConfirm)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.confirmationRecoveryKey.isEmpty)
            
            Button {
                context.send(viewAction: .resetEncryption)
            } label: {
                Text(L10n.screenIdentityConfirmationCreateNewRecoveryKey)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.compound(.plain))
        }
    }
    
    private var recoveryCreatedActionButtons: some View {
        VStack(spacing: 8.0) {
            if let recoveryKey = context.viewState.recoveryKey {
                ShareLink(item: recoveryKey) {
                    Label(L10n.screenRecoveryKeySaveAction, icon: \.download)
                }
                .buttonStyle(.compound(.primary))
                .simultaneousGesture(TapGesture().onEnded { _ in
                    context.send(viewAction: .keySaved)
                })
            }
            
            Button {
                context.send(viewAction: .done)
            } label: {
                Text(L10n.actionDone)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.viewState.recoveryKey == nil || context.viewState.doneButtonEnabled == false)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.isModallyPresented == true, context.viewState.recoveryKey == nil {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
    
    private var generateRecoveryKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.commonRecoveryKey)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySMSemibold)
            
            Group {
                if context.viewState.recoveryKey == nil {
                    Button(generateButtonTitle) {
                        context.send(viewAction: .generateKey)
                    }
                    .font(.compound.bodyLGSemibold)
                } else {
                    HStack(alignment: .top, spacing: 8) {
                        Text(context.viewState.recoveryKey ?? "")
                            .foregroundColor(.compound.textPrimary)
                            .font(.compound.bodyLG)
                        
                        Spacer()
                        
                        Button {
                            context.send(viewAction: .copyKey)
                        } label: {
                            CompoundIcon(\.copy)
                        }
                        .tint(.compound.iconSecondary)
                        .accessibilityLabel(L10n.actionCopy)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.compound.bgSubtleSecondaryLevel0)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            if let subtitle = context.viewState.recoveryKeySubtitle {
                Label {
                    Text(subtitle)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodySM)
                } icon: {
                    if context.viewState.recoveryKey == nil {
                        CompoundIcon(\.infoSolid, size: .small, relativeTo: .compound.bodySM)
                    }
                }
                .labelStyle(.custom(spacing: 8, alignment: .top))
            }
        }
    }
    
    private var generateButtonTitle: String {
        context.viewState.mode == .setupRecovery ? L10n.screenRecoveryKeySetupGenerateKey : L10n.screenRecoveryKeyChangeGenerateKey
    }
    
    @ViewBuilder
    private var confirmRecoveryKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.commonRecoveryKey)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySMSemibold)
            
            SecureField(L10n.screenRecoveryKeyConfirmKeyPlaceholder, text: $context.confirmationRecoveryKey)
                .tint(.compound.iconAccentTertiary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.compound.bgSubtleSecondaryLevel0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .id(textFieldIdentifier)
                .focused($focused)
                .submitLabel(.done)
                .onSubmit {
                    context.send(viewAction: .confirmKey)
                }
            
            if let subtitle = context.viewState.recoveryKeySubtitle {
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodySM)
            }
        }
    }
}

// MARK: - Previews

struct SecureBackupRecoveryKeyScreen_Previews: PreviewProvider, TestablePreview {
    static let setupViewModel = viewModel(recoveryState: .enabled)
    static let notSetUpViewModel = viewModel(recoveryState: .disabled)
    static let incompleteViewModel = viewModel(recoveryState: .incomplete)
    static let unknownViewModel = viewModel(recoveryState: .unknown)
    
    static var previews: some View {
        NavigationStack {
            SecureBackupRecoveryKeyScreen(context: notSetUpViewModel.context)
        }
        .previewDisplayName("Not set up")
        
        NavigationStack {
            SecureBackupRecoveryKeyScreen(context: setupViewModel.context)
        }
        .previewDisplayName("Set up")

        NavigationStack {
            SecureBackupRecoveryKeyScreen(context: incompleteViewModel.context)
        }
        .previewDisplayName("Incomplete")
        
        NavigationStack {
            SecureBackupRecoveryKeyScreen(context: unknownViewModel.context)
        }
        .previewDisplayName("Unknown")
    }
    
    static func viewModel(recoveryState: SecureBackupRecoveryState) -> SecureBackupRecoveryKeyScreenViewModelType {
        let backupController = SecureBackupControllerMock()
        backupController.underlyingRecoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        
        return SecureBackupRecoveryKeyScreenViewModel(secureBackupController: backupController,
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      isModallyPresented: true)
    }
}
