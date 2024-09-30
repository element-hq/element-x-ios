//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown to unlock the App Lock settings or to create a new PIN and enable the feature.
struct AppLockSetupPINScreen: View {
    @ObservedObject var context: AppLockSetupPINScreenViewModel.Context
    
    @FocusState private var textFieldFocus
    
    var stackSpacing: CGFloat {
        context.viewState.mode == .unlock ? 36 : 40
    }
    
    var subtitleColor: Color {
        context.viewState.isSubtitleWarning ? .compound.textCriticalPrimary : .compound.textSecondary
    }
    
    var interactiveDismissDisabled: Bool {
        context.viewState.isMandatory || context.viewState.isLoggingOut
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: stackSpacing) {
                header
                
                PINTextField(pinCode: $context.pinCode,
                             isSecure: true)
                    .focused($textFieldFocus)
                
                if context.viewState.mode == .unlock {
                    Button(L10n.screenAppLockForgotPin) {
                        context.send(viewAction: .forgotPIN)
                    }
                    .buttonStyle(.compound(.plain))
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, UIConstants.iconTopPaddingToNavigationBar)
            .frame(maxWidth: .infinity)
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .toolbar { toolbar }
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .interactiveDismissDisabled(interactiveDismissDisabled)
        .disabled(context.viewState.isLoggingOut)
        .alert(item: $context.alertInfo)
        .onAppear { textFieldFocus = true }
    }
    
    var header: some View {
        VStack(spacing: 8) {
            HeroImage(icon: \.lockSolid)
                .padding(.bottom, 8)
            
            Text(context.viewState.title)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(context.viewState.subtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(subtitleColor)
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if !context.viewState.isMandatory {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
                .accessibilityIdentifier(A11yIdentifiers.appLockSetupPINScreen.cancel)
            }
        }
    }
}

// MARK: - Previews

struct AppLockSetupPINScreen_Previews: PreviewProvider, TestablePreview {
    static let service = AppLockServiceMock.mock()
    static let failedService = AppLockServiceMock.mock(numberOfPINAttempts: 1)
    
    static let createViewModel = AppLockSetupPINScreenViewModel(initialMode: .create,
                                                                isMandatory: false,
                                                                appLockService: service)
    static let confirmViewModel = AppLockSetupPINScreenViewModel(initialMode: .confirm,
                                                                 isMandatory: false,
                                                                 appLockService: service)
    static let unlockViewModel = AppLockSetupPINScreenViewModel(initialMode: .unlock,
                                                                isMandatory: false,
                                                                appLockService: service)
    static let unlockFailedViewModel = AppLockSetupPINScreenViewModel(initialMode: .unlock,
                                                                      isMandatory: false,
                                                                      appLockService: failedService)
    
    static var previews: some View {
        NavigationStack {
            AppLockSetupPINScreen(context: createViewModel.context)
        }
        .previewDisplayName("Create")
        
        NavigationStack {
            AppLockSetupPINScreen(context: confirmViewModel.context)
        }
        .previewDisplayName("Confirm")
        
        NavigationStack {
            AppLockSetupPINScreen(context: unlockViewModel.context)
        }
        .previewDisplayName("Unlock")
        
        NavigationStack {
            AppLockSetupPINScreen(context: unlockFailedViewModel.context)
        }
        .previewDisplayName("Unlock Failed")
    }
}
