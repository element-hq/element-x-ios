//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupRecoveryKeyScreen: View {
    @ObservedObject var context: SecureBackupRecoveryKeyScreenViewModel.Context
    @FocusState private var focused
    private let textFieldIdentifier = "textFieldIdentifier"
    
    var body: some View {
        ScrollView {
            ScrollViewReader { reader in
                mainContent
                    .padding(16)
                    .onChange(of: focused) { newValue in
                        guard newValue == true else { return }
                        reader.scrollTo(textFieldIdentifier)
                    }
            }
        }
        .safeAreaInset(edge: .bottom) {
            footer
                .padding([.horizontal, .bottom], 16)
                .padding(.top, 8)
                .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        }
        .interactiveDismissDisabled()
        .toolbar { toolbar }
        .toolbar(.visible, for: .navigationBar)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
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
            }
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        switch context.viewState.mode {
        case .setupRecovery, .changeRecovery:
            recoveryCreatedActionButtons
        case .fixRecovery:
            Button {
                context.send(viewAction: .confirmKey)
            } label: {
                Text(L10n.actionConfirm)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.confirmationRecoveryKey.isEmpty)
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
    
    private var header: some View {
        VStack(spacing: 16) {
            HeroImage(icon: \.keySolid)
            
            Text(context.viewState.title)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
            
            Text(context.viewState.subtitle)
                .foregroundColor(.compound.textSecondary)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
        }
    }
    
    private var generateRecoveryKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.commonRecoveryKey)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySM)
            
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
            
            Label {
                Text(context.viewState.recoveryKeySubtitle)
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
    
    private var generateButtonTitle: String {
        context.viewState.mode == .setupRecovery ? L10n.screenRecoveryKeySetupGenerateKey : L10n.screenRecoveryKeyChangeGenerateKey
    }
    
    @ViewBuilder
    private var confirmRecoveryKeySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.commonRecoveryKey)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySM)
            
            SecureField(L10n.screenRecoveryKeyConfirmKeyPlaceholder, text: $context.confirmationRecoveryKey)
                .textContentType(.password) // Not ideal but stops random suggestions
                .autocapitalization(.none)
                .disableAutocorrection(true)
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
            
            Text(context.viewState.recoveryKeySubtitle)
                .foregroundColor(.compound.textSecondary)
                .font(.compound.bodySM)
        }
    }
}

// MARK: - Previews

struct SecureBackupRecoveryKeyScreen_Previews: PreviewProvider, TestablePreview {
    static let setupViewModel = viewModel(recoveryState: .enabled)
    static let notSetUpViewModel = viewModel(recoveryState: .disabled)
    static let incompleteViewModel = viewModel(recoveryState: .incomplete)
    
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
    }
    
    static func viewModel(recoveryState: SecureBackupRecoveryState) -> SecureBackupRecoveryKeyScreenViewModelType {
        let backupController = SecureBackupControllerMock()
        backupController.underlyingRecoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        
        return SecureBackupRecoveryKeyScreenViewModel(secureBackupController: backupController,
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      isModallyPresented: true)
    }
}
