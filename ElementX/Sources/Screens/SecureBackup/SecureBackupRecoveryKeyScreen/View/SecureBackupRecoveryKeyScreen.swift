//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupRecoveryKeyScreen: View {
    @Bindable var context: SecureBackupRecoveryKeyScreenViewModel.Context
    @FocusState private var focused
    private let textFieldIdentifier = "textFieldIdentifier"
    
    var body: some View {
        FullscreenDialog {
            ScrollViewReader { reader in
                mainContent
                    .onChange(of: focused) { _, newValue in
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
            BigIcon(icon: \.keySolid)
            
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
            .accessibilityIdentifier(A11yIdentifiers.secureBackupRecoveryKeyScreen.confirm)
        }
    }
    
    private var recoveryCreatedActionButtons: some View {
        VStack(spacing: 16) {
            if let recoveryKey = context.viewState.recoveryKey {
                ShareLink(item: recoveryKey) {
                    Label(L10n.screenRecoveryKeySaveAction, icon: \.download)
                }
                .buttonStyle(.compound(.secondary))
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
            .accessibilityIdentifier(A11yIdentifiers.secureBackupRecoveryKeyScreen.done)
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
                .padding(.leading, 16)
            
            ZStack {
                RecoveryKeyView(recoveryKey: "", isInvisibleForLayout: true) { }
                
                if context.viewState.recoveryKey == nil {
                    if !context.viewState.isGeneratingKey {
                        Button(generateButtonTitle) {
                            context.send(viewAction: .generateKey)
                        }
                        .font(.compound.bodyLGSemibold)
                        .accessibilityIdentifier(A11yIdentifiers.secureBackupRecoveryKeyScreen.generateRecoveryKey)
                    } else {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text(L10n.screenRecoveryKeyGeneratingKey)
                        }
                        .font(.compound.bodyLGSemibold)
                        .foregroundStyle(.compound.textPrimary)
                    }
                } else {
                    RecoveryKeyView(recoveryKey: context.viewState.recoveryKey ?? "") {
                        context.send(viewAction: .copyKey)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .background(Color.compound.bgSubtleSecondaryLevel0)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            
            if let subtitle = context.viewState.recoveryKeySubtitle {
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodySM)
                    .padding(.leading, 16)
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
                .accessibilityIdentifier(A11yIdentifiers.secureBackupRecoveryKeyScreen.recoveryKeyField)
            
            if let subtitle = context.viewState.recoveryKeySubtitle {
                Text(subtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodySM)
            }
        }
    }
}

private struct RecoveryKeyView: View {
    /// The recovery key to show. This can be blank if `isInvisibleForLayout` is `true.`
    let recoveryKey: String
    /// Hides the view, laying it out with the expected key size so that the superview can have a consistent size.
    var isInvisibleForLayout = false
    /// The action performed when tapping the copy button.
    let copyAction: () -> Void
    
    private let placeholderRecoveryKey = Array(repeating: "XXXX", count: 12).joined(separator: " ")
    
    var body: some View {
        HStack(spacing: 8) {
            Text(isInvisibleForLayout ? placeholderRecoveryKey : recoveryKey)
                .foregroundColor(.compound.textSecondary)
                .font(.compound.bodyLG.monospaced())
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: copyAction) {
                CompoundIcon(\.copy)
            }
            .tint(.compound.iconSecondary)
            .accessibilityLabel(L10n.actionCopy)
            .accessibilityIdentifier(A11yIdentifiers.secureBackupRecoveryKeyScreen.copyRecoveryKey)
        }
        .opacity(isInvisibleForLayout ? 0 : 1)
        .accessibilityHidden(isInvisibleForLayout)
    }
}

// MARK: - Previews

struct SecureBackupRecoveryKeyScreen_Previews: PreviewProvider, TestablePreview {
    static let key = "EsTM njec uHYA yHmh dQdW Nj4o bNRU 9jMN XGMc KUNM UFr5 R8GY"
    static let notSetUpViewModel = viewModel(recoveryState: .disabled)
    static let generatingViewModel = viewModel(recoveryState: .disabled, generateKey: true, key: key)
    static let setupViewModel = viewModel(recoveryState: .enabled, generateKey: true, key: key)
    static let incompleteViewModel = viewModel(recoveryState: .incomplete)
    static let unknownViewModel = viewModel(recoveryState: .unknown)
    
    static var previews: some View {
        NavigationStack {
            SecureBackupRecoveryKeyScreen(context: notSetUpViewModel.context)
        }
        .previewDisplayName("Not set up")
        
        NavigationStack {
            SecureBackupRecoveryKeyScreen(context: generatingViewModel.context)
        }
        .previewDisplayName("Generating")
        
        NavigationStack {
            SecureBackupRecoveryKeyScreen(context: setupViewModel.context)
        }
        .snapshotPreferences(expect: setupViewModel.context.observe(\.viewState.recoveryKey).map { $0 != nil })
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
    
    static func viewModel(recoveryState: SecureBackupRecoveryState, generateKey: Bool = false, key: String? = nil) -> SecureBackupRecoveryKeyScreenViewModelType {
        let backupController = SecureBackupControllerMock()
        backupController.underlyingRecoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        
        if let key {
            backupController.generateRecoveryKeyReturnValue = .success(key)
        } else {
            backupController.generateRecoveryKeyClosure = {
                try? await Task.sleep(for: .seconds(1000))
                return .success("youshouldntseeme")
            }
        }
        
        let viewModel = SecureBackupRecoveryKeyScreenViewModel(secureBackupController: backupController,
                                                               userIndicatorController: UserIndicatorControllerMock(),
                                                               isModallyPresented: true)
        
        if generateKey {
            viewModel.context.send(viewAction: .generateKey)
        }
        
        return viewModel
    }
}
