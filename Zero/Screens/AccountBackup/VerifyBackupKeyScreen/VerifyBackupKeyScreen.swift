//
// Copyright 2024 New Vector Ltd
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

import SwiftUI
import Combine

struct VerifyBackupKeyScreen: View {
    
    @ObservedObject var context: SecureBackupRecoveryKeyScreenViewModel.Context
    
    @FocusState var isFocused: Bool
        
    var body: some View {
        FullscreenDialog(topPadding: 0, horizontalPadding: 0) {
            header
            
            content
        } bottomContent: {
            actionButton
        }
        .toolbar { toolbar }
        .toolbar(.visible, for: .navigationBar)
        .background()
        .backgroundStyle(Asset.Colors.zeroDarkGrey.swiftUIColor)
        .interactiveDismissDisabled()
        .alert(item: $context.alertInfo)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.isModallyPresented == true, context.viewState.recoveryKey == nil {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
                .tint(Asset.Colors.textPrimary.swiftUIColor)
            }
        }
    }
    
    var header: some View {
        Image(asset: Asset.Images.zeroBackupHeader)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(height: 192)
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Verify Login")
                .font(.zero.bodyLG)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .padding(.top, 24)
            
            Text("Enter your account backup phrase to restore access to messages from previous logins and devices.")
                .multilineTextAlignment(.leading)
                .font(.zero.bodySM)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 8) {
                
                Text("Account backup phrase")
                    .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                    .font(.zero.bodySM)
                
                backupkeyField
                
                errorContent
            }
            .padding(.top, 40)
        }
        .padding(.horizontal, 32)
    }
    
    var backupkeyField: some View {
        TextField(
            "",
            text: $context.confirmationRecoveryKey,
            prompt: Text("Backup phrase")
                .foregroundColor(Asset.Colors.greyScale150.swiftUIColor)
        )
        .foregroundColor(Asset.Colors.textPrimary.swiftUIColor)
        .padding()
        .textFieldStyle(PlainTextFieldStyle())
        .frame(height: 40)
        .background(Asset.Colors.greyScale150.swiftUIColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .focused($isFocused)
        .keyboardType(.asciiCapable)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .submitLabel(.done)
        .onSubmit {
            isFocused = false
            context.send(viewAction: .confirmKey)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(context.alertInfo == nil ? Color.clear : Asset.Colors.textWarning.swiftUIColor)
        )
        .onAppear {
            UITextField.appearance().clearButtonMode = .whileEditing
        }
    }
    
    var errorContent: some View {
        VStack{
            if let alert = context.alertInfo {
                HStack {
                    Image(asset: Asset.Images.alertFillCircleIcon)
                        .padding(.leading, 16)
                    
                    Text(alert.message ?? "Error occured will verifying backup key.")
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(Asset.Colors.textWarning.swiftUIColor)
                        .font(.zero.bodyXS)
                    
                    Spacer()
                }
                .frame(minHeight: 28)
                .background(Asset.Colors.textWarning.swiftUIColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 4))
                
            } else {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 28)
            }
        }
    }
    
    var actionButton: some View {
        Button {
            context.send(viewAction: .confirmKey)
        } label: {
            Text("Verify")
                .font(.zero.bodyMDSemibold)
                .foregroundStyle(Asset.Colors.textPrimary.swiftUIColor)
                .frame(height: 48)
                .frame(maxWidth: 94)
                .background(Color(red: 0.99, green: 0.99, blue: 0.99).opacity(0.05))
                .cornerRadius(9999)
                .overlay(
                    RoundedRectangle(cornerRadius: 9999)
                        .inset(by: 0.5)
                        .stroke(canVerify ? .white.opacity(0.25) : .clear, lineWidth: 1)
                )
        }
        .disabled(!canVerify)
        .frame(maxWidth: .infinity)
        .padding(.bottom, 44)
    }
    
    private var canVerify: Bool {
        !context.confirmationRecoveryKey.isEmpty
    }
}

// MARK: - Previews

struct VerifyBackupKeyScreen_Previews: PreviewProvider, TestablePreview {
    static let setupViewModel = viewModel(recoveryState: .enabled)
    static let notSetUpViewModel = viewModel(recoveryState: .disabled)
    static let incompleteViewModel = viewModel(recoveryState: .incomplete)
    static let unknownViewModel = viewModel(recoveryState: .unknown)
    
    static var previews: some View {
        NavigationStack {
            VerifyBackupKeyScreen(context: notSetUpViewModel.context)
        }
        .previewDisplayName("Not set up")
        
        NavigationStack {
            VerifyBackupKeyScreen(context: setupViewModel.context)
        }
        .previewDisplayName("Set up")

        NavigationStack {
            VerifyBackupKeyScreen(context: incompleteViewModel.context)
        }
        .previewDisplayName("Incomplete")
        
        NavigationStack {
            VerifyBackupKeyScreen(context: unknownViewModel.context)
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
