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
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.recoveryKey == nil {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
    
    private var header: some View {
        VStack(spacing: 16) {
            HeroImage(image: Image(asset: Asset.Images.secureBackupOn))
            
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
        VStack(alignment: .leading) {
            Text(L10n.commonRecoveryKey)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySM)
         
            HStack {
                if context.viewState.recoveryKey == nil {
                    Button(generateButtonTitle) {
                        context.send(viewAction: .generateKey)
                    }
                    .font(.compound.bodyLGSemibold)
                } else {
                    HStack(alignment: .top) {
                        Text(context.viewState.recoveryKey ?? "")
                            .foregroundColor(.compound.textPrimary)
                            .font(.compound.bodyLG)
                        
                        Spacer()
                        
                        Button {
                            context.send(viewAction: .copyKey)
                        } label: {
                            Image(asset: Asset.Images.copy)
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
            
            HStack(alignment: .top) {
                if context.viewState.recoveryKey == nil {
                    CompoundIcon(\.infoSolid, size: .small, relativeTo: .compound.bodySM)
                }
                
                Text(context.viewState.recoveryKeySubtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodySM)
            }
        }
    }
    
    private var generateButtonTitle: String {
        context.viewState.mode == .setupRecovery ? L10n.screenRecoveryKeySetupGenerateKey : L10n.screenRecoveryKeyChangeGenerateKey
    }
    
    @ViewBuilder
    private var confirmRecoveryKeySection: some View {
        VStack(alignment: .leading) {
            Text(L10n.commonRecoveryKey)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySM)
            
            TextField(L10n.screenRecoveryKeyConfirmKeyPlaceholder, text: $context.confirmationRecoveryKey)
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
    static let setupViewModel = viewModel(recoveryKeyState: .enabled)
    static let notSetUpViewModel = viewModel(recoveryKeyState: .disabled)
    static let incompleteViewModel = viewModel(recoveryKeyState: .incomplete)
    
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
    
    static func viewModel(recoveryKeyState: SecureBackupRecoveryKeyState) -> SecureBackupRecoveryKeyScreenViewModelType {
        let backupController = SecureBackupControllerMock()
        backupController.underlyingRecoveryKeyState = CurrentValueSubject<SecureBackupRecoveryKeyState, Never>(recoveryKeyState).asCurrentValuePublisher()
        
        return SecureBackupRecoveryKeyScreenViewModel(secureBackupController: backupController, userIndicatorController: nil)
    }
}
