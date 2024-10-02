//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown when setting up App Lock that asks the user whether
/// the would like to use Face ID/Touch ID instead of entering their PIN code.
struct AppLockSetupBiometricsScreen: View {
    @ObservedObject var context: AppLockSetupBiometricsScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 48) {
                header
            }
            .padding(.horizontal, 16)
            .padding(.top, UIConstants.iconTopPaddingToNavigationBar)
            .frame(maxWidth: .infinity)
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .toolbar(.visible, for: .navigationBar)
        .navigationBarBackButtonHidden()
        .interactiveDismissDisabled()
        .safeAreaInset(edge: .bottom) {
            buttons
                .padding(.top, 16)
                .padding(.horizontal, 16)
                .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        }
    }
    
    var header: some View {
        VStack(spacing: 8) {
            Image(systemSymbol: context.viewState.icon)
                .font(.system(size: 72))
                .padding(.top, 58)
                .padding(.bottom, 26)
                .accessibilityHidden(true)
            
            Text(context.viewState.title)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(context.viewState.subtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    var buttons: some View {
        VStack(spacing: 16) {
            Button(context.viewState.title) { context.send(viewAction: .allow) }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.appLockSetupBiometricsScreen.allow)
            
            Button { context.send(viewAction: .skip) } label: {
                Text(L10n.screenAppLockSetupBiometricUnlockSkip)
                    .font(.compound.bodyLGSemibold)
                    .padding(14)
            }
        }
    }
}

// MARK: - Previews

struct AppLockSetupBiometricsScreen_Previews: PreviewProvider, TestablePreview {
    static let faceIDViewModel = AppLockSetupBiometricsScreenViewModel(appLockService: AppLockServiceMock.mock(biometryType: .faceID))
    static let touchIDViewModel = AppLockSetupBiometricsScreenViewModel(appLockService: AppLockServiceMock.mock(biometryType: .touchID))
    
    static var previews: some View {
        NavigationStack {
            AppLockSetupBiometricsScreen(context: faceIDViewModel.context)
        }
        .previewDisplayName("Face ID")
        
        NavigationStack {
            AppLockSetupBiometricsScreen(context: touchIDViewModel.context)
        }
        .previewDisplayName("Touch ID")
    }
}
